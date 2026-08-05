import SwiftUI
import SwiftData

@main
struct SelfUpApp: App {
    @State private var router = AppRouter.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
            Transaction.self,
            TaskItem.self,
            Reward.self,
            SavingGoal.self
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
            SplashScreenView {
                ContentView(router: router)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    @Bindable var router: AppRouter
    
    var body: some View {
        TabView(selection: $router.destination) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(AppDestination.today)
            
            HabitsView()
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle")
                }
                .tag(AppDestination.habits)
            
            MoneyView()
                .tabItem {
                    Label("Money", systemImage: "creditcard")
                }
                .tag(AppDestination.money)
            
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(AppDestination.tasks)
            
            RewardsView()
                .tabItem {
                    Label("Rewards", systemImage: "gift")
                }
                .tag(AppDestination.rewards)
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
                .tag(AppDestination.insights)
        }
    }
}
