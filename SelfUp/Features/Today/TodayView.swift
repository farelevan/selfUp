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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Greeting with App Logo Branding
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            SelfUpLogoView(style: .compactHeader)
                            
                            Text(Date().formatted(date: .complete, time: .omitted).uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .tracking(1.2)
                        }
                        Spacer()
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .padding(10)
                                .background(Circle().fill(Color(.tertiarySystemFill)))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Level Progress Bento Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(SelfUpStyle.goldGradient)
                                    .frame(width: 38, height: 38)
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.white)
                                    .font(.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("LEVEL \(snapshot.level)")
                                    .font(.system(.headline, design: .default))
                                    .fontWeight(.bold)
                                Text("\(snapshot.xp) XP Total")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.caption2)
                                    .foregroundStyle(SelfUpStyle.cyberLime)
                                Text("\(100 - (snapshot.xp % 100)) XP NEXT LEVEL")
                                    .font(.system(size: 10, weight: .bold, design: .default))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(SelfUpStyle.primaryIndigo.opacity(0.15)))
                            .foregroundStyle(SelfUpStyle.primaryIndigo)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 12)
                                
                                Capsule()
                                    .fill(SelfUpStyle.progressGradient)
                                    .frame(width: max(14, geo.size.width * CGFloat(snapshot.xpProgress)), height: 12)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: snapshot.xpProgress)
                            }
                        }
                        .frame(height: 12)
                    }
                    .premiumCard(cornerRadius: 16)
                    .padding(.horizontal)
                    
                    // Life Score Bento Gauge
                    HStack(alignment: .center, spacing: 20) {
                        // Life Score Circular Gauge
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 14)
                                    .frame(width: 104, height: 104)
                                
                                Circle()
                                    .trim(from: 0, to: animateScore ? CGFloat(snapshot.lifeScore) / 100.0 : 0)
                                    .stroke(
                                        SelfUpStyle.lifeScoreGradient,
                                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 104, height: 104)
                                    .animation(.spring(response: 1.2, dampingFraction: 0.8), value: animateScore)
                                
                                VStack(spacing: 0) {
                                    Text("\(snapshot.lifeScore)")
                                        .font(.system(size: 32, weight: .bold, design: .default))
                                    Text("SCORE")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(SelfUpStyle.cyberLime)
                                        .tracking(1.5)
                                }
                            }
                        }
                        
                        // Side Summary Metrics
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(SelfUpStyle.cyberLime.opacity(0.18)).frame(width: 30, height: 30)
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(SelfUpStyle.cyberLime)
                                        .font(.subheadline)
                                }
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Habits Done")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(completedHabitsCount) of \(activeHabits.count)")
                                        .font(.system(.subheadline, design: .default))
                                        .fontWeight(.bold)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(SelfUpStyle.primaryIndigo.opacity(0.18)).frame(width: 30, height: 30)
                                    Image(systemName: "checklist")
                                        .foregroundStyle(SelfUpStyle.primaryIndigo)
                                        .font(.subheadline)
                                }
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Focus Tasks")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(openTasksToday.count) Pending")
                                        .font(.system(.subheadline, design: .default))
                                        .fontWeight(.bold)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(SelfUpStyle.hyperMagenta.opacity(0.18)).frame(width: 30, height: 30)
                                    Image(systemName: "creditcard.fill")
                                        .foregroundStyle(SelfUpStyle.hyperMagenta)
                                        .font(.subheadline)
                                }
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Today Net")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(moneySummaryToday.net >= 0 ? "+" : "")\(currencySymbol) \(moneySummaryToday.net, format: .number)")
                                        .font(.system(.subheadline, design: .default))
                                        .fontWeight(.bold)
                                        .foregroundStyle(moneySummaryToday.net >= 0 ? SelfUpStyle.cyberLime : SelfUpStyle.hyperMagenta)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .bentoCard(cornerRadius: 16)
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
                                .foregroundStyle(SelfUpStyle.primaryIndigo)
                        }
                        
                        Chart(activityData) { day in
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Life Score", day.score)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(SelfUpStyle.primaryIndigo)
                            .lineStyle(StrokeStyle(lineWidth: 3.5))
                            
                            AreaMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Life Score", day.score)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [SelfUpStyle.primaryIndigo.opacity(0.3), SelfUpStyle.primaryIndigo.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 135)
                        .chartYScale(domain: 0...100)
                    }
                    .premiumCard(cornerRadius: 16)
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
}

struct HabitQuickCell: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    private let trackingService = TrackingService()
    @State private var celebrationToken = 0
    
    private var isCompletedToday: Bool {
        ProgressService.isCompleted(habit, on: Date())
    }
    
    private var tintColor: Color {
        switch habit.tintName {
        case "green": return .emerald
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .coral
        case "teal": return .teal
        case "indigo": return SelfUpStyle.primaryIndigo
        default: return SelfUpStyle.primaryIndigo
        }
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                let didComplete = (try? trackingService.toggleHabit(habit, on: Date(), context: modelContext)) == true
                if didComplete {
                    celebrationToken += 1
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
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isCompletedToday ? tintColor : Color(.secondarySystemGroupedBackground))
                    .shadow(color: isCompletedToday ? tintColor.opacity(0.3) : Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isCompletedToday ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .pressableScale(scale: 0.94)
        .overlay {
            if celebrationToken > 0 {
                CompletionMotionView(color: tintColor, compact: true)
                    .id(celebrationToken)
            }
        }
    }
}
