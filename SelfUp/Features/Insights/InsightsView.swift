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
                    
                    // Life Score History Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Life Score Analytics")
                                    .font(.system(.title3, design: .rounded))
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
                    .glowingCard(color: SelfUpStyle.primaryIndigo, cornerRadius: 20)
                    .padding(.horizontal)
                    
                    // Habit Consistency Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Habit Consistency")
                                .font(.system(.title3, design: .rounded))
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
                                            .font(.system(.subheadline, design: .rounded))
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
                            .font(.system(.title3, design: .rounded))
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
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
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
