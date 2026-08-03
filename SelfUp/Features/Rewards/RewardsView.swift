import SwiftUI
import SwiftData

struct RewardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reward.xpCost) private var rewards: [Reward]
    @Query private var habits: [Habit]
    @Query private var tasks: [TaskItem]
    @Query private var transactions: [Transaction]
    
    @State private var showingEditor = false
    @State private var rewardToEdit: Reward? = nil
    @State private var showingSettings = false
    
    private var snapshot: ProgressSnapshot {
        ProgressService.snapshot(habits: habits, tasks: tasks, transactions: transactions, rewards: rewards, on: Date())
    }
    
    private var activeRewards: [Reward] {
        rewards.filter { $0.redeemedAt == nil }
    }
    
    private var redeemedRewards: [Reward] {
        rewards.filter { $0.redeemedAt != nil }.sorted { $0.redeemedAt! > $1.redeemedAt! }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Hero Card
                    VStack(spacing: 8) {
                        Text("AVAILABLE BALANCE")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                        
                        Text("\(snapshot.currentXP) XP")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(SelfUpStyle.goldGradient)
                        
                        Text("Lifetime Earned: \(snapshot.xp) XP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .premiumCard()
                    .padding(.horizontal)
                    
                    // Active Rewards Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reward Store")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if activeRewards.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                Text("No rewards available in the store.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(activeRewards) { reward in
                                    RewardCard(reward: reward, currentXP: snapshot.currentXP, onRedeem: {
                                        redeem(reward)
                                    })
                                    .contextMenu {
                                        Button {
                                            rewardToEdit = reward
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            delete(reward)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Redeemed Rewards List
                    if !redeemedRewards.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Redemption History")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                ForEach(redeemedRewards) { reward in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(reward.title)
                                                .font(.subheadline)
                                                .bold()
                                                .strikethrough()
                                                .foregroundStyle(.secondary)
                                            if let date = reward.redeemedAt {
                                                Text("Redeemed on \(date, style: .date)")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Text("-\(reward.xpCost) XP")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    
                                    if reward != redeemedRewards.last {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reward Store")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                RewardEditorView()
            }
            .sheet(item: $rewardToEdit) { reward in
                RewardEditorView(rewardToEdit: reward)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private func redeem(_ reward: Reward) {
        reward.redeemedAt = Date()
        try? modelContext.save()
    }
    
    private func delete(_ reward: Reward) {
        modelContext.delete(reward)
        try? modelContext.save()
    }
}

struct RewardCard: View {
    let reward: Reward
    let currentXP: Int
    let onRedeem: () -> Void
    
    private var canRedeem: Bool {
        currentXP >= reward.xpCost
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(canRedeem ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "gift.fill")
                    .font(.headline)
                    .foregroundStyle(canRedeem ? Color.orange : Color.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.headline)
                    .lineLimit(2)
                    .frame(height: 48, alignment: .topLeading)
                
                Text("\(reward.xpCost) XP")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(SelfUpStyle.goldGradient)
            }
            
            Button {
                withAnimation(.spring()) {
                    onRedeem()
                }
            } label: {
                Text("Redeem")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(canRedeem ? Color.orange : Color.gray.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!canRedeem)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color(white: 0, opacity: 0.03), radius: 6, x: 0, y: 3)
    }
}
