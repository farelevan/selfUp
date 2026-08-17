import Foundation

struct XPSourceBreakdown {
    let habitXP: Int
    let taskXP: Int

    var totalXP: Int {
        let (total, overflow) = habitXP.addingReportingOverflow(taskXP)
        return overflow ? Int.max : total
    }
}

struct ProgressAchievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let current: Int
    let target: Int
    let isUnlocked: Bool

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, Double(current) / Double(target)))
    }
}

struct ProgressSnapshot {
    let level: Int
    let levelTitle: String
    let xp: Int
    let spentXP: Int
    let currentXP: Int
    /// XP required to traverse the current level.
    let xpForNextLevel: Int
    let xpIntoLevel: Int
    let xpToNextLevel: Int
    let xpProgress: Double
    let lifeScore: Int
    let sourceBreakdown: XPSourceBreakdown
    let achievements: [ProgressAchievement]
}

enum RewardRedemptionError: Error, LocalizedError, Equatable {
    case alreadyRedeemed
    case insufficientXP(required: Int, available: Int)
    case invalidCost

    var errorDescription: String? {
        switch self {
        case .alreadyRedeemed:
            return "This reward has already been redeemed."
        case .insufficientXP(let required, let available):
            return "You need \(required - available) more XP to redeem this reward."
        case .invalidCost:
            return "This reward has an invalid XP cost."
        }
    }
}

enum RewardsService {
    static func canRedeem(_ reward: Reward, availableXP: Int) -> Bool {
        reward.redeemedAt == nil && reward.xpCost > 0 && availableXP >= reward.xpCost
    }

    @discardableResult
    static func redeem(_ reward: Reward, availableXP: Int, on date: Date = Date()) throws -> Date {
        guard reward.redeemedAt == nil else {
            throw RewardRedemptionError.alreadyRedeemed
        }
        guard reward.xpCost > 0 else {
            throw RewardRedemptionError.invalidCost
        }
        guard availableXP >= reward.xpCost else {
            throw RewardRedemptionError.insufficientXP(
                required: reward.xpCost,
                available: max(0, availableXP)
            )
        }

        reward.redeemedAt = date
        return date
    }
}

enum ProgressService {
    private static let baseLevelXP = 100
    private static let levelXPIncrement = 50

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

