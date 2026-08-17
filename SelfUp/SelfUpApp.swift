import SwiftUI
import SwiftData
import UserNotifications

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
            RootView(router: router)
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Bindable var router: AppRouter
    @AppStorage("onboarding_completed") private var onboardingCompleted = false

    var body: some View {
        if onboardingCompleted {
            SplashScreenView { ContentView(router: router) }
        } else {
            OnboardingView { onboardingCompleted = true }
        }
    }
}

enum NotificationManager {
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    static func scheduleDailySummary(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Plan your SelfUp day"
        content.body = "Review today's habits, tasks, and one money action."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        let request = UNNotificationRequest(identifier: "selfup.daily-summary", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func scheduleHabit(_ habit: Habit) {
        let center = UNUserNotificationCenter.current()
        let prefix = "habit.\(habit.id.uuidString)."
        center.getPendingNotificationRequests { requests in
            center.removePendingNotificationRequests(withIdentifiers: requests.map(\.identifier).filter { $0.hasPrefix(prefix) })
        }
        guard let hour = habit.reminderHour, let minute = habit.reminderMinute else { return }
        let weekdays = habit.scheduledWeekdays ?? 0
        let days = weekdays == 0 ? Array(1...7) : (1...7).filter { weekdays & (1 << $0) != 0 }
        for day in days {
            let content = UNMutableNotificationContent()
            content.title = habit.title
            content.body = "A small action today keeps your momentum alive."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute, weekday: day), repeats: true)
            center.add(UNNotificationRequest(identifier: "\(prefix)\(day)", content: content, trigger: trigger))
        }
    }

    static func scheduleTask(_ task: TaskItem) {
        let identifier = "task.\(task.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        guard let due = task.dueDate, let hour = task.reminderHour, let minute = task.reminderMinute else { return }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: due)
        components.hour = hour
        components.minute = minute
        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = "This task is due today."
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)))
    }
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("profile_name") private var storedName = ""
    @AppStorage("selected_currency") private var storedCurrency = "Rp"

    let onComplete: () -> Void
    @State private var name = ""
    @State private var focus = "Balance"
    @State private var currency = "Rp"
    @State private var wantsReminder = true
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()

    private let focuses = ["Productivity", "Health", "Money", "Balance"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        SelfUpLogoView(style: .compactHeader)
                        Text("Build a system for the life you want.")
                            .font(.title2.bold())
                        Text("Set up a private, offline-first daily workspace in under a minute.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("About You") {
                    TextField("Your name", text: $name)
                    Picker("Main focus", selection: $focus) {
                        ForEach(focuses, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Currency", selection: $currency) {
                        Text("IDR (Rp)").tag("Rp")
                        Text("USD ($)").tag("$")
                        Text("EUR (€)").tag("€")
                    }
                }

                Section("Daily Rhythm") {
                    Toggle("Morning planning reminder", isOn: $wantsReminder)
                    if wantsReminder {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    Button("Start My SelfUp") { finish() }
                        .frame(maxWidth: .infinity)
                        .fontWeight(.bold)
                } footer: {
                    Text("We’ll create one starter habit and task. You can edit or delete them anytime.")
                }
            }
            .navigationTitle("Welcome")
        }
    }

    private func finish() {
        storedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        storedCurrency = currency
        let habitTitle = focus == "Health" ? "Move for 20 minutes" : "Plan tomorrow in 5 minutes"
        let habit = Habit(title: habitTitle, symbol: focus == "Health" ? "figure.walk" : "sparkles", tintName: "indigo")
        let task = TaskItem(title: "Explore your SelfUp dashboard", dueDate: Date(), priority: .medium, period: .today)
        modelContext.insert(habit)
        modelContext.insert(task)
        try? modelContext.save()

        if wantsReminder {
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            Task {
                if await NotificationManager.requestAuthorization() {
                    NotificationManager.scheduleDailySummary(hour: components.hour ?? 7, minute: components.minute ?? 0)
                }
            }
        }
        onComplete()
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
