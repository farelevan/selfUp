import SwiftUI
import SwiftData
import UserNotifications
import UIKit

final class SelfUpNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard response.notification.request.identifier.hasPrefix(NotificationManager.funBudgetIdentifierPrefix) else {
            completionHandler()
            return
        }

        Task { @MainActor in
            AppRouter.shared.navigate(to: .money)
            completionHandler()
        }
    }
}

@main
struct SelfUpApp: App {
    @UIApplicationDelegateAdaptor(SelfUpNotificationDelegate.self) private var notificationDelegate
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
                .overlay {
                    FunBudgetLifecycleMonitor()
                        .frame(width: 0, height: 0)
                        .allowsHitTesting(false)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct FunBudgetLifecycleMonitor: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @AppStorage("selected_currency") private var currencySymbol = "Rp"

    private var transactionSignature: String {
        transactions.map { transaction in
            [
                transaction.id.uuidString,
                NSDecimalNumber(decimal: transaction.amount).stringValue,
                transaction.type.rawValue,
                transaction.category,
                String(transaction.date.timeIntervalSinceReferenceDate)
            ].joined(separator: "|")
        }.joined(separator: ";")
    }

    var body: some View {
        Color.clear
            .task { await reconcile() }
            .onChange(of: transactionSignature) { _, _ in
                Task { await reconcile() }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task { await reconcile() }
            }
            .onChange(of: currencySymbol) { _, _ in
                Task { await reconcile() }
            }
    }

    private func reconcile() async {
        _ = await NotificationManager.reconcileFunBudget(
            transactions: transactions,
            currencySymbol: currencySymbol,
            now: Date(),
            calendar: .autoupdatingCurrent
        )
    }
}

struct RootView: View {
    @Bindable var router: AppRouter
    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    @AppStorage("has_seen_launch_splash") private var hasSeenLaunchSplash = false

