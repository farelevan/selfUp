import SwiftUI
import SwiftData

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var taskToEdit: TaskItem?
    var defaultPeriod: TaskPeriod = .inbox
    
    @State private var title: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var priority: TaskPriority = .medium
    @State private var xpReward: Int = 10
    @State private var period: TaskPeriod = .inbox
    @State private var workflowStatus: TaskWorkflowStatus = .planned
    @State private var recurrence: TaskRecurrence = .none
    @State private var hasReminder = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
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

                Section(
                    header: Text("Plan"),
                    footer: Text("Period is when you intend to work on it. Due date remains the hard deadline.")
                ) {
                    Picker("Period", selection: $period) {
                        ForEach(TaskPeriod.allCases) { period in
                            Label(period.title, systemImage: period.symbol).tag(period)
                        }
                    }

                    Picker("Status", selection: $workflowStatus) {
                        ForEach(TaskWorkflowStatus.allCases) { status in
                            Label(status.title, systemImage: status.symbol).tag(status)
                        }
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Repeat & Reminder") {
                    Picker("Repeat", selection: $recurrence) {
                        ForEach(TaskRecurrence.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    Toggle("Due-day reminder", isOn: $hasReminder)
                        .disabled(!hasDueDate)
                    if hasDueDate && hasReminder {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
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
                    period = task.effectivePeriod
                    workflowStatus = task.effectiveStatus
                    recurrence = task.effectiveRecurrence
                    if let hour = task.reminderHour, let minute = task.reminderMinute {
                        hasReminder = true
                        reminderTime = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? reminderTime
                    }
                } else {
                    period = defaultPeriod
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
            task.period = period
            task.recurrence = recurrence
            applyReminder(to: task)
            task.move(to: workflowStatus)
            NotificationManager.scheduleTask(task)
        } else {
            let newTask = TaskItem(
                title: trimmed,
                dueDate: targetDueDate,
                priority: priority,
                xpReward: xpReward,
                period: period,
                workflowStatus: workflowStatus,
                recurrence: recurrence
            )
            applyReminder(to: newTask)
            newTask.move(to: workflowStatus)
            modelContext.insert(newTask)
            NotificationManager.scheduleTask(newTask)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save task: \(error)")
        }
    }

    private func applyReminder(to task: TaskItem) {
        guard hasDueDate && hasReminder else {
            task.reminderHour = nil
            task.reminderMinute = nil
            return
        }
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        task.reminderHour = components.hour
        task.reminderMinute = components.minute
        Task { _ = await NotificationManager.requestAuthorization() }
    }
}
