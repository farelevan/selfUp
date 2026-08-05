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
        // Fallback default sample entry
        return WidgetSnapshot(
            vibeScore: 85,
            level: 1,
            xp: 250,
            completedHabits: 3,
            totalHabits: 4,
            pendingTasks: 2,
            lastUpdated: Date()
        )
    }
}
