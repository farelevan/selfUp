import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var title: String
    var symbol: String
    var xpReward: Int
    var isArchived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]

    init(title: String, symbol: String = "checkmark.circle.fill", xpReward: Int = 10) {
        self.id = UUID()
        self.title = title
        self.symbol = symbol
        self.xpReward = xpReward
        self.isArchived = false
        self.createdAt = .now
        self.completions = []
    }
}

@Model
final class HabitCompletion {
    var id: UUID
    var date: Date
    var habit: Habit?

    init(date: Date = .now, habit: Habit? = nil) {
        self.id = UUID()
        self.date = date
        self.habit = habit
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income, expense
}

@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var typeRaw: String
    var category: String
    var note: String
    var date: Date

    var type: TransactionType { TransactionType(rawValue: typeRaw) ?? .expense }

    init(amount: Decimal, type: TransactionType, category: String, note: String = "", date: Date = .now) {
        self.id = UUID()
        self.amount = amount
        self.typeRaw = type.rawValue
        self.category = category
        self.note = note
        self.date = date
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low, medium, high
}

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var dueDate: Date?
    var priorityRaw: String
    var completedAt: Date?
    var xpReward: Int

    var priority: TaskPriority { TaskPriority(rawValue: priorityRaw) ?? .medium }

    init(title: String, dueDate: Date? = nil, priority: TaskPriority = .medium, xpReward: Int = 15) {
        self.id = UUID()
        self.title = title
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.xpReward = xpReward
    }
}

enum AppDestination: String, CaseIterable {
    case today, habits, money, tasks, insights
}
