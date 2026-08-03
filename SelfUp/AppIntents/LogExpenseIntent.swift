import AppIntents
import SwiftData
import Foundation

struct LogExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Expense"
    
    @Parameter(title: "Amount") var amount: Double
    @Parameter(title: "Category") var category: String
    @Parameter(title: "Note") var note: String?
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let schema = Schema([Habit.self, HabitCompletion.self, Transaction.self, TaskItem.self])
        let container = try ModelContainer(for: schema)
        let context = container.mainContext
        
        let tx = Transaction(amount: Decimal(amount), type: .expense, category: category, note: note ?? "", date: Date())
        context.insert(tx)
        try context.save()
        
        return .result()
    }
}
