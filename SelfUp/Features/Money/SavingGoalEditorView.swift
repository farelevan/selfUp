import SwiftUI
import SwiftData

struct SavingGoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var goalToEdit: SavingGoal?
    
    @State private var title = ""
    @State private var targetAmountString = ""
    @State private var currentAmountString = "0"
    
    private var isNew: Bool { goalToEdit == nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Title (e.g. New Laptop)", text: $title)
                    
                    TextField("Target Amount", text: $targetAmountString)
                        .keyboardType(.decimalPad)
                    
                    if isNew {
                        TextField("Starting Amount", text: $currentAmountString)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle(isNew ? "New Saving Goal" : "Edit Saving Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        Decimal(string: targetAmountString) == nil
                    )
                }
            }
            .onAppear {
                if let goal = goalToEdit {
                    title = goal.title
                    targetAmountString = "\(goal.targetAmount)"
                    currentAmountString = "\(goal.currentAmount)"
                }
            }
        }
    }
    
    private func save() {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let target = Decimal(string: targetAmountString) else { return }
        let current = Decimal(string: currentAmountString) ?? 0.0
        
        if let goal = goalToEdit {
            goal.title = cleanedTitle
            goal.targetAmount = target
        } else {
            let newGoal = SavingGoal(title: cleanedTitle, targetAmount: target, currentAmount: current)
            modelContext.insert(newGoal)
        }
        try? modelContext.save()
        dismiss()
    }
}
