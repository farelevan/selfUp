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
                    
                    // Level Progress Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(SelfUpStyle.goldGradient)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.white)
                                    .font(.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("LEVEL \(snapshot.level)")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                Text("\(snapshot.xp) XP Total")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(100 - (snapshot.xp % 100)) XP to Level \(snapshot.level + 1)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(SelfUpStyle.primaryIndigo.opacity(0.1)))
                                .foregroundStyle(SelfUpStyle.primaryIndigo)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 10)
                                
                                Capsule()
                                    .fill(SelfUpStyle.progressGradient)
                                    .frame(width: max(12, geo.size.width * CGFloat(snapshot.xpProgress)), height: 10)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: snapshot.xpProgress)
                            }
                        }
                        .frame(height: 10)
                    }
                    .glowingCard(color: SelfUpStyle.primaryIndigo, cornerRadius: 20)
                    .padding(.horizontal)
                    
                    // Life Score Circular Gauge & Status Card
                    HStack(alignment: .center, spacing: 20) {
                        // Life Score Circular Gauge
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 12)
                                    .frame(width: 100, height: 100)
                                
                                Circle()
                                    .trim(from: 0, to: animateScore ? CGFloat(snapshot.lifeScore) / 100.0 : 0)
                                    .stroke(
                                        SelfUpStyle.lifeScoreGradient,
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: Color.indigo.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .animation(.spring(response: 1.2, dampingFraction: 0.8), value: animateScore)
                                
                                VStack(spacing: 0) {
                                    Text("\(snapshot.lifeScore)")
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                    Text("SCORE")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(.secondary)
                                        .tracking(1)
                                }
                            }
                        }
                        
                        // Side Summary Metrics
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(Color.emerald.opacity(0.15)).frame(width: 28, height: 28)
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.emerald)
                                        .font(.caption)
                                }
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Habits Done")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(completedHabitsCount) of \(activeHabits.count)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(Color.indigo.opacity(0.15)).frame(width: 28, height: 28)
                                    Image(systemName: "checklist")
                                        .foregroundStyle(SelfUpStyle.primaryIndigo)
                                        .font(.caption)
                                }
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Focus Tasks")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(openTasksToday.count) Pending")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(Color.orange.opacity(0.15)).frame(width: 28, height: 28)
                                    Image(systemName: "creditcard.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                }
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Today Net")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(moneySummaryToday.net >= 0 ? "+" : "")\(currencySymbol) \(moneySummaryToday.net, format: .number)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(moneySummaryToday.net >= 0 ? Color.emerald : Color.coral)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .premiumCard(cornerRadius: 20)
                    .padding(.horizontal)
                    .onAppear {
                        animateScore = true
                    }
                    
                    // Habit Horizontal Quick Track
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today's Habits")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(completedHabitsCount)/\(activeHabits.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if activeHabits.isEmpty {
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(Color.emerald)
                                Text("No active habits created yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
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
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Money Summary")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundStyle(Color.emerald)
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.right.circle.fill")
                                        .foregroundStyle(Color.emerald)
                                        .font(.caption)
                                    Text("Income")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("\(currencySymbol) \(moneySummaryToday.income, format: .number)")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.emerald)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.emerald.opacity(0.08)))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .foregroundStyle(Color.coral)
                                        .font(.caption)
                                    Text("Expenses")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("\(currencySymbol) \(moneySummaryToday.expenses, format: .number)")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.coral)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.coral.opacity(0.08)))
                        }
                    }
                    .premiumCard(cornerRadius: 20)
                    .padding(.horizontal)
                    
                    // Task Focus List
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Focus Tasks")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                            Spacer()
                            if !openTasksToday.isEmpty {
                                Text("\(openTasksToday.count) Due")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.indigo.opacity(0.1)))
                                    .foregroundStyle(SelfUpStyle.primaryIndigo)
                            }
                        }
                        
                        if openTasksToday.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.emerald)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("All Tasks Clear!")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Text("You've finished all focus tasks for today.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 6)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(openTasksToday) { task in
                                    HStack(spacing: 12) {
                                        Capsule()
                                            .fill(task.priority == .high ? Color.coral : (task.priority == .medium ? Color.orange : SelfUpStyle.primaryIndigo))
                                            .frame(width: 4, height: 24)
                                        
                                        Text(task.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        if let due = task.dueDate {
                                            Text(due, style: .date)
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
                                }
                            }
                        }
                    }
                    .premiumCard(cornerRadius: 20)
                    .padding(.horizontal)
                    
                    // 7-Day Life Score Chart
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("7-Day Life Score Trend")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                Text("Track your overall consistency")
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
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
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
                        .frame(height: 130)
                        .chartYScale(domain: 0...100)
                    }
                    .premiumCard(cornerRadius: 20)
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
                _ = try? trackingService.toggleHabit(habit, on: Date(), context: modelContext)
                if !isCompletedToday {
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
    }
}

