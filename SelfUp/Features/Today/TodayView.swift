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
    
    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }
    
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
        ProgressService.snapshot(habits: habits, tasks: tasks, transactions: transactions, on: Date())
    }
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "selected_currency") ?? "Rp"
    }
    
    @State private var showingSettings = false

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
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("LEVEL \(snapshot.level)")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.blue)
                        
                        ProgressView(value: snapshot.xpProgress)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                        
                        Text("\(snapshot.xp % 100) / 100 XP to next level (Total: \(snapshot.xp) XP)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            Circle()
                                .trim(from: 0, to: CGFloat(snapshot.lifeScore) / 100.0)
                                .stroke(
                                    AngularGradient(colors: [.blue, .green, .blue], center: .center),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 80, height: 80)
                            
                            Text("\(snapshot.lifeScore)")
                                .font(.title3)
                                .bold()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Life Score")
                                .font(.headline)
                            Text("Consists of 50% habits, 40% tasks, and 10% cash flow tracking.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Habit Completion")
                                .font(.headline)
                            Text("\(completedHabitsCount) of \(activeHabits.count) completed today")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(completedHabitsCount == activeHabits.count && !activeHabits.isEmpty ? .green : .secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today's Cash Flow")
                            .font(.headline)
                        
                        HStack {
                            Text("Income: \(currencySymbol) \(moneySummaryToday.income, format: .number)")
                                .foregroundStyle(.green)
                            Spacer()
                            Text("Expense: \(currencySymbol) \(moneySummaryToday.expenses, format: .number)")
                                .foregroundStyle(.red)
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tasks to Focus")
                            .font(.headline)
                        
                        if openTasksToday.isEmpty {
                            Text("No urgent or high priority tasks due today.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(openTasksToday) { task in
                                HStack {
                                    Image(systemName: task.priority == .high ? "exclamationmark.circle.fill" : "circle")
                                        .foregroundStyle(task.priority == .high ? .red : .orange)
                                    Text(task.title)
                                    Spacer()
                                    if let due = task.dueDate {
                                        Text(due, style: .date)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
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
                        Text("7-Day Consistency")
                            .font(.headline)
                        
                        Chart(activityData) { day in
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Life Score", day.score)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.blue)
                            
                            AreaMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Life Score", day.score)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .blue.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                        }
                        .frame(height: 120)
                        .chartYScale(domain: 0...100)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
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
