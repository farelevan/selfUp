import XCTest
@testable import SelfUp

final class ModelDefaultsTests: XCTestCase {
    func testNewHabitStartsWithNoCompletionsAndDefaultXP() {
        let habit = Habit(title: "Drink water")
        XCTAssertEqual(habit.xpReward, 10)
        XCTAssertTrue(habit.completions.isEmpty)
        XCTAssertFalse(habit.isArchived)
    }

    func testNewTaskStartsInInboxAsPlanned() {
        let task = TaskItem(title: "Plan launch")

        XCTAssertEqual(task.effectivePeriod, .inbox)
        XCTAssertEqual(task.effectiveStatus, .planned)
        XCTAssertNil(task.completedAt)
    }

    func testTaskStatusTransitionsKeepCompletionDateConsistent() {
        let task = TaskItem(title: "Plan launch")
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        task.move(to: .inProgress, on: date)
        XCTAssertEqual(task.effectiveStatus, .inProgress)
        XCTAssertEqual(task.startedAt, date)

        task.move(to: .completed, on: date)
        XCTAssertEqual(task.effectiveStatus, .completed)
        XCTAssertEqual(task.completedAt, date)

        task.move(to: .planned, on: date)
        XCTAssertEqual(task.effectiveStatus, .planned)
        XCTAssertNil(task.completedAt)
    }

    func testMigratedTaskWithMissingWorkflowValuesUsesSafeDefaults() {
        let task = TaskItem(title: "Existing task")
        task.period = nil
        task.workflowStatus = nil

        XCTAssertEqual(task.effectivePeriod, .inbox)
        XCTAssertEqual(task.effectiveStatus, .planned)
    }

    func testHabitScheduleSupportsSelectedWeekdaysAndLegacyDailyDefault() {
        let calendar = Calendar(identifier: .gregorian)
        let monday = calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))!
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        let habit = Habit(title: "Gym", scheduledWeekdays: 1 << 2)

        XCTAssertTrue(habit.isScheduled(on: monday, calendar: calendar))
        XCTAssertFalse(habit.isScheduled(on: tuesday, calendar: calendar))
        habit.scheduledWeekdays = nil
        XCTAssertTrue(habit.isScheduled(on: tuesday, calendar: calendar))
    }

    func testRecurringTaskCalculatesNextOccurrence() {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: 16))!
        let task = TaskItem(title: "Weekly review", recurrence: .weekly)

        XCTAssertEqual(task.nextOccurrence(after: date, calendar: calendar), calendar.date(byAdding: .day, value: 7, to: date))
    }
}
