import Foundation
import SwiftData

enum TaskPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
}

enum TaskPeriod: String, Codable, CaseIterable, Identifiable {
    case inbox
    case today
    case thisWeek
    case later

    var id: Self { self }

    var title: String {
        switch self {
        case .inbox: return "Inbox"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .later: return "Later"
        }
    }

    var symbol: String {
        switch self {
        case .inbox: return "tray"
        case .today: return "sun.max"
        case .thisWeek: return "calendar"
        case .later: return "clock"
        }
    }
}

enum TaskWorkflowStatus: String, Codable, CaseIterable, Identifiable {
    case planned
    case inProgress
    case blocked
    case completed

    var id: Self { self }

    var title: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .blocked: return "Blocked"
        case .completed: return "Completed"
        }
    }

    var symbol: String {
        switch self {
        case .planned: return "circle"
        case .inProgress: return "play.circle.fill"
        case .blocked: return "exclamationmark.octagon.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

enum TaskRecurrence: String, Codable, CaseIterable, Identifiable {
    case none
    case daily
    case weekly
    case monthly

    var id: Self { self }
    var title: String { rawValue.capitalized }
}

@Model final class TaskItem {
    var id: UUID
    var title: String
    var dueDate: Date?
    var priority: TaskPriority
    var completedAt: Date?
    var xpReward: Int
    // Captures the configured reward when completion occurs. Nil is retained as
    // a backward-compatible marker for tasks saved by older app versions.
    var xpAwarded: Int?
    // Optional storage is intentional: records created before these fields
    // existed contain nil and must remain readable during lightweight migration.
    var period: TaskPeriod?
    var workflowStatus: TaskWorkflowStatus?
    var startedAt: Date?
    var recurrence: TaskRecurrence?
    var reminderHour: Int?
    var reminderMinute: Int?
    var recurrenceAdvancedAt: Date?

    var effectivePeriod: TaskPeriod {
        period ?? .inbox
    }

    var effectiveStatus: TaskWorkflowStatus {
        completedAt == nil ? (workflowStatus ?? .planned) : .completed
    }

    var effectiveRecurrence: TaskRecurrence { recurrence ?? .none }
    
    init(
        title: String,
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        completedAt: Date? = nil,
        xpReward: Int = 10,
        period: TaskPeriod = .inbox,
        workflowStatus: TaskWorkflowStatus = .planned,
        startedAt: Date? = nil,
        recurrence: TaskRecurrence = .none,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil,
        xpAwarded: Int? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.completedAt = completedAt
        self.xpReward = xpReward
        self.xpAwarded = completedAt == nil ? nil : (xpAwarded ?? max(0, xpReward))
        self.period = period
        self.workflowStatus = completedAt == nil ? workflowStatus : .completed
        self.startedAt = startedAt
        self.recurrence = recurrence
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.recurrenceAdvancedAt = nil
    }

    func move(to status: TaskWorkflowStatus, on date: Date = Date()) {
        workflowStatus = status

        switch status {
        case .planned:
            completedAt = nil
            xpAwarded = nil
            startedAt = nil
        case .inProgress:
            completedAt = nil
            xpAwarded = nil
            startedAt = startedAt ?? date
        case .blocked:
            completedAt = nil
            xpAwarded = nil
        case .completed:
            completedAt = completedAt ?? date
            xpAwarded = xpAwarded ?? max(0, xpReward)
        }
    }


    func nextOccurrence(after date: Date, calendar: Calendar = .current) -> Date? {
        switch effectiveRecurrence {
        case .none: return nil
        case .daily: return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly: return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly: return calendar.date(byAdding: .month, value: 1, to: date)
        }
    }
}
