import SwiftUI
import SwiftData

struct HabitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var habitToEdit: Habit?
    
    @State private var title: String = ""
    @State private var selectedSymbol: String = "checkmark.circle.fill"
    @State private var selectedTint: String = "blue"
    @State private var xpReward: Int = 10
    
    let symbols = ["checkmark.circle.fill", "flame.fill", "heart.fill", "star.fill", "book.fill", "drop.fill", "bolt.fill"]
    let tints = ["blue", "green", "orange", "purple", "red", "teal", "indigo"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                        .accessibilityIdentifier("habit_title_field")
                    
                    Stepper("XP Reward: \(xpReward)", value: $xpReward, in: 5...50, step: 5)
                }
                
                Section(header: Text("Icon")) {
                    Picker("Symbol", selection: $selectedSymbol) {
                        ForEach(symbols, id: \.self) { symbol in
                            Label(symbol, systemImage: symbol).tag(symbol)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Tint Color")) {
                    Picker("Color", selection: $selectedTint) {
                        ForEach(tints, id: \.self) { tint in
                            Text(tint.capitalized).tag(tint)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle(habitToEdit == nil ? "New Habit" : "Edit Habit")
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let habit = habitToEdit {
                    title = habit.title
                    selectedSymbol = habit.symbol
                    selectedTint = habit.tintName
                    xpReward = habit.xpReward
                }
            }
        }
    }
    
    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let habit = habitToEdit {
            habit.title = trimmed
            habit.symbol = selectedSymbol
            habit.tintName = selectedTint
            habit.xpReward = xpReward
        } else {
            let newHabit = Habit(title: trimmed, symbol: selectedSymbol, tintName: selectedTint, xpReward: xpReward)
            modelContext.insert(newHabit)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save habit: \(error)")
        }
    }
}
