import SwiftUI
import SwiftData

struct RewardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var rewardToEdit: Reward?
    
    @State private var title = ""
    @State private var xpCost = 50
    
    private var isNew: Bool { rewardToEdit == nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reward Details") {
                    TextField("Title (e.g. Buy bubble tea)", text: $title)
                    
                    Stepper(value: $xpCost, in: 10...5000, step: 10) {
                        HStack {
                            Text("XP Cost")
                            Spacer()
                            Text("\(xpCost) XP")
                                .bold()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New Reward" : "Edit Reward")
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let reward = rewardToEdit {
                    title = reward.title
                    xpCost = reward.xpCost
                }
            }
        }
    }
    
    private func save() {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let reward = rewardToEdit {
            reward.title = cleanedTitle
            reward.xpCost = xpCost
        } else {
            let newReward = Reward(title: cleanedTitle, xpCost: xpCost)
            modelContext.insert(newReward)
        }
        try? modelContext.save()
        dismiss()
    }
}
