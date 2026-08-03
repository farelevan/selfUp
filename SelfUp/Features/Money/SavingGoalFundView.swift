import SwiftUI
import SwiftData

struct SavingGoalFundView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let goal: SavingGoal
    
    @State private var amountString = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Add Funds to \(goal.title)") {
                    TextField("Amount", text: $amountString)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addFunds()
                    }
                    .disabled(Decimal(string: amountString) == nil)
                }
            }
        }
    }
    
    private func addFunds() {
        guard let amount = Decimal(string: amountString) else { return }
        goal.currentAmount += amount
        
        // Log transaction to sync net balances
        let tx = Transaction(
            amount: amount,
            type: .expense,
            category: "Savings",
            note: "Allocated to \(goal.title)",
            date: Date()
        )
        modelContext.insert(tx)
        
        try? modelContext.save()
        dismiss()
    }
}
