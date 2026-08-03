import Foundation
import AppIntents

enum AppDestination: String, CaseIterable, AppEnum {
    case today
    case habits
    case money
    case tasks
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "App Section")
    }
    
    static var caseDisplayRepresentations: [AppDestination: DisplayRepresentation] {
        [
            .today: DisplayRepresentation(title: "Today"),
            .habits: DisplayRepresentation(title: "Habits"),
            .money: DisplayRepresentation(title: "Money"),
            .tasks: DisplayRepresentation(title: "Tasks")
        ]
    }
}
