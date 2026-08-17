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
    @State private var scheduledWeekdays: Int = 0
    @State private var hasReminder = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    
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

                Section(header: Text("Schedule"), footer: Text(scheduledWeekdays == 0 ? "Every day" : "Only selected days count toward your daily score.")) {
                    HStack {
                        ForEach(Array(zip([1, 2, 3, 4, 5, 6, 7], ["S", "M", "T", "W", "T", "F", "S"])), id: \.0) { day, label in
                            Button {
                                let bit = 1 << day
                                scheduledWeekdays = scheduledWeekdays & bit == 0 ? scheduledWeekdays | bit : scheduledWeekdays & ~bit
                            } label: {
                                Text(label)
                                    .font(.caption.bold())
                                    .frame(width: 28, height: 28)
                                    .foregroundStyle(scheduledWeekdays == 0 || scheduledWeekdays & (1 << day) != 0 ? .white : .primary)
                                    .background(Circle().fill(scheduledWeekdays == 0 || scheduledWeekdays & (1 << day) != 0 ? SelfUpStyle.primaryIndigo : Color.secondary.opacity(0.16)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Reminder") {
                    Toggle("Remind me", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
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
                    scheduledWeekdays = habit.scheduledWeekdays ?? 0
                    if let hour = habit.reminderHour, let minute = habit.reminderMinute {
                        hasReminder = true
                        reminderTime = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? reminderTime
                    }
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
            habit.scheduledWeekdays = scheduledWeekdays
            applyReminder(to: habit)
            NotificationManager.scheduleHabit(habit)
        } else {
            let newHabit = Habit(title: trimmed, symbol: selectedSymbol, tintName: selectedTint, xpReward: xpReward, scheduledWeekdays: scheduledWeekdays)
            applyReminder(to: newHabit)
            modelContext.insert(newHabit)
            NotificationManager.scheduleHabit(newHabit)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save habit: \(error)")
        }
    }

    private func applyReminder(to habit: Habit) {
        guard hasReminder else {
            habit.reminderHour = nil
            habit.reminderMinute = nil
            return
        }
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        habit.reminderHour = components.hour
        habit.reminderMinute = components.minute
        Task { _ = await NotificationManager.requestAuthorization() }
    }
}
