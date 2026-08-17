import XCTest
import SwiftData
@testable import SelfUp

final class ProgressServiceTests: XCTestCase {
    var calendar: Calendar!
    var today: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        today = calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))!
    }

    func testStreakCountsConsecutiveCompletionDaysEndingToday() {
        let dates = [today!, calendar.date(byAdding: .day, value: -1, to: today!)!]
        XCTAssertEqual(
            ProgressService.streak(completionDates: dates, through: today, calendar: calendar),
            2
        )
    }

    func testLongestStreakPreservesHistoricalAchievement() {
        let dates = (8...14).map {
            calendar.date(byAdding: .day, value: -$0, to: today!)!
        }

        XCTAssertEqual(
            ProgressService.streak(completionDates: dates, through: today, calendar: calendar),
            0
        )
        XCTAssertEqual(
            ProgressService.longestStreak(completionDates: dates, calendar: calendar),
            7
        )

        let habit = Habit(title: "Historical streak")
        habit.completions = dates.map { HabitCompletion(date: $0, habit: habit, xpAwarded: 10) }
        let snapshot = ProgressService.snapshot(
            habits: [habit],
            tasks: [],
            transactions: [],
            on: today,
            calendar: calendar
        )
        let achievement = snapshot.achievements.first { $0.id == "week-warrior" }
        XCTAssertEqual(achievement?.current, 7)
        XCTAssertEqual(achievement?.target, 7)
        XCTAssertTrue(achievement?.isUnlocked == true)
    }

    func testProgressiveLevelBoundaries() {
        let cases: [(xp: Int, level: Int, into: Int, remaining: Int, required: Int)] = [
            (0, 1, 0, 100, 100),
            (99, 1, 99, 1, 100),
            (100, 2, 0, 150, 150),
            (249, 2, 149, 1, 150),
            (250, 3, 0, 200, 200)
        ]

        for item in cases {
            let progress = snapshot(withTaskXP: item.xp)
            XCTAssertEqual(progress.level, item.level, "Unexpected level at \(item.xp) XP")
            XCTAssertEqual(progress.xpIntoLevel, item.into)
            XCTAssertEqual(progress.xpToNextLevel, item.remaining)
            XCTAssertEqual(progress.xpForNextLevel, item.required)
            XCTAssertEqual(
                progress.xpProgress,
                Double(item.into) / Double(item.required),
                accuracy: 0.000_001
            )
        }

        XCTAssertEqual(snapshot(withTaskXP: 100).levelTitle, "Momentum")
        XCTAssertEqual(snapshot(withTaskXP: 250).levelTitle, "Builder")
    }

    func testAwardSnapshotsDoNotChangeWhenConfiguredRewardsAreEdited() {
        let habit = Habit(title: "Read", xpReward: 10)
        let completion = HabitCompletion(date: today, habit: habit, xpAwarded: 10)
        habit.completions = [completion]

        let task = TaskItem(
            title: "Plan",
            completedAt: today,
            xpReward: 20,
            xpAwarded: 20
        )

        habit.xpReward = 50
        task.xpReward = 100

        let breakdown = ProgressService.sourceBreakdown(
            habits: [habit],
            tasks: [task],
            calendar: calendar
        )
        XCTAssertEqual(breakdown.habitXP, 10)
        XCTAssertEqual(breakdown.taskXP, 20)
        XCTAssertEqual(breakdown.totalXP, 30)
    }

    func testLegacyAwardsFallBackToCurrentConfiguredReward() {
        let habit = Habit(title: "Read", xpReward: 15)
        let completion = HabitCompletion(date: today, habit: habit)
        habit.completions = [completion]

        let task = TaskItem(title: "Plan", completedAt: today, xpReward: 20)
        task.xpAwarded = nil

        XCTAssertEqual(
            ProgressService.totalXP(habits: [habit], tasks: [task], calendar: calendar),
            35
        )
    }

    @MainActor
    func testTrackingSnapshotsAwardsAndExplicitUndoClearsThem() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Habit.self,
            HabitCompletion.self,
            TaskItem.self,
            configurations: configuration
        )
        let context = container.mainContext
        let service = TrackingService()
        let habit = Habit(title: "Read", xpReward: 15)
        let task = TaskItem(title: "Plan", xpReward: 25)
        context.insert(habit)
        context.insert(task)

        XCTAssertTrue(try service.toggleHabit(habit, on: today, context: context))
        XCTAssertEqual(habit.completions.first?.xpAwarded, 15)
        XCTAssertTrue(try service.toggleTask(task, on: today, context: context))
        XCTAssertEqual(task.xpAwarded, 25)

        XCTAssertTrue(service.undoTaskCompletion(task))
        XCTAssertNil(task.completedAt)
        XCTAssertNil(task.xpAwarded)
        XCTAssertTrue(try service.undoHabitCompletion(habit, on: today, context: context))
        XCTAssertTrue(habit.completions.isEmpty)
    }

    private func snapshot(withTaskXP xp: Int) -> ProgressSnapshot {
        let tasks: [TaskItem]
        if xp == 0 {
            tasks = []
        } else {
            tasks = [TaskItem(
                title: "XP fixture",
                completedAt: today,
                xpReward: xp,
                xpAwarded: xp
            )]
        }

        return ProgressService.snapshot(
            habits: [],
            tasks: tasks,
            transactions: [],
            on: today,
            calendar: calendar
        )
    }
}
