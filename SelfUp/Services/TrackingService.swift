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
            let completion = HabitCompletion(
                date: targetDate,
                habit: habit,
                xpAwarded: max(0, habit.xpReward)
            )
            context.insert(completion)
            habit.completions.append(completion)
            return true
        }
    }

    /// Explicit undo keeps completion intents idempotent while giving interactive
    /// UI a safe way to revoke an accidental completion and its XP snapshot.
    func undoHabitCompletion(_ habit: Habit, on date: Date, context: ModelContext) throws -> Bool {
        let calendar = Calendar.current
        guard let completion = habit.completions.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) else {
            return false
        }

        habit.completions.removeAll { $0.id == completion.id }
        context.delete(completion)
        return true
    }
    
    func toggleTask(_ task: TaskItem, on date: Date, context: ModelContext) throws -> Bool {
        if task.completedAt != nil {
            return false
        } else {
            task.move(to: .completed, on: date)
            return true
        }
    }

    func undoTaskCompletion(_ task: TaskItem) -> Bool {
        guard task.completedAt != nil else { return false }
        task.move(to: .planned)
        return true
    }
}
