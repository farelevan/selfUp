import SwiftUI
import SwiftData

struct RewardsView: View {
    @Bindable var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \Reward.xpCost) private var rewards: [Reward]
    @Query private var habits: [Habit]
    @Query private var tasks: [TaskItem]
    @Query private var transactions: [Transaction]

    @State private var showingEditor = false
    @State private var rewardToEdit: Reward?
    @State private var showingSettings = false
    @State private var redemptionErrorMessage: String?

    private var snapshot: ProgressSnapshot {
        ProgressService.snapshot(
            habits: habits,
            tasks: tasks,
            transactions: transactions,
            rewards: rewards,
            on: Date()
        )
    }

    private var activeRewards: [Reward] {
        rewards.filter { $0.redeemedAt == nil }
    }

    private var redeemedRewards: [Reward] {
        rewards
            .filter { $0.redeemedAt != nil }
            .sorted { ($0.redeemedAt ?? .distantPast) > ($1.redeemedAt ?? .distantPast) }
    }

    private var rewardColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 155, maximum: 260), spacing: 16)]
    }

    private var achievementColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 145, maximum: 220), spacing: 12)]
    }

    var body: some View {
        let progress = snapshot

        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 22) {
                    progressHero(progress)
                    insightsLink
                    achievementSection(progress.achievements)
                    rewardStore(progress)
                    redemptionHistory
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("Add Reward", systemImage: "plus.circle.fill")
                            .foregroundStyle(SelfUpStyle.brand)
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
            .sheet(isPresented: $router.shouldPresentInsights) {
                InsightsView()
            }
            .alert("Unable to Redeem", isPresented: Binding(
                get: { redemptionErrorMessage != nil },
                set: { if !$0 { redemptionErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(redemptionErrorMessage ?? "Please try again.")
            }
        }
    }

    private var insightsLink: some View {
        Button {
            router.shouldPresentInsights = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title3)
                    .foregroundStyle(SelfUpStyle.brand)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(SelfUpStyle.brand.opacity(0.12)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress Insights")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Review trends, streaks, and next actions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .premiumCard(cornerRadius: SelfUpStyle.Radius.medium)
        .padding(.horizontal)
        .accessibilityHint("Opens detailed progress insights")
    }

    private func progressHero(_ progress: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            progressCrown
                            progressLevelSummary(progress)
                        }
                        availableXP(progress, alignment: .leading)
                    }
                } else {
                    HStack(alignment: .top, spacing: 14) {
                        progressCrown
                        progressLevelSummary(progress)
                        Spacer()
                        availableXP(progress, alignment: .trailing)
                    }
                }
            }

            ProgressView(value: progress.xpProgress)
                .tint(SelfUpStyle.brand)
                .accessibilityLabel("Level progress")
                .accessibilityValue("\(progress.xpIntoLevel) of \(progress.xpForNextLevel) XP")

            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("\(progress.xpIntoLevel) / \(progress.xpForNextLevel) XP this level")
                    Spacer()
                    Text("\(progress.xp) lifetime XP")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(progress.xpIntoLevel) / \(progress.xpForNextLevel) XP this level")
                    Text("\(progress.xp) lifetime XP")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 10) { progressSourceMetrics(progress) }
                } else {
                    HStack(spacing: 10) { progressSourceMetrics(progress) }
                }
            }
        }
        .premiumCard(cornerRadius: 18)
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
    }

    private var progressCrown: some View {
        ZStack {
            Circle()
                .fill(SelfUpStyle.goldGradient)
                .frame(width: 48, height: 48)
            Image(systemName: "crown.fill")
                .foregroundStyle(.white)
                .font(.title3)
        }
        .accessibilityHidden(true)
    }

    private func progressLevelSummary(_ progress: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("LEVEL \(progress.level)")
                .font(.caption.weight(.bold))
                .tracking(dynamicTypeSize.isAccessibilitySize ? 0 : 1)
                .foregroundStyle(SelfUpStyle.achievement)
            Text(progress.levelTitle)
                .font(.title2.bold())
            Text("\(progress.xpToNextLevel) XP to level \(progress.level + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func availableXP(_ progress: ProgressSnapshot, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text("\(progress.currentXP)")
                .font(.title.bold())
                .foregroundStyle(SelfUpStyle.achievement)
            Text("XP AVAILABLE")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func progressSourceMetrics(_ progress: ProgressSnapshot) -> some View {
        XPSourceMetric(
            title: "Habits",
            value: progress.sourceBreakdown.habitXP,
            symbol: "flame.fill",
            color: SelfUpStyle.success
        )
        XPSourceMetric(
            title: "Tasks",
            value: progress.sourceBreakdown.taskXP,
            symbol: "checkmark.seal.fill",
            color: SelfUpStyle.brand
        )
        XPSourceMetric(
            title: "Spent",
            value: progress.spentXP,
            symbol: "gift.fill",
            color: SelfUpStyle.warning
        )
    }

    private func achievementSection(_ achievements: [ProgressAchievement]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.title3.bold())
                Spacer()
                Text("\(achievements.filter(\.isUnlocked).count)/\(achievements.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: achievementColumns, spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
        .padding(.horizontal)
    }

    private func rewardStore(_ progress: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reward Store")
                .font(.title3.bold())
                .padding(.horizontal)

            if activeRewards.isEmpty {
                ContentUnavailableView(
                    "No Rewards Yet",
                    systemImage: "gift.fill",
                    description: Text("Add something meaningful to work toward with your XP.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemGroupedBackground)))
                .padding(.horizontal)
            } else {
                LazyVGrid(columns: rewardColumns, spacing: 16) {
                    ForEach(activeRewards) { reward in
                        RewardCard(
                            reward: reward,
                            currentXP: progress.currentXP,
                            onRedeem: { redeem(reward) }
                        )
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
    }

    @ViewBuilder
    private var redemptionHistory: some View {
        if !redeemedRewards.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Redemption History")
                    .font(.title3.bold())
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    ForEach(redeemedRewards) { reward in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(SelfUpStyle.success)
                                .font(.title3)
                                .frame(width: 36, height: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(reward.title)
                                    .font(.subheadline.bold())
                                if let date = reward.redeemedAt {
                                    Text("Redeemed \(date, style: .date)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text("−\(reward.xpCost) XP")
                                .font(.subheadline.bold())
                                .foregroundStyle(SelfUpStyle.warning)
                        }
                        .padding(14)
                        .accessibilityElement(children: .combine)

                        if reward.id != redeemedRewards.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)
            }
        }
    }

    private func redeem(_ reward: Reward) {
        do {
            // Recompute at action time so two redemptions cannot both rely on a
            // balance captured by the same earlier render pass.
            try RewardsService.redeem(reward, availableXP: snapshot.currentXP)
            do {
                try modelContext.save()
                Haptics.success()
            } catch {
                reward.redeemedAt = nil
                redemptionErrorMessage = "Your reward could not be saved. \(error.localizedDescription)"
            }
        } catch {
            redemptionErrorMessage = error.localizedDescription
            Haptics.light()
        }
    }

    private func delete(_ reward: Reward) {
        modelContext.delete(reward)
        try? modelContext.save()
    }
}

private struct XPSourceMetric: View {
    let title: String
    let value: Int
    let symbol: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text("\(value) XP")
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.1)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value) XP")
    }
}

private struct AchievementCard: View {
    let achievement: ProgressAchievement

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: achievement.isUnlocked ? achievement.symbol : "lock.fill")
                .foregroundStyle(achievement.isUnlocked ? SelfUpStyle.achievement : .secondary)
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(
                        achievement.isUnlocked
                            ? SelfUpStyle.achievement.opacity(0.14)
                            : Color.primary.opacity(0.06)
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(achievement.title)
                        .font(.caption.bold())
                    Spacer(minLength: 4)
                    Text("\(achievement.current)/\(achievement.target)")
                        .font(.caption2.bold())
                        .foregroundStyle(achievement.isUnlocked ? SelfUpStyle.success : .secondary)
                }
                Text(achievement.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressView(value: achievement.progress)
                    .tint(achievement.isUnlocked ? SelfUpStyle.success : SelfUpStyle.brand)
            }
            Spacer(minLength: 0)
        }
        .padding(11)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(achievement.title), \(achievement.isUnlocked ? "unlocked" : "locked")")
        .accessibilityValue("\(achievement.current) of \(achievement.target). \(achievement.detail)")
    }
}

