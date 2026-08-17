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
    }
}
