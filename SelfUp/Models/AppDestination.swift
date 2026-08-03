import Foundation
import AppIntents
import Observation

enum AppDestination: String, CaseIterable, AppEnum {
    case today
    case habits
    case money
    case tasks
    case rewards
    case insights
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "App Section")
    }
    
    static var caseDisplayRepresentations: [AppDestination: DisplayRepresentation] {
        [
            .today: DisplayRepresentation(title: "Today"),
            .habits: DisplayRepresentation(title: "Habits"),
            .money: DisplayRepresentation(title: "Money"),
            .tasks: DisplayRepresentation(title: "Tasks"),
            .rewards: DisplayRepresentation(title: "Rewards"),
            .insights: DisplayRepresentation(title: "Insights")
        ]
    }
}

@Observable
final class AppRouter {
    static let shared = AppRouter()
    
    var destination: AppDestination = .today
    
    func navigate(to target: AppDestination) {
        destination = target
    }
}
