import XCTest
@testable import SelfUp

final class MoneySummaryServiceTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testMoneySummarySubtractsExpensesFromIncome() {
        let transactions = [
            Transaction(amount: 100, type: .income, category: "Salary"),
            Transaction(amount: 35, type: .expense, category: "Food")
        ]
        let summary = MoneySummaryService.summary(for: transactions)
        XCTAssertEqual(summary.net, Decimal(65))
    }

    func testFunBudgetCountsOnlyPositiveCurrentEntertainmentExpensesThroughNow() {
        let now = date(2026, 8, 17)
        let transactions = [
            Transaction(amount: Decimal(string: "25.25")!, type: .expense, category: "  entertainment\n", date: date(2026, 8, 10)),
            Transaction(amount: 50, type: .income, category: "Entertainment", date: date(2026, 8, 11)),
            Transaction(amount: -10, type: .expense, category: "Entertainment", date: date(2026, 8, 12)),
            Transaction(amount: 40, type: .expense, category: "Shopping", date: date(2026, 8, 13)),
            Transaction(amount: 30, type: .expense, category: "Entertainment", date: date(2026, 7, 31)),
            Transaction(amount: 35, type: .expense, category: "Entertainment", date: date(2026, 8, 18))
        ]

        let snapshot = FunBudgetService.snapshot(
            for: transactions,
            limit: 100,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.spent, Decimal(string: "25.25"))
        XCTAssertEqual(snapshot.remaining, Decimal(string: "74.75"))
        XCTAssertEqual(snapshot.attention, .onTrack)
        XCTAssertEqual(snapshot.warningAction, .none)
    }

    func testFunBudgetUsesExactDecimalEightyPercentThreshold() {
        let now = date(2026, 8, 10)
        let below = Transaction(
            amount: Decimal(string: "79.99")!,
            type: .expense,
            category: "Entertainment",
            date: date(2026, 8, 9)
        )
        let exactRemainder = Transaction(
            amount: Decimal(string: "0.01")!,
            type: .expense,
            category: "ENTERTAINMENT",
            date: date(2026, 8, 10, hour: 8)
        )

        let belowSnapshot = FunBudgetService.snapshot(
            for: [below],
            limit: 100,
            now: now,
            calendar: calendar
        )
        let exactSnapshot = FunBudgetService.snapshot(
            for: [below, exactRemainder],
            limit: 100,
            now: now,
            calendar: calendar
        )

        XCTAssertFalse(belowSnapshot.isWarningThresholdReached)
        XCTAssertEqual(belowSnapshot.warningAction, .none)
        XCTAssertTrue(exactSnapshot.isWarningThresholdReached)
        XCTAssertEqual(exactSnapshot.attention, .nearlyDepleted)
        XCTAssertEqual(exactSnapshot.warningAction, .schedule(date(2026, 8, 15, hour: 9)))
    }

    func testFunBudgetWarnsImmediatelyAtOrAfterMidMonth() {
        let now = date(2026, 8, 15, hour: 9)
        let transaction = Transaction(
            amount: 80,
            type: .expense,
            category: "Entertainment",
            date: date(2026, 8, 14)
        )

        let snapshot = FunBudgetService.snapshot(
            for: [transaction],
            limit: 100,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.warningAction, .notifyNow)
        XCTAssertEqual(snapshot.periodKey, "2026-08")
    }

    func testFunBudgetMonthBoundaryExcludesDecemberFromJanuary() {
        let now = date(2027, 1, 5)
        let transactions = [
            Transaction(amount: 90, type: .expense, category: "Entertainment", date: date(2026, 12, 31)),
            Transaction(amount: 20, type: .expense, category: "Entertainment", date: date(2027, 1, 1))
        ]

        let snapshot = FunBudgetService.snapshot(
            for: transactions,
            limit: 100,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.spent, 20)
        XCTAssertEqual(snapshot.periodKey, "2027-01")
        XCTAssertEqual(snapshot.warningAction, .none)
    }

    func testFunBudgetStoreRoundTripsDecimalWithoutDoubleConversion() {
        let suiteName = "MoneySummaryServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = FunBudgetStore(defaults: defaults)
        let limit = Decimal(string: "1234567890.123456789")!

        store.limit = limit

        XCTAssertEqual(store.limit, limit)
        XCTAssertEqual(defaults.string(forKey: "finance.funBudget.limit.v1"), NSDecimalNumber(decimal: limit).stringValue)
    }

    func testFunBudgetStoreKeepsScheduledContentFingerprintInSync() {
        let suiteName = "MoneySummaryServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = FunBudgetStore(defaults: defaults)
        let warningDate = date(2026, 8, 15, hour: 9)

        store.recordScheduled(period: "2026-08", date: warningDate, fingerprint: "Rp|80|100")

        XCTAssertEqual(store.scheduledPeriod, "2026-08")
        XCTAssertEqual(store.scheduledDate, warningDate)
        XCTAssertEqual(store.scheduledFingerprint, "Rp|80|100")

        store.clearScheduled()
        XCTAssertNil(store.scheduledPeriod)
        XCTAssertNil(store.scheduledDate)
        XCTAssertNil(store.scheduledFingerprint)
    }

    func testExpenseBreakdownCombinesReservedOtherCategoryWithoutDuplicateIDs() {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "Food"),
            Transaction(amount: 90, type: .expense, category: "Transport"),
            Transaction(amount: 80, type: .expense, category: "Shopping"),
            Transaction(amount: 70, type: .expense, category: "Rent"),
            Transaction(amount: 60, type: .expense, category: "Entertainment"),
            Transaction(amount: 50, type: .expense, category: "Other"),
            Transaction(amount: 25, type: .expense, category: " other "),
            Transaction(amount: 999, type: .income, category: "Other")
        ]

        let shares = CategoryShare.expenseBreakdown(for: transactions)

        XCTAssertEqual(shares.count, 5)
        XCTAssertEqual(Set(shares.map(\.id)).count, shares.count)
        XCTAssertEqual(shares.first(where: { $0.category == "Other" })?.amount, 135)
        XCTAssertEqual(shares.reduce(Decimal.zero) { $0 + $1.amount }, 475)
    }

    func testExpenseBreakdownCanonicalizesOtherWhenAggregationIsNotNeeded() {
        let transactions = [
            Transaction(amount: 20, type: .expense, category: "Food"),
            Transaction(amount: 10, type: .expense, category: "Other"),
            Transaction(amount: 5, type: .expense, category: "OTHER")
        ]

        let shares = CategoryShare.expenseBreakdown(for: transactions)

        XCTAssertEqual(shares.count, 2)
        XCTAssertEqual(shares.first(where: { $0.category == "Other" })?.amount, 15)
    }
}
