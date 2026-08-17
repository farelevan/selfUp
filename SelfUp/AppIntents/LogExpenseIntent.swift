import AppIntents
import SwiftData
import Foundation

private enum LogExpenseIntentError: LocalizedError {
    case invalidAmount
    case emptyCategory

    var errorDescription: String? {
        switch self {
        case .invalidAmount: "Amount must be greater than zero."
        case .emptyCategory: "Category cannot be empty."
        }
    }
}

struct LogExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Expense"
    
    @Parameter(title: "Amount") var amount: Double
    @Parameter(title: "Category") var category: String
    @Parameter(title: "Note") var note: String?
    
    @MainActor
    func perform() async throws -> some IntentResult {
        guard amount.isFinite, amount > 0 else {
            throw LogExpenseIntentError.invalidAmount
        }
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else {
            throw LogExpenseIntentError.emptyCategory
        }

        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
            Transaction.self,
            TaskItem.self,
            Reward.self,
            SavingGoal.self
        ])
        let container = try ModelContainer(for: schema)
        let context = container.mainContext
        
        let tx = Transaction(
            amount: Decimal(amount),
            type: .expense,
            category: trimmedCategory,
            note: note ?? "",
            date: Date()
        )
        context.insert(tx)
        try context.save()

        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        _ = await NotificationManager.reconcileFunBudget(
            transactions: transactions,
            currencySymbol: UserDefaults.standard.string(forKey: "selected_currency") ?? "Rp",
            now: Date(),
            calendar: .autoupdatingCurrent
        )
        
        return .result()
    }
}
