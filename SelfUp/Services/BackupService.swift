import Foundation

struct HabitCompletionBackup: Codable {
    let id: UUID
    let date: Date
    let xpAwarded: Int?
}

struct HabitBackup: Codable {
    let id: UUID
    let title: String
    let symbol: String
    let tintName: String
    let xpReward: Int
    let isArchived: Bool
    let createdAt: Date
    let completions: [Date]
    let completionAwards: [HabitCompletionBackup]?
    let scheduledWeekdays: Int?
    let reminderHour: Int?
    let reminderMinute: Int?
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
    let xpAwarded: Int?
    let period: String?
    let workflowStatus: String?
    let startedAt: Date?
    let recurrence: String?
    let reminderHour: Int?
    let reminderMinute: Int?
}

struct RewardBackup: Codable {
    let id: UUID
    let title: String
    let xpCost: Int
    let redeemedAt: Date?
}

struct BackupPayload: Codable {
    let habits: [HabitBackup]
    let transactions: [TransactionBackup]
    let tasks: [TaskBackup]
    let rewards: [RewardBackup]?
}

enum ValidationErrorBackup: Error, LocalizedError {
    case invalidTitle(String)
    case invalidCategory(String)
    case invalidAmount(Decimal)
    case invalidXP(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidTitle(let name): return "Title cannot be blank (found in \(name))."
        case .invalidCategory(let name): return "Category cannot be blank (found in \(name))."
        case .invalidAmount(let amt): return "Amount must be positive (found \(amt))."
        case .invalidXP(let name): return "XP value is outside the supported range (found in \(name))."
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
            guard (0...10_000).contains(habit.xpReward),
                  habit.completionAwards?.allSatisfy({ (0...10_000).contains($0.xpAwarded ?? habit.xpReward) }) != false else {
                throw ValidationErrorBackup.invalidXP("Habit")
            }
        }
        
        for task in payload.tasks {
            if task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ValidationErrorBackup.invalidTitle("Task")
            }
            guard (0...10_000).contains(task.xpReward),
                  task.xpAwarded.map({ (0...10_000).contains($0) }) ?? true else {
                throw ValidationErrorBackup.invalidXP("Task")
            }
        }

        for reward in payload.rewards ?? [] {
            if reward.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ValidationErrorBackup.invalidTitle("Reward")
            }
            guard (1...1_000_000).contains(reward.xpCost) else {
                throw ValidationErrorBackup.invalidXP("Reward")
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
