import XCTest
import SwiftData
@testable import SelfUp

final class TrackingServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var service: TrackingService!
    var today: Date!
    
    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Habit.self, HabitCompletion.self, TaskItem.self, configurations: config)
        context = container.mainContext
        service = TrackingService()
        today = Calendar.current.startOfDay(for: Date())
    }
    
    @MainActor
    func testCompletingSameHabitTwiceOnOneDayCreatesOneCompletion() throws {
        let habit = Habit(title: "Drink water")
        context.insert(habit)
        
        XCTAssertTrue(try service.toggleHabit(habit, on: today, context: context))
        XCTAssertFalse(try service.toggleHabit(habit, on: today, context: context))
        XCTAssertEqual(habit.completions.count, 1)
    }
}
