import Foundation

struct HabitBackup: Codable {
    let id: UUID
    let title: String
    let symbol: String
    let tintName: String
    let xpReward: Int
    let isArchived: Bool
    let createdAt: Date
    let completions: [Date]
}

struct TransactionBackup: Codable {
    let id: UUID
    let amount: Decimal
    let type: String
    let category: String
    let note: String
    let date: Date
}

struct TaskBackup: Codable {
    let id: UUID
    let title: String
    let dueDate: Date?
    let priority: String
    let completedAt: Date?
    let xpReward: Int
}

struct BackupPayload: Codable {
    let habits: [HabitBackup]
    let transactions: [TransactionBackup]
    let tasks: [TaskBackup]
}

enum ValidationErrorBackup: Error, LocalizedError {
    case invalidTitle(String)
    case invalidCategory(String)
    case invalidAmount(Decimal)
    
    var errorDescription: String? {
        switch self {
        case .invalidTitle(let name): return "Title cannot be blank (found in \(name))."
        case .invalidCategory(let name): return "Category cannot be blank (found in \(name))."
        case .invalidAmount(let amt): return "Amount must be positive (found \(amt))."
        }
    }
}

enum BackupService {
    static func validateImport(_ data: Data) throws -> BackupPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        let payload = try decoder.decode(BackupPayload.self, from: data)
        
        for habit in payload.habits {
            if habit.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ValidationErrorBackup.invalidTitle("Habit")
            }
        }
        
        for task in payload.tasks {
            if task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ValidationErrorBackup.invalidTitle("Task")
            }
        }
        
        for tx in payload.transactions {
            if tx.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ValidationErrorBackup.invalidCategory("Transaction")
            }
            if tx.amount <= 0 {
                throw ValidationErrorBackup.invalidAmount(tx.amount)
            }
        }
        
        return payload
    }
}