    var body: some View {
        if onboardingCompleted {
            if hasSeenLaunchSplash {
                ContentView(router: router)
            } else {
                SplashScreenView {
                    ContentView(router: router)
                        .onAppear { hasSeenLaunchSplash = true }
                }
            }
        } else {
            OnboardingView { onboardingCompleted = true }
        }
    }
}

enum FunBudgetAuthorizationResult: Equatable {
    case authorized
    case denied
    case failed(String)
}

enum FunBudgetNotificationResult: Equatable {
    case unchanged
    case scheduled
    case notified
    case cancelled
    case notificationsDisabled
    case notAuthorized
    case failed(String)
}

enum NotificationManager {
    static let funBudgetIdentifierPrefix = "selfup.fun-budget."
    @MainActor private static var funBudgetReconcileActive = false
    @MainActor private static var funBudgetReconcileWaiters: [CheckedContinuation<Void, Never>] = []

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    static func requestFunBudgetAuthorization() async -> FunBudgetAuthorizationResult {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                return granted ? .authorized : .denied
            } catch {
                return .failed(error.localizedDescription)
            }
        @unknown default:
            return .denied
        }
    }

    @MainActor
    static func reconcileFunBudget(
        transactions: [Transaction],
        currencySymbol: String,
        now: Date,
        calendar: Calendar,
        defaults: UserDefaults = .standard
    ) async -> FunBudgetNotificationResult {
        await acquireFunBudgetReconcile()
        defer { releaseFunBudgetReconcile() }

        let store = FunBudgetStore(defaults: defaults)
        let snapshot = FunBudgetService.snapshot(
            for: transactions,
            limit: store.limit,
            now: now,
            calendar: calendar
        )
        let center = UNUserNotificationCenter.current()
        let identifier = funBudgetIdentifier(for: snapshot.periodKey)
        let pendingRequests = await center.pendingNotificationRequests()
        let staleIdentifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(funBudgetIdentifierPrefix) && $0 != identifier }
        if !staleIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
        }

        if store.scheduledPeriod != nil, store.scheduledPeriod != snapshot.periodKey {
            store.clearScheduled()
        }

        if store.scheduledPeriod == snapshot.periodKey,
           let scheduledDate = store.scheduledDate,
           now >= scheduledDate {
            // Delivery has no reliable background callback. Once its trigger has
            // passed, consume the period so clearing Notification Center cannot
            // cause another warning in the same month.
            store.recordNotified(period: snapshot.periodKey)
        }

        let hasPendingRequest = pendingRequests.contains { $0.identifier == identifier }

        guard store.notificationsEnabled else {
            if hasPendingRequest {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
            if store.scheduledPeriod == snapshot.periodKey {
                store.clearScheduled()
            }
            return hasPendingRequest ? .cancelled : .notificationsDisabled
        }

        if store.notifiedPeriod == snapshot.periodKey {
            if hasPendingRequest {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
            return .unchanged
        }

        guard snapshot.isConfigured else {
            if hasPendingRequest {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
            if store.scheduledPeriod == snapshot.periodKey {
                store.clearScheduled()
            }
            return hasPendingRequest ? .cancelled : .unchanged
        }

        let settings = await center.notificationSettings()
        guard isAuthorized(settings.authorizationStatus) else {
            if hasPendingRequest {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
            if store.scheduledPeriod == snapshot.periodKey {
                store.clearScheduled()
            }
            return .notAuthorized
        }

        guard snapshot.warningAction != .none else {
            if hasPendingRequest {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
            if store.scheduledPeriod == snapshot.periodKey {
                store.clearScheduled()
            }
            return hasPendingRequest ? .cancelled : .unchanged
        }

        let content = funBudgetContent(for: snapshot, currencySymbol: currencySymbol)
        let contentFingerprint = funBudgetContentFingerprint(
            for: snapshot,
            currencySymbol: currencySymbol
        )

        switch snapshot.warningAction {
        case .none:
            return .unchanged

        case .schedule(let date):
            if store.scheduledPeriod == snapshot.periodKey,
               let storedDate = store.scheduledDate,
               abs(storedDate.timeIntervalSince(date)) < 1,
               store.scheduledFingerprint == contentFingerprint,
               hasPendingRequest {
                return .unchanged
            }
            if hasPendingRequest {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
            store.clearScheduled()

            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            components.timeZone = calendar.timeZone
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
                store.recordScheduled(
                    period: snapshot.periodKey,
                    date: date,
                    fingerprint: contentFingerprint
                )
                return .scheduled
            } catch {
                return .failed(error.localizedDescription)
            }

        case .notifyNow:
            if hasPendingRequest {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
            store.clearScheduled()
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

            do {
                try await center.add(request)
                store.recordNotified(period: snapshot.periodKey)
                return .notified
            } catch {
                return .failed(error.localizedDescription)
            }
        }
    }

    @MainActor
    private static func acquireFunBudgetReconcile() async {
        guard funBudgetReconcileActive else {
            funBudgetReconcileActive = true
            return
        }

        await withCheckedContinuation { continuation in
            funBudgetReconcileWaiters.append(continuation)
        }
    }

    @MainActor
    private static func releaseFunBudgetReconcile() {
        guard !funBudgetReconcileWaiters.isEmpty else {
            funBudgetReconcileActive = false
            return
        }

        let next = funBudgetReconcileWaiters.removeFirst()
        next.resume()
    }

    static func funBudgetIdentifier(for periodKey: String) -> String {
        funBudgetIdentifierPrefix + periodKey
    }

    private static func isAuthorized(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func funBudgetContent(
        for snapshot: FunBudgetSnapshot,
        currencySymbol: String
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let spent = "\(currencySymbol) \(NSDecimalNumber(decimal: snapshot.spent).stringValue)"
        let limit = "\(currencySymbol) \(NSDecimalNumber(decimal: snapshot.limit).stringValue)"

        if snapshot.attention == .depleted {
            content.title = "Fun budget depleted"
            if snapshot.overage > 0 {
                let overage = "\(currencySymbol) \(NSDecimalNumber(decimal: snapshot.overage).stringValue)"
                content.body = "Entertainment spending is \(overage) over your \(limit) monthly budget."
            } else {
                content.body = "You've used all of your \(limit) Entertainment budget this month."
            }
        } else {
            content.title = "Fun budget nearly depleted"
            content.body = "You've spent \(spent) of your \(limit) Entertainment budget this month."
        }

        content.sound = .default
        content.threadIdentifier = "selfup.fun-budget"
        content.userInfo = ["destination": "money", "period": snapshot.periodKey]
        return content
    }

    private static func funBudgetContentFingerprint(
        for snapshot: FunBudgetSnapshot,
        currencySymbol: String
    ) -> String {
        let attention: String
        switch snapshot.attention {
        case .unconfigured: attention = "unconfigured"
        case .onTrack: attention = "on-track"
        case .nearlyDepleted: attention = "nearly-depleted"
        case .depleted: attention = "depleted"
        }

        return [
            snapshot.periodKey,
            currencySymbol,
            NSDecimalNumber(decimal: snapshot.spent).stringValue,
            NSDecimalNumber(decimal: snapshot.limit).stringValue,
            NSDecimalNumber(decimal: snapshot.overage).stringValue,
            attention
        ].joined(separator: "|")
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
                        Text("GBP (£)").tag("£")
                        Text("JPY (¥)").tag("¥")
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
            
            RewardsView(router: router)
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppDestination.rewards)
        }
        .tint(SelfUpStyle.brand)
    }
}
