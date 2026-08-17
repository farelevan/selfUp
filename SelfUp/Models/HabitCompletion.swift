import Foundation
import SwiftData

@Model final class HabitCompletion {
    var id: UUID
    var date: Date
    // Optional so records created before XP snapshots were introduced continue
    // to load. ProgressService falls back to the habit's configured reward.
    var xpAwarded: Int?
    var habit: Habit?
    
    init(id: UUID = UUID(), date: Date, habit: Habit? = nil, xpAwarded: Int? = nil) {
        self.id = id
        self.date = date
        self.xpAwarded = xpAwarded
        self.habit = habit
    }
}
