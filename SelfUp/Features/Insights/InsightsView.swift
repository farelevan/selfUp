import SwiftUI
import SwiftData
import Charts

struct HistoricalScore: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
}

struct InsightsView: View {
    @Query private var habits: [Habit]
    @Query private var tasks: [TaskItem]
    @Query private var transactions: [Transaction]
    
    @State private var selectedRange = 30
    @State private var showingSettings = false
    
    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }
    
    private var completedTasksCount: Int { tasks.filter { $0.completedAt != nil }.count }
    private var pendingTasksCount: Int { tasks.filter { $0.completedAt == nil }.count }
    private var taskCompletionRate: Double {
        let total = completedTasksCount + pendingTasksCount
        return total == 0 ? 0.0 : Double(completedTasksCount) / Double(total) * 100.0
    }
    
    private var lifeScoreHistory: [HistoricalScore] {
        let calendar = Calendar.current
        var list: [HistoricalScore] = []
        for i in (0..<selectedRange).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let score = ProgressService.lifeScore(habits: habits, tasks: tasks, transactions: transactions, on: date)
                list.append(HistoricalScore(date: date, score: score))
            }
        }
        return list
    }

    private var weeklyScores: (current: Int, previous: Int) {
        let calendar = Calendar.current
        func average(daysAgo range: Range<Int>) -> Int {
            let values = range.compactMap { offset -> Int? in
                guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
                return ProgressService.lifeScore(habits: habits, tasks: tasks, transactions: transactions, on: date)
            }
            return values.isEmpty ? 0 : values.reduce(0, +) / values.count
        }
        return (average(daysAgo: 0..<7), average(daysAgo: 7..<14))
    }

    private var weeklyRecommendations: [String] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let missedHabit = activeHabits.min { lhs, rhs in
            lhs.completions.filter { $0.date >= sevenDaysAgo }.count < rhs.completions.filter { $0.date >= sevenDaysAgo }.count
        }
        let overdue = tasks.filter { $0.completedAt == nil && ($0.dueDate ?? .distantFuture) < Date() }.count
        let expenses = transactions.filter { $0.type == .expense && $0.date >= sevenDaysAgo }
        var items: [String] = []
        if let missedHabit, missedHabit.completions.filter({ $0.date >= sevenDaysAgo }).count < 4 {
            items.append("Make ‘\(missedHabit.title)’ easier or move it to your best time of day.")
        }
        if overdue > 0 { items.append("Reschedule or finish your \(overdue) overdue task\(overdue == 1 ? "" : "s").") }
        if let topCategory = Dictionary(grouping: expenses, by: \.category).max(by: { $0.value.count < $1.value.count })?.key {
            items.append("Review \(topCategory)—it was your most frequent spending category this week.")
        }
        if items.isEmpty { items.append("Keep your rhythm: choose one meaningful habit and one priority task each morning.") }
        return Array(items.prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Range Picker
                    Picker("Range", selection: $selectedRange) {
                        Text("7 Days").tag(7)
                        Text("30 Days").tag(30)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Weekly Review")
                                    .font(.title3.bold())
                                Text("Your last 7 days, turned into next actions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(weeklyScores.current)")
                                    .font(.title.bold())
                                    .foregroundStyle(SelfUpStyle.primaryIndigo)
                                Text(weeklyScores.current >= weeklyScores.previous ? "↑ from last week" : "↓ from last week")
                                    .font(.caption2.bold())
                                    .foregroundStyle(weeklyScores.current >= weeklyScores.previous ? Color.emerald : Color.orange)
                            }
                        }
                        Divider()
                        ForEach(Array(weeklyRecommendations.enumerated()), id: \.offset) { index, recommendation in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Circle().fill(SelfUpStyle.primaryIndigo))
                                Text(recommendation)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .premiumCard(cornerRadius: 18)
                    .padding(.horizontal)
                    
                    // Life Score History Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Life Score Analytics")
                                    .font(.system(.title3, design: .default))
                                    .fontWeight(.bold)
                                Text("Last \(selectedRange) days progress trajectory")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title3)
                                .foregroundStyle(SelfUpStyle.primaryIndigo)
                        }
                        
                        Chart(lifeScoreHistory) { day in
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Life Score", day.score)
                            )
                            .foregroundStyle(SelfUpStyle.primaryIndigo)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Life Score", day.score)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [SelfUpStyle.primaryIndigo.opacity(0.25), SelfUpStyle.primaryIndigo.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 160)
                        .chartYScale(domain: 0...100)
                    }
                    .premiumCard(cornerRadius: 16)
                    .padding(.horizontal)
                    
                    // Habit Consistency Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Habit Consistency")
                                .font(.system(.title3, design: .default))
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                        }
                        
                        if activeHabits.isEmpty {
                            Text("No active habits tracked yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(activeHabits) { habit in
                                    let streak = ProgressService.streak(completionDates: habit.completions.map { $0.date }, through: Date())
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(SelfUpStyle.primaryIndigo.opacity(0.12))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: habit.symbol)
                                                .font(.subheadline)
                                                .foregroundStyle(SelfUpStyle.primaryIndigo)
                                        }
                                        
                                        Text(habit.title)
                                            .font(.system(.subheadline, design: .default))
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "flame.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                            Text("\(streak)d streak")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                                        .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }
                    .premiumCard(cornerRadius: 20)
                    .padding(.horizontal)
                    
                    // Task Completion Metrics
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Task Completion Metrics")
                            .font(.system(.title3, design: .default))
                            .fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Circle().fill(Color.emerald).frame(width: 8, height: 8)
                                    Text("Completed: \(completedTasksCount)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                HStack(spacing: 6) {
                                    Circle().fill(Color.orange).frame(width: 8, height: 8)
                                    Text("Pending: \(pendingTasksCount)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(taskCompletionRate, format: .number.precision(.fractionLength(0...1)))%")
                                    .font(.system(size: 30, weight: .bold, design: .default))
                                    .foregroundStyle(Color.emerald)
                                Text("Completion Rate")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .premiumCard(cornerRadius: 20)
                    .padding(.horizontal)
                    
                    if !transactions.isEmpty {
                        MoneyChartView(transactions: transactions, currentMonthOnly: false)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

}
