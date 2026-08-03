import XCTest
@testable import SelfUp

final class RewardsServiceTests: XCTestCase {
    func testXpBalanceDeductionsUponRedemption() {
        // Arrange
        let habit = Habit(title: "Drink Water", xpReward: 15)
        let completion = HabitCompletion(date: Date())
        completion.habit = habit
        habit.completions = [completion]
        
        let habits = [habit]
        
        let tasks = [
            TaskItem(title: "Do Tax", priority: .high, completedAt: Date(), xpReward: 20)
        ]
        let transactions: [Transaction] = []
        
        let rewards = [
            Reward(title: "Play Games", xpCost: 30, redeemedAt: Date())
        ]
        
        // Act
        let snapshot = ProgressService.snapshot(
            habits: habits,
            tasks: tasks,
            transactions: transactions,
            rewards: rewards,
            on: Date()
        )
        
        // Assert
        XCTAssertEqual(snapshot.xp, 35, "Lifetime XP should be 35")
        XCTAssertEqual(snapshot.level, 1, "Level should be 1 based on lifetime XP")
        XCTAssertEqual(snapshot.spentXP, 30, "Spent XP should be 30")
        XCTAssertEqual(snapshot.currentXP, 5, "Available balance should be 5")
    }
}
