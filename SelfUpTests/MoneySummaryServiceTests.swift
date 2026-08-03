import XCTest
@testable import SelfUp

final class MoneySummaryServiceTests: XCTestCase {
    func testMoneySummarySubtractsExpensesFromIncome() {
        let transactions = [
            Transaction(amount: 100, type: .income, category: "Salary"),
            Transaction(amount: 35, type: .expense, category: "Food")
        ]
        let summary = MoneySummaryService.summary(for: transactions)
        XCTAssertEqual(summary.net, Decimal(65))
    }
}
