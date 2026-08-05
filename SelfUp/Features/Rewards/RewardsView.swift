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
                    // Balance Vault Hero Card
                    VStack(spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(SelfUpStyle.goldGradient)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AVAILABLE REWARD VAULT")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(SelfUpStyle.rewardGold)
                                    .tracking(1)
                                Text("\(snapshot.currentXP) XP")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(SelfUpStyle.goldGradient)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total Earned: \(snapshot.xp) XP")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Level \(snapshot.level) Vault")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.orange.opacity(0.12)))
                                .foregroundStyle(.orange)
                        }
                    }
                    .glowingCard(color: SelfUpStyle.rewardGold, cornerRadius: 20)
                    .padding(.horizontal)
                    
                    // Active Rewards Grid
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Reward Store")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if activeRewards.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(SelfUpStyle.rewardGold.opacity(0.5))
                                Text("No active rewards in store")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
                            .padding(.horizontal)
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
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Redemption History")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                ForEach(redeemedRewards) { reward in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.emerald.opacity(0.12))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundStyle(Color.emerald)
                                                .font(.subheadline)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(reward.title)
                                                .font(.system(.subheadline, design: .rounded))
                                                .fontWeight(.bold)
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
                                            .font(.system(.subheadline, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundStyle(.orange)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    
                                    if reward != redeemedRewards.last {
                                        Divider()
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 20))
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
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SelfUpStyle.primaryIndigo)
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
        Haptics.success()
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
                    .fill(canRedeem ? Color.orange.opacity(0.15) : Color.primary.opacity(0.06))
                    .frame(width: 44, height: 44)
                Image(systemName: canRedeem ? "gift.fill" : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(canRedeem ? Color.orange : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .frame(height: 44, alignment: .topLeading)
                
                Text("\(reward.xpCost) XP")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(SelfUpStyle.goldGradient)
            }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onRedeem()
                }
            } label: {
                Text(canRedeem ? "Redeem" : "Locked")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canRedeem ? SelfUpStyle.goldGradient : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                    )
            }
            .pressableScale(scale: 0.92)
            .disabled(!canRedeem)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(canRedeem ? Color.orange.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

