import SwiftUI
import SwiftData

private struct WeekdayOption: Identifiable {
    let id: Int
    let shortLabel: String
    let accessibilityLabel: String
}

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

    private let weekdays = [
        WeekdayOption(id: 1, shortLabel: "S", accessibilityLabel: "Sunday"),
        WeekdayOption(id: 2, shortLabel: "M", accessibilityLabel: "Monday"),
        WeekdayOption(id: 3, shortLabel: "T", accessibilityLabel: "Tuesday"),
        WeekdayOption(id: 4, shortLabel: "W", accessibilityLabel: "Wednesday"),
        WeekdayOption(id: 5, shortLabel: "T", accessibilityLabel: "Thursday"),
        WeekdayOption(id: 6, shortLabel: "F", accessibilityLabel: "Friday"),
        WeekdayOption(id: 7, shortLabel: "S", accessibilityLabel: "Saturday")
    ]

    private let weekdayColumns = Array(
        repeating: GridItem(.flexible(), spacing: SelfUpStyle.Spacing.small),
        count: 4
    )
    
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
                            Label(symbolDisplayName(symbol), systemImage: symbol).tag(symbol)
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
                    LazyVGrid(columns: weekdayColumns, spacing: SelfUpStyle.Spacing.small) {
                        ForEach(weekdays) { weekday in
                            let isSelected = scheduledWeekdays == 0 || scheduledWeekdays & (1 << weekday.id) != 0
                            Button {
                                let bit = 1 << weekday.id
                                scheduledWeekdays = scheduledWeekdays & bit == 0 ? scheduledWeekdays | bit : scheduledWeekdays & ~bit
                            } label: {
                                Text(weekday.shortLabel)
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: SelfUpStyle.Control.minimumTapTarget)
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .background(
                                        Capsule().fill(isSelected ? SelfUpStyle.brandFill : Color.secondary.opacity(0.16))
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(weekday.accessibilityLabel)
                            .accessibilityValue(isSelected ? "Selected" : "Not selected")
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
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

    private func symbolDisplayName(_ symbol: String) -> String {
        switch symbol {
        case "checkmark.circle.fill": return "Checkmark"
        case "flame.fill": return "Flame"
        case "heart.fill": return "Heart"
        case "star.fill": return "Star"
        case "book.fill": return "Book"
        case "drop.fill": return "Water drop"
        case "bolt.fill": return "Bolt"
        default: return "Symbol"
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
