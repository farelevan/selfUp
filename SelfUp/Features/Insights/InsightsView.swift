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
                VStack(spacing: 16) {
                    Picker("Range", selection: $selectedRange) {
                        Text("7 Days").tag(7)
                        Text("30 Days").tag(30)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Life Score History")
                            .font(.headline)
                        
                        Chart(lifeScoreHistory) { day in
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Life Score", day.score)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 150)
                        .chartYScale(domain: 0...100)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Habit Consistency")
                            .font(.headline)
                        
                        if activeHabits.isEmpty {
                            Text("No habits tracked yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(activeHabits) { habit in
                                HStack {
                                    Image(systemName: habit.symbol)
                                        .foregroundStyle(.blue)
                                    Text(habit.title)
                                    Spacer()
                                    Text("Streak: \(ProgressService.streak(completionDates: habit.completions.map { $0.date }, through: Date())) days")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Task Completion Metrics")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Completed: \(completedTasksCount)")
                                Text("Pending: \(pendingTasksCount)")
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(taskCompletionRate, format: .number.precision(.fractionLength(0...1)))%")
                                    .font(.title)
                                    .bold()
                                    .foregroundStyle(.green)
                                Text("Completion Rate")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
