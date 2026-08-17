import Foundation

struct ProgressSnapshot {
    let level: Int
    let xp: Int
    let spentXP: Int
    let currentXP: Int
    let xpForNextLevel: Int
    let xpProgress: Double
    let lifeScore: Int
}

enum ProgressService {
    static func streak(completionDates: [Date], through day: Date, calendar: Calendar = .current) -> Int {
        let normalizedDates = Set(completionDates.map { calendar.startOfDay(for: $0) })
        let targetToday = calendar.startOfDay(for: day)
        let targetYesterday = calendar.date(byAdding: .day, value: -1, to: targetToday)!
        
        var currentDay = targetToday
        if !normalizedDates.contains(currentDay) {
            currentDay = targetYesterday
            if !normalizedDates.contains(currentDay) {
                return 0
            }
        }
        
        var streak = 0
        while normalizedDates.contains(currentDay) {
            streak += 1
            currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
        }
        return streak
    }
    
    static func isCompleted(_ habit: Habit, on date: Date, calendar: Calendar = .current) -> Bool {
        habit.completions.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    static func lifeScore(habits: [Habit], tasks: [TaskItem], transactions: [Transaction], on date: Date, calendar: Calendar = .current) -> Int {
        let activeHabits = habits.filter { !$0.isArchived && $0.isScheduled(on: date, calendar: calendar) }
        let completedActiveHabitsCount = activeHabits.filter { isCompleted($0, on: date, calendar: calendar) }.count
        let habitFraction = activeHabits.isEmpty ? 0.0 : Double(completedActiveHabitsCount) / Double(activeHabits.count)
        
        let tasksDueToday = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
        let completedTasksDueTodayCount = tasksDueToday.filter { $0.completedAt != nil }.count
        let taskFraction = tasksDueToday.isEmpty ? 0.0 : Double(completedTasksDueTodayCount) / Double(tasksDueToday.count)
        
        let loggedTransaction = transactions.contains { calendar.isDate($0.date, inSameDayAs: date) }
        let transactionScore = loggedTransaction ? 10.0 : 0.0
        
        let score = Int(round(50.0 * habitFraction + 40.0 * taskFraction + transactionScore))
        return max(0, min(100, score))
    }
    
    static func totalXP(habits: [Habit], tasks: [TaskItem], calendar: Calendar = .current) -> Int {
        var xp = 0
        for habit in habits {
            let uniqueDays = Set(habit.completions.map { calendar.startOfDay(for: $0.date) })
            xp += uniqueDays.count * habit.xpReward
        }
        for task in tasks {
            if task.completedAt != nil {
                xp += task.xpReward
            }
        }
        return xp
    }
    
    static func snapshot(habits: [Habit], tasks: [TaskItem], transactions: [Transaction], rewards: [Reward] = [], on date: Date, calendar: Calendar = .current) -> ProgressSnapshot {
        let xp = totalXP(habits: habits, tasks: tasks, calendar: calendar)
        let level = 1 + (xp / 100)
        let xpInLevel = xp % 100
        let xpProgress = Double(xpInLevel) / 100.0
        let score = lifeScore(habits: habits, tasks: tasks, transactions: transactions, on: date, calendar: calendar)
        
        let spentXp = rewards.filter { $0.redeemedAt != nil }.reduce(0) { $0 + $1.xpCost }
        let currentXp = max(0, xp - spentXp)
        
        return ProgressSnapshot(
            level: level,
            xp: xp,
            spentXP: spentXp,
            currentXP: currentXp,
            xpForNextLevel: 100,
            xpProgress: xpProgress,
            lifeScore: score
        )
    }
}