struct RewardCard: View {
    let reward: Reward
    let currentXP: Int
    let onRedeem: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var canRedeem: Bool {
        RewardsService.canRedeem(reward, availableXP: currentXP)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: canRedeem ? "gift.fill" : "lock.fill")
                .font(.title3)
                .foregroundStyle(canRedeem ? Color.white : Color.secondary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(canRedeem ? SelfUpStyle.warningFill : Color.primary.opacity(0.06)))

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.headline.bold())
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                Text("\(reward.xpCost) XP")
                    .font(.subheadline.bold())
                    .foregroundStyle(SelfUpStyle.achievement)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6)) {
                    onRedeem()
                }
            } label: {
                Text(canRedeem ? "Redeem" : "Need \(max(0, reward.xpCost - currentXP)) XP")
                    .font(.caption.bold())
                    .foregroundStyle(canRedeem ? Color.white : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: SelfUpStyle.Control.minimumTapTarget)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canRedeem ? SelfUpStyle.goldGradient : LinearGradient(
                                colors: [Color(.tertiarySystemFill), Color(.tertiarySystemFill)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    )
            }
            .pressableScale(scale: 0.92)
            .disabled(!canRedeem)
            .accessibilityLabel("Redeem \(reward.title)")
            .accessibilityValue("Costs \(reward.xpCost) XP; \(currentXP) XP available")
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 225, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(canRedeem ? SelfUpStyle.warning.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
