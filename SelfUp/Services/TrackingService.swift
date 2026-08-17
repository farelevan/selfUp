import Foundation
import SwiftData

@MainActor
struct TrackingService {
    func toggleHabit(_ habit: Habit, on date: Date, context: ModelContext) throws -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        let alreadyCompleted = habit.completions.contains { completion in
            calendar.isDate(completion.date, inSameDayAs: targetDate)
        }
        
        if alreadyCompleted {
            return false
        } else {
            let completion = HabitCompletion(date: targetDate, habit: habit)
            context.insert(completion)
            habit.completions.append(completion)
            return true
        }
    }
    
    func toggleTask(_ task: TaskItem, on date: Date, context: ModelContext) throws -> Bool {
        if task.completedAt != nil {
            return false
        } else {
            task.move(to: .completed, on: date)
            return true
        }
    }
}
