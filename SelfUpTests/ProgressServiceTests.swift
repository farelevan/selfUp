import XCTest
@testable import SelfUp

final class ProgressServiceTests: XCTestCase {
    var calendar: Calendar!
    var today: Date!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        today = calendar.startOfDay(for: Date())
    }
    
    func testStreakCountsConsecutiveCompletionDaysEndingToday() {
        let dates = [today!, calendar.date(byAdding: .day, value: -1, to: today!)!]
        XCTAssertEqual(ProgressService.streak(completionDates: dates, through: today!), 2)
    }
}
