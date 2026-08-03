import SwiftUI
import SwiftData

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var taskToEdit: TaskItem?
    
    @State private var title: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var priority: TaskPriority = .medium
    @State private var xpReward: Int = 10
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                        .accessibilityIdentifier("task_title_field")
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Stepper("XP Reward: \(xpReward)", value: $xpReward, in: 5...100, step: 5)
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(taskToEdit == nil ? "New Task" : "Edit Task")
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
                if let task = taskToEdit {
                    title = task.title
                    if let due = task.dueDate {
                        hasDueDate = true
                        dueDate = due
                    } else {
                        hasDueDate = false
                    }
                    priority = task.priority
                    xpReward = task.xpReward
                }
            }
        }
    }
    
    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let targetDueDate = hasDueDate ? dueDate : nil
        
        if let task = taskToEdit {
            task.title = trimmed
            task.dueDate = targetDueDate
            task.priority = priority
            task.xpReward = xpReward
        } else {
            let newTask = TaskItem(title: trimmed, dueDate: targetDueDate, priority: priority, xpReward: xpReward)
            modelContext.insert(newTask)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save task: \(error)")
        }
    }
}
