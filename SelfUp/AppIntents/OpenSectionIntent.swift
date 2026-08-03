import AppIntents
import SwiftUI

struct OpenSectionIntent: AppIntent {
    static let title: LocalizedStringResource = "Open SelfUp Section"
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Section") var destination: AppDestination
    
    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.navigate(to: destination)
        return .result()
    }
}
