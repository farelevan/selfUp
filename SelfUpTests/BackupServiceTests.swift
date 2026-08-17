import XCTest
@testable import SelfUp

final class BackupServiceTests: XCTestCase {
    func testImportRejectsPayloadWithTransactionMissingCategory() throws {
        let invalidPayload: [String: Any] = [
            "habits": [],
            "transactions": [
                [
                    "id": UUID().uuidString,
                    "amount": 100.0,
                    "type": "expense",
                    "category": "",
                    "note": "Invalid tx",
                    "date": Date().timeIntervalSince1970
                ]
            ],
            "tasks": []
        ]
        
        let data = try JSONSerialization.data(withJSONObject: invalidPayload)
        XCTAssertThrowsError(try BackupService.validateImport(data))
    }
    
    func testImportRejectsPayloadWithNegativeAmount() throws {
        let invalidPayload: [String: Any] = [
            "habits": [],
            "transactions": [
                [
                    "id": UUID().uuidString,
                    "amount": -50.0,
                    "type": "expense",
                    "category": "Food",
                    "note": "Invalid tx",
                    "date": Date().timeIntervalSince1970
                ]
            ],
            "tasks": []
        ]
        
        let data = try JSONSerialization.data(withJSONObject: invalidPayload)
        XCTAssertThrowsError(try BackupService.validateImport(data))
    }

    func testLegacyTaskBackupWithoutWorkflowFieldsStillDecodes() throws {
        let payload: [String: Any] = [
            "habits": [],
            "transactions": [],
            "tasks": [[
                "id": UUID().uuidString,
                "title": "Legacy task",
                "priority": "medium",
                "xpReward": 10
            ]]
        ]

        let data = try JSONSerialization.data(withJSONObject: payload)
        let decoded = try BackupService.validateImport(data)

        XCTAssertEqual(decoded.tasks.first?.title, "Legacy task")
        XCTAssertNil(decoded.tasks.first?.period)
        XCTAssertNil(decoded.tasks.first?.workflowStatus)
        XCTAssertNil(decoded.rewards, "A missing legacy rewards field must remain distinguishable from an empty rewards list")
    }

    func testBackupRoundTripPreservesAwardSnapshotsAndRewards() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let completion = HabitCompletionBackup(id: UUID(), date: date, xpAwarded: 15)
        let payload = BackupPayload(
            habits: [HabitBackup(
                id: UUID(),
                title: "Read",
                symbol: "book.fill",
                tintName: "blue",
                xpReward: 25,
                isArchived: false,
                createdAt: date,
                completions: [date],
                completionAwards: [completion],
                scheduledWeekdays: 0,
                reminderHour: nil,
                reminderMinute: nil
            )],
            transactions: [],
            tasks: [TaskBackup(
                id: UUID(),
                title: "Plan",
                dueDate: date,
                priority: "medium",
                completedAt: date,
                xpReward: 30,
                xpAwarded: 20,
                period: "today",
                workflowStatus: "completed",
                startedAt: nil,
                recurrence: "none",
                reminderHour: nil,
                reminderMinute: nil
            )],
            rewards: [RewardBackup(
                id: UUID(),
                title: "Movie",
                xpCost: 25,
                redeemedAt: date
            )]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let decoded = try BackupService.validateImport(encoder.encode(payload))

        XCTAssertEqual(decoded.habits.first?.completionAwards?.first?.xpAwarded, 15)
        XCTAssertEqual(decoded.tasks.first?.xpAwarded, 20)
        XCTAssertEqual(decoded.rewards?.first?.xpCost, 25)
        XCTAssertEqual(decoded.rewards?.first?.redeemedAt, date)
    }
}
