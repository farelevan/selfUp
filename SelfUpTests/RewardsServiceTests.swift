import XCTest
@testable import SelfUp

final class RewardsServiceTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

    func testXpBalanceDeductionsUponRedemption() {
        let habit = Habit(title: "Drink Water", xpReward: 15)
        let completion = HabitCompletion(date: fixedDate, habit: habit, xpAwarded: 15)
        habit.completions = [completion]

        let tasks = [
            TaskItem(
                title: "Do Tax",
                priority: .high,
                completedAt: fixedDate,
                xpReward: 20,
                xpAwarded: 20
            )
        ]
        let rewards = [
            Reward(title: "Play Games", xpCost: 30, redeemedAt: fixedDate)
        ]

        let snapshot = ProgressService.snapshot(
            habits: [habit],
            tasks: tasks,
            transactions: [],
            rewards: rewards,
            on: fixedDate,
            calendar: fixedCalendar
        )

        XCTAssertEqual(snapshot.xp, 35)
        XCTAssertEqual(snapshot.level, 1)
        XCTAssertEqual(snapshot.spentXP, 30)
        XCTAssertEqual(snapshot.currentXP, 5)
    }

    func testRedeemRejectsInsufficientBalanceWithoutMutation() {
        let reward = Reward(title: "Movie", xpCost: 50)

        XCTAssertThrowsError(
            try RewardsService.redeem(reward, availableXP: 40, on: fixedDate)
        ) { error in
            XCTAssertEqual(
                error as? RewardRedemptionError,
                .insufficientXP(required: 50, available: 40)
            )
        }
        XCTAssertNil(reward.redeemedAt)
    }

    func testRedeemRejectsAnAlreadyRedeemedReward() {
        let originalDate = Date(timeIntervalSince1970: 1_700_000_000)
        let reward = Reward(title: "Movie", xpCost: 50, redeemedAt: originalDate)

        XCTAssertThrowsError(
            try RewardsService.redeem(reward, availableXP: 500, on: fixedDate)
        ) { error in
            XCTAssertEqual(error as? RewardRedemptionError, .alreadyRedeemed)
        }
        XCTAssertEqual(reward.redeemedAt, originalDate)
    }

    func testRedeemStoresTheProvidedDateWhenAffordable() throws {
        let reward = Reward(title: "Movie", xpCost: 50)

        let redeemedAt = try RewardsService.redeem(
            reward,
            availableXP: 50,
            on: fixedDate
        )

        XCTAssertEqual(redeemedAt, fixedDate)
        XCTAssertEqual(reward.redeemedAt, fixedDate)
    }

    private var fixedCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
