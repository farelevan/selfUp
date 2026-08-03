import AppIntents

struct SelfUpShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Track spending in \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "creditcard"
        )
        
        AppShortcut(
            intent: CompleteHabitIntent(),
            phrases: [
                "Complete habit in \(.applicationName)",
                "Check off habit in \(.applicationName)"
            ],
            shortTitle: "Complete Habit",
            systemImageName: "checkmark.circle"
        )
        
        AppShortcut(
            intent: OpenSectionIntent(),
            phrases: [
                "Open section in \(.applicationName)",
                "Show tab in \(.applicationName)"
            ],
            shortTitle: "Open Section",
            systemImageName: "sidebar.left"
        )
    }
}
