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
                    // Header Date
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Date().formatted(date: .complete, time: .omitted))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Welcome Back")
                                .font(.largeTitle)
                                .bold()
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Level Progress Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(SelfUpStyle.goldGradient)
                                .font(.title3)
                            Text("LEVEL \(snapshot.level)")
                                .font(.headline)
                                .bold()
                            Spacer()
                            Text("\(snapshot.xp) XP Total")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 10)
                                
                                Capsule()
                                    .fill(SelfUpStyle.progressGradient)
                                    .frame(width: geo.size.width * CGFloat(snapshot.xpProgress), height: 10)
                            }
                        }
                        .frame(height: 10)
                        
                        Text("\(100 - (snapshot.xp % 100)) XP left to Level \(snapshot.level + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .premiumCard()
                    .padding(.horizontal)
                    
                    // Life Score & Habit Grid Ring Row
                    HStack(alignment: .center, spacing: 16) {
                        // Life Score Circular Gauge
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 10)
                                    .frame(width: 90, height: 90)
                                
                                Circle()
                                    .trim(from: 0, to: animateScore ? CGFloat(snapshot.lifeScore) / 100.0 : 0)
                                    .stroke(
                                        SelfUpStyle.lifeScoreGradient,
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 90, height: 90)
                                    .animation(.easeOut(duration: 1.2), value: animateScore)
                                
                                Text("\(snapshot.lifeScore)")
                                    .font(.title)
                                    .bold()
                            }
                            Text("Life Score")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.secondary)
                        }
                        
                        // Side Summary Metrics
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Habits: \(completedHabitsCount)/\(activeHabits.count)")
                            }
                            HStack {
                                Image(systemName: "list.bullet.rectangle.fill")
                                    .foregroundStyle(.blue)
                                Text("Focus Tasks: \(openTasksToday.count)")
                            }
                            HStack {
                                Image(systemName: "indianrupeesign.circle.fill")
                                    .foregroundStyle(.orange)
                                Text("Net Flow: \(moneySummaryToday.net >= 0 ? "+" : "")\(moneySummaryToday.net, format: .number)")
                            }
                        }
                        .font(.subheadline)
                        .bold()
                        
                        Spacer()
                    }
                    .premiumCard()
                    .padding(.horizontal)
                    .onAppear {
                        animateScore = true
                    }
                    
                    // Habit Horizontal Quick Track
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Habits")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if activeHabits.isEmpty {
                            Text("No active habits created.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(activeHabits) { habit in
                                        HabitQuickCell(habit: habit)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // Today's Money Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Money Summary")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Income")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(currencySymbol) \(moneySummaryToday.income, format: .number)")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundStyle(.green)
                            }
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Expenses")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(currencySymbol) \(moneySummaryToday.expenses, format: .number)")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundStyle(.red)
                            }
                            Spacer()
                        }
                    }
                    .premiumCard()
                    .padding(.horizontal)
                    
                    // Task Focus list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Tasks Focus")
                            .font(.headline)
                        
                        if openTasksToday.isEmpty {
                            Text("All clear! No tasks due today.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(openTasksToday) { task in
                                HStack {
                                    Circle()
                                        .fill(task.priority == .high ? Color.red : (task.priority == .medium ? Color.orange : Color.blue))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(task.title)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    if let due = task.dueDate {
                                        Text(due, style: .date)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .premiumCard()
                    .padding(.horizontal)
                    
                    // 7-day Area Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("7-Day Life Score")
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
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .blue.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 120)
                        .chartYScale(domain: 0...100)
                    }
                    .premiumCard()
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.primary)
                    }
                }
            }
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
    
    private var isCompletedToday: Bool {
        ProgressService.isCompleted(habit, on: Date())
    }
    
    private var tintColor: Color {
        switch habit.tintName {
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .blue
        }
    }
    
    var body: some View {
        Button {
            withAnimation(.spring()) {
                _ = try? trackingService.toggleHabit(habit, on: Date(), context: modelContext)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: habit.symbol)
                    .font(.subheadline)
                    .foregroundStyle(isCompletedToday ? .white : tintColor)
                Text(habit.title)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(isCompletedToday ? .white : .primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompletedToday ? tintColor : Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCompletedToday ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
