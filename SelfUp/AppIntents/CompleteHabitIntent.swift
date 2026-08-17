import AppIntents
import SwiftData
import Foundation

struct HabitEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Habit")
    }
    
    static var defaultQuery = HabitEntityQuery()
    
    let id: UUID
    let title: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
    
    init(id: UUID, title: String) {
        self.id = id
        self.title = title
    }
}

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        let context = try await getContext()
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { identifiers.contains($0.id) })
        let habits = try context.fetch(descriptor)
        return habits.map { HabitEntity(id: $0.id, title: $0.title) }
    }
    
    func suggestedEntities() async throws -> [HabitEntity] {
        let context = try await getContext()
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { !$0.isArchived })
        let habits = try context.fetch(descriptor)
        return habits.map { HabitEntity(id: $0.id, title: $0.title) }
    }
    
    @MainActor
    private func getContext() throws -> ModelContext {
        let schema = Schema([Habit.self, HabitCompletion.self, Transaction.self, TaskItem.self, Reward.self, SavingGoal.self])
        let container = try ModelContainer(for: schema)
        return container.mainContext
    }
}

struct CompleteHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete Habit"
    
    @Parameter(title: "Habit") var habit: HabitEntity
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let schema = Schema([Habit.self, HabitCompletion.self, Transaction.self, TaskItem.self, Reward.self, SavingGoal.self])
        let container = try ModelContainer(for: schema)
        let context = container.mainContext
        
        let habitId = habit.id
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == habitId })
        if let matchingHabit = try context.fetch(descriptor).first {
            let service = TrackingService()
            _ = try service.toggleHabit(matchingHabit, on: Date(), context: context)
            try context.save()
        }
        return .result()
    }
}
