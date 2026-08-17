import Foundation
import WidgetKit

struct WidgetSnapshot: Codable {
    let vibeScore: Int
    let level: Int
    let xp: Int
    let completedHabits: Int
    let totalHabits: Int
    let pendingTasks: Int
    let lastUpdated: Date
}

final class WidgetDataStore {
    static let shared = WidgetDataStore()
    private let key = "selfup_widget_snapshot"
    
    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: "group.com.farelevan.selfup") ?? UserDefaults.standard
    }
    
    func saveSnapshot(_ snapshot: WidgetSnapshot) {
        if let encoded = try? JSONEncoder().encode(snapshot) {
            userDefaults.set(encoded, forKey: key)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func loadSnapshot() -> WidgetSnapshot {
        if let data = userDefaults.data(forKey: key),
           let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) {
            return snapshot
        }
        // Never present demo metrics as if they were the user's live data.
        return WidgetSnapshot(
            vibeScore: 0,
            level: 1,
            xp: 0,
            completedHabits: 0,
            totalHabits: 0,
            pendingTasks: 0,
            lastUpdated: Date()
        )
    }
}