    static func longestStreak(completionDates: [Date], calendar: Calendar = .current) -> Int {
        let days = Set(completionDates.map { calendar.startOfDay(for: $0) }).sorted()
        guard let first = days.first else { return 0 }

        var longest = 1
        var current = 1
        var previous = first

        for day in days.dropFirst() {
            if calendar.date(byAdding: .day, value: 1, to: previous) == day {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
            previous = day
        }

        return longest
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

    static func sourceBreakdown(habits: [Habit], tasks: [TaskItem], calendar: Calendar = .current) -> XPSourceBreakdown {
        var habitXP = 0
        for habit in habits {
            // Corrupt duplicate completions must not grant XP twice. Taking the
            // largest award also makes the result deterministic across fetch order.
            var awardByDay: [Date: Int] = [:]
            for completion in habit.completions {
                let day = calendar.startOfDay(for: completion.date)
                let award = max(0, completion.xpAwarded ?? habit.xpReward)
                awardByDay[day] = max(awardByDay[day] ?? 0, award)
            }
            for award in awardByDay.values {
                habitXP = addingXP(habitXP, award)
            }
        }

        var taskXP = 0
        for task in tasks where task.completedAt != nil {
            taskXP = addingXP(taskXP, max(0, task.xpAwarded ?? task.xpReward))
        }

        return XPSourceBreakdown(habitXP: habitXP, taskXP: taskXP)
    }

    static func totalXP(habits: [Habit], tasks: [TaskItem], calendar: Calendar = .current) -> Int {
        sourceBreakdown(habits: habits, tasks: tasks, calendar: calendar).totalXP
    }

    static func snapshot(habits: [Habit], tasks: [TaskItem], transactions: [Transaction], rewards: [Reward] = [], on date: Date, calendar: Calendar = .current) -> ProgressSnapshot {
        let breakdown = sourceBreakdown(habits: habits, tasks: tasks, calendar: calendar)
        let xp = breakdown.totalXP
        let levelState = levelState(for: xp)
        let score = lifeScore(habits: habits, tasks: tasks, transactions: transactions, on: date, calendar: calendar)

        var spentXP = 0
        for reward in rewards where reward.redeemedAt != nil {
            spentXP = addingXP(spentXP, max(0, reward.xpCost))
        }
        let currentXP = max(0, xp - min(xp, spentXP))

        return ProgressSnapshot(
            level: levelState.level,
            levelTitle: levelTitle(for: levelState.level),
            xp: xp,
            spentXP: spentXP,
            currentXP: currentXP,
            xpForNextLevel: levelState.required,
            xpIntoLevel: levelState.into,
            xpToNextLevel: levelState.remaining,
            xpProgress: levelState.progress,
            lifeScore: score,
            sourceBreakdown: breakdown,
            achievements: achievements(
                habits: habits,
                tasks: tasks,
                spentXP: spentXP,
                level: levelState.level,
                calendar: calendar
            )
        )
    }

    static func levelTitle(for level: Int) -> String {
        switch max(1, level) {
        case 1: return "Getting Started"
        case 2: return "Momentum"
        case 3...4: return "Builder"
        case 5...7: return "Achiever"
        case 8...11: return "Champion"
        default: return "Legend"
        }
    }

    private static func levelState(for totalXP: Int) -> (level: Int, into: Int, remaining: Int, required: Int, progress: Double) {
        let xp = max(0, totalXP)
        // Cumulative XP after n level-ups is 25n² + 75n. Solving the
        // quadratic avoids a loop whose cost grows with a long-lived account.
        let discriminant = 5_625.0 + 100.0 * Double(xp)
        let completedLevels = max(0, Int(floor((sqrt(discriminant) - 75.0) / 50.0)))
        let level = completedLevels + 1
        let levelStartXP = cumulativeXP(after: completedLevels)
        let required = xpRequiredToAdvance(from: level)
        let into = max(0, min(required, xp - min(xp, levelStartXP)))
        let remaining = max(0, required - into)
        let progress = required == 0 ? 0 : min(1, max(0, Double(into) / Double(required)))
        return (level, into, remaining, required, progress)
    }

    private static func xpRequiredToAdvance(from level: Int) -> Int {
        let steps = max(0, level - 1)
        let (increase, multiplyOverflow) = steps.multipliedReportingOverflow(by: levelXPIncrement)
        guard !multiplyOverflow else { return Int.max }
        let (result, addOverflow) = baseLevelXP.addingReportingOverflow(increase)
        return addOverflow ? Int.max : result
    }

    private static func cumulativeXP(after completedLevels: Int) -> Int {
        guard completedLevels > 0 else { return 0 }
        let (scaled, scaleOverflow) = completedLevels.multipliedReportingOverflow(by: 25)
        guard !scaleOverflow else { return Int.max }
        let (factor, addOverflow) = scaled.addingReportingOverflow(75)
        guard !addOverflow else { return Int.max }
        let (total, totalOverflow) = completedLevels.multipliedReportingOverflow(by: factor)
        return totalOverflow ? Int.max : total
    }

    private static func addingXP(_ current: Int, _ award: Int) -> Int {
        let (result, overflow) = current.addingReportingOverflow(max(0, award))
        return overflow ? Int.max : result
    }

    private static func achievements(habits: [Habit], tasks: [TaskItem], spentXP: Int, level: Int, calendar: Calendar) -> [ProgressAchievement] {
        let completedHabitCount = habits.reduce(0) { $0 + $1.completions.count }
        let completedTaskCount = tasks.filter { $0.completedAt != nil }.count
        let longestHistoricalStreak = habits.map {
            longestStreak(completionDates: $0.completions.map(\.date), calendar: calendar)
        }.max() ?? 0

        return [
            ProgressAchievement(
                id: "first-step",
                title: "First Step",
                detail: "Complete your first habit",
                symbol: "sparkles",
                current: min(1, completedHabitCount),
                target: 1,
                isUnlocked: completedHabitCount > 0
            ),
            ProgressAchievement(
                id: "task-starter",
                title: "Task Starter",
                detail: "Finish your first task",
                symbol: "checkmark.seal.fill",
                current: min(1, completedTaskCount),
                target: 1,
                isUnlocked: completedTaskCount > 0
            ),
            ProgressAchievement(
                id: "week-warrior",
                title: "Week Warrior",
                detail: "Reach a 7-day habit streak",
                symbol: "flame.fill",
                current: min(7, longestHistoricalStreak),
                target: 7,
                isUnlocked: longestHistoricalStreak >= 7
            ),
            ProgressAchievement(
                id: "level-five",
                title: "High Five",
                detail: "Reach level 5",
                symbol: "crown.fill",
                current: min(5, level),
                target: 5,
                isUnlocked: level >= 5
            ),
            ProgressAchievement(
                id: "reward-yourself",
                title: "Reward Yourself",
                detail: "Redeem your first reward",
                symbol: "gift.fill",
                current: spentXP > 0 ? 1 : 0,
                target: 1,
                isUnlocked: spentXP > 0
            )
        ]
    }
}
