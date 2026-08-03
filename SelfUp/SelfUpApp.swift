import SwiftUI
import SwiftData

@main
struct SelfUpApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
            Transaction.self,
            TaskItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    var body: some View {
        Text("SelfUp App Running")
    }
}
