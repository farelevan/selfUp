import XCTest
@testable import SelfUp

final class ModelDefaultsTests: XCTestCase {
    func testNewHabitStartsWithNoCompletionsAndDefaultXP() {
        let habit = Habit(title: "Drink water")
        XCTAssertEqual(habit.xpReward, 10)
        XCTAssertTrue(habit.completions.isEmpty)
        XCTAssertFalse(habit.isArchived)
    }
}
