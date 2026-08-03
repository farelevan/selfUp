import XCTest
@testable import SelfUp

final class TransactionValidationTests: XCTestCase {
    func testTransactionDraftRejectsZeroAmount() {
        XCTAssertThrowsError(try TransactionDraft(amountText: "0", type: .expense, category: "Food").makeTransaction())
    }
}
