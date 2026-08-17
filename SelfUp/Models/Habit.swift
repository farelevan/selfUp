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
    // Nil keeps records created by older versions valid. Bit 1...7 maps to
    // Calendar weekday (Sunday...Saturday); 0 means every day.
    var scheduledWeekdays: Int?
    var reminderHour: Int?
    var reminderMinute: Int?
    
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []
    
    init(title: String, symbol: String = "checkmark.circle.fill", tintName: String = "blue", xpReward: Int = 10, isArchived: Bool = false, createdAt: Date = Date(), scheduledWeekdays: Int = 0, reminderHour: Int? = nil, reminderMinute: Int? = nil) {
        self.id = UUID()
        self.title = title
        self.symbol = symbol
        self.tintName = tintName
        self.xpReward = xpReward
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.scheduledWeekdays = scheduledWeekdays
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.completions = []
    }

    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        let mask = scheduledWeekdays ?? 0
        guard mask != 0 else { return true }
        return mask & (1 << calendar.component(.weekday, from: date)) != 0
    }
}
