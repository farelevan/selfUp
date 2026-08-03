import Foundation
import SwiftData

@Model final class Habit {
    var id: UUID
    var title: String
    var symbol: String
    var tintName: String
    var xpReward: Int
    var isArchived: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []
    
    init(title: String, symbol: String = "checkmark.circle.fill", tintName: String = "blue", xpReward: Int = 10, isArchived: Bool = false, createdAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.symbol = symbol
        self.tintName = tintName
        self.xpReward = xpReward
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.completions = []
    }
}
