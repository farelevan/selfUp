import Foundation
import SwiftData

enum TaskPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
}

@Model final class TaskItem {
    var id: UUID
    var title: String
    var dueDate: Date?
    var priority: TaskPriority
    var completedAt: Date?
    var xpReward: Int
    
    init(title: String, dueDate: Date? = nil, priority: TaskPriority = .medium, completedAt: Date? = nil, xpReward: Int = 10) {
        self.id = UUID()
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.completedAt = completedAt
        self.xpReward = xpReward
    }
}
