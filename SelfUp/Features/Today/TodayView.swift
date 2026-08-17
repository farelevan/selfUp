import SwiftUI
import SwiftData
import Charts

struct DailyActivity: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
}

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("profile_name") private var profileName = ""
    @Query private var habits: [Habit]
    @Query private var tasks: [TaskItem]
    @Query private var transactions: [Transaction]
    @Query private var rewards: [Reward]
    
    @State private var showingSettings = false
    @State private var animateScore = false
    
    private var activeHabits: [Habit] { habits.filter { !$0.isArchived && $0.isScheduled(on: Date()) } }
    
    private var completedHabitsCount: Int {
        activeHabits.filter { ProgressService.isCompleted($0, on: Date()) }.count
    }
    
    private var openTasksToday: [TaskItem] {
        let calendar = Calendar.current
        return tasks.filter { task in
            task.completedAt == nil && (task.dueDate.map { calendar.isDate($0, inSameDayAs: Date()) } ?? false || task.priority == .high)
        }
    }
    
    private var moneySummaryToday: MoneySummary {
        let calendar = Calendar.current
        let todayTransactions = transactions.filter { calendar.isDate($0.date, inSameDayAs: Date()) }
        return MoneySummaryService.summary(for: todayTransactions)
    }
    
    private var snapshot: ProgressSnapshot {
        ProgressService.snapshot(habits: habits, tasks: tasks, transactions: transactions, rewards: rewards, on: Date())
    }
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "selected_currency") ?? "Rp"
    }
    
    private var activityData: [DailyActivity] {
        let calendar = Calendar.current
        var list: [DailyActivity] = []
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let score = ProgressService.lifeScore(habits: habits, tasks: tasks, transactions: transactions, on: date)
                list.append(DailyActivity(date: date, score: score))
            }
        }
        return list
    }

    private var activityAccessibilitySummary: String {
        guard let latest = activityData.last else { return "No Life Score data" }
        let scores = activityData.map(\.score)
        return "Latest score \(latest.score) out of 100; seven-day range \(scores.min() ?? 0) to \(scores.max() ?? 0)."
    }
    
    var body: some View {
        let progress = snapshot
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    .padding(.horizontal)
                    
                    // Level Progress Bento Card
                    VStack(alignment: .leading, spacing: 14) {
                        levelHeader(progress)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 12)
                                
                                Capsule()
                                    .fill(SelfUpStyle.progressGradient)
                                    .frame(width: geo.size.width * CGFloat(progress.xpProgress), height: 12)
                                    .animation(reduceMotion ? nil : .spring(response: 0.8, dampingFraction: 0.7), value: progress.xpProgress)
                            }
                        }
                        .frame(height: 12)
                    }
                    .premiumCard(cornerRadius: 18)
                    .padding(.horizontal)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Level \(progress.level), \(progress.levelTitle)")
                    .accessibilityValue("\(progress.xpIntoLevel) of \(progress.xpForNextLevel) XP; \(progress.xpToNextLevel) XP to next level")
                    
                    // Life Score Bento Gauge
                    Group {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: 18) {
                                lifeScoreGauge(progress)
                                summaryMetrics
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack(alignment: .center, spacing: 20) {
                                lifeScoreGauge(progress)
                                summaryMetrics
                                Spacer()
                            }
                        }
                    }
                    .bentoCard(cornerRadius: 18)
                    .padding(.horizontal)
                    .onAppear {
                        animateScore = true
                    }
                    
                    // Unified Vertical Activity Carousel Bento Card (Habits, Tasks, Expenses)
                    DailyActivityCarouselView(
                        habits: activeHabits,
                        openTasks: openTasksToday,
                        moneySummary: moneySummaryToday,
                        currencySymbol: currencySymbol
                    )
                    
                    // 7-Day Life Score Chart
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("7-Day Progress")
                                    .font(.system(.headline, design: .default))
                                    .fontWeight(.bold)
                                Text("Your consistency over time")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(SelfUpStyle.brand)
                        }
                        
                        Chart(activityData) { day in
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Life Score", day.score)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(SelfUpStyle.brand)
                            .lineStyle(StrokeStyle(lineWidth: 3.5))
                            
                            AreaMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Life Score", day.score)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [SelfUpStyle.brand.opacity(0.3), SelfUpStyle.brand.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 135)
                        .chartYScale(domain: 0...100)
                        .accessibilityLabel("Seven-day Life Score")
                        .accessibilityValue(activityAccessibilitySummary)
                    }
                    .premiumCard(cornerRadius: 18)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    SelfUpLogoView(style: .compactHeader)
                    Spacer()
                    settingsButton
                }
                greeting
            }
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    SelfUpLogoView(style: .compactHeader)
                    greeting
                }
                Spacer()
                settingsButton
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                 ? "Welcome back"
                 : "Hey, \(profileName.trimmingCharacters(in: .whitespacesAndNewlines))")
                .font(.title3.bold())

            Text(Date().formatted(date: .complete, time: .omitted).uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .tracking(dynamicTypeSize.isAccessibilitySize ? 0 : 1.2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var settingsButton: some View {
        Button {
            showingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(10)
                .background(Circle().fill(Color(.tertiarySystemFill)))
                .frame(minWidth: SelfUpStyle.minimumControlSize, minHeight: SelfUpStyle.minimumControlSize)
        }
        .accessibilityLabel("Open settings")
    }

    @ViewBuilder
    private func levelHeader(_ progress: ProgressSnapshot) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    levelIcon
                    levelIdentity(progress)
                }
                nextLevelBadge(progress)
            }
        } else {
            HStack(spacing: 12) {
                levelIcon
                levelIdentity(progress)
                Spacer(minLength: 8)
                nextLevelBadge(progress)
            }
        }
    }

    private var levelIcon: some View {
        ZStack {
            Circle()
                .fill(SelfUpStyle.goldGradient)
                .frame(width: 38, height: 38)
            Image(systemName: "crown.fill")
                .foregroundStyle(.white)
                .font(.subheadline)
        }
        .accessibilityHidden(true)
    }

    private func levelIdentity(_ progress: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Level \(progress.level)")
                .font(.headline.bold())
            Text("\(progress.levelTitle) • \(progress.xp) XP total")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func nextLevelBadge(_ progress: ProgressSnapshot) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.white)
            Text("\(progress.xpToNextLevel) XP to next level")
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 12).fill(SelfUpStyle.brandFill))
        .foregroundStyle(.white)
    }

    private func lifeScoreGauge(_ progress: ProgressSnapshot) -> some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 14)
                .frame(width: 104, height: 104)

            Circle()
                .trim(from: 0, to: animateScore ? CGFloat(progress.lifeScore) / 100.0 : 0)
                .stroke(SelfUpStyle.lifeScoreGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 104, height: 104)
                .animation(reduceMotion ? nil : .spring(response: 1.2, dampingFraction: 0.8), value: animateScore)

            VStack(spacing: 0) {
                Text("\(progress.lifeScore)")
                    .font(.title.bold())
                Text("SCORE")
                    .font(.caption2.bold())
                    .foregroundStyle(SelfUpStyle.success)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Life Score")
        .accessibilityValue("\(progress.lifeScore) out of 100")
    }

    private var summaryMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryMetric(
                title: "Habits Done",
                value: "\(completedHabitsCount) of \(activeHabits.count)",
                symbol: "checkmark.circle.fill",
                color: SelfUpStyle.success
            )
            summaryMetric(
                title: "Focus Tasks",
                value: "\(openTasksToday.count) Pending",
                symbol: "checklist",
                color: SelfUpStyle.brand
            )
            summaryMetric(
                title: "Today Net",
                value: "\(moneySummaryToday.net >= 0 ? "+" : "")\(currencySymbol) \(NSDecimalNumber(decimal: moneySummaryToday.net).stringValue)",
                symbol: "creditcard.fill",
                color: moneySummaryToday.net >= 0 ? SelfUpStyle.success : SelfUpStyle.danger
            )
        }
    }

    private func summaryMetric(title: String, value: String, symbol: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.18)).frame(width: 30, height: 30)
                Image(systemName: symbol)
                    .foregroundStyle(color)
                    .font(.subheadline)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(title == "Today Net" ? color : Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct HabitQuickCell: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let trackingService = TrackingService()
    @State private var celebrationToken = 0
    
    private var isCompletedToday: Bool {
        ProgressService.isCompleted(habit, on: Date())
    }
    
    private var tintColor: Color {
        SelfUpStyle.habitTint(named: habit.tintName)
    }

    private var tintFillColor: Color {
        SelfUpStyle.habitFill(named: habit.tintName)
    }
    
    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6)) {
                let didComplete = (try? trackingService.toggleHabit(habit, on: Date(), context: modelContext)) == true
                if didComplete {
                    if !reduceMotion { celebrationToken += 1 }
                    Haptics.success()
                } else {
                    Haptics.light()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: habit.symbol)
                    .font(.subheadline)
                    .foregroundStyle(isCompletedToday ? .white : tintColor)
                Text(habit.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(isCompletedToday ? .white : .primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: SelfUpStyle.minimumControlSize)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isCompletedToday ? tintFillColor : Color(.secondarySystemGroupedBackground))
                    .shadow(color: isCompletedToday ? tintFillColor.opacity(0.24) : Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isCompletedToday ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .pressableScale(scale: 0.94)
        .accessibilityLabel(habit.title)
        .accessibilityValue(isCompletedToday ? "Completed today" : "Not completed today, worth \(habit.xpReward) XP")
        .overlay {
            if celebrationToken > 0 && !reduceMotion {
                CompletionMotionView(color: tintFillColor, compact: true)
                    .id(celebrationToken)
            }
        }
    }
}
