import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.createdAt) private var activeHabits: [Habit]
    
    @State private var showingEditor = false
    @State private var habitToEdit: Habit? = nil
    
    private let trackingService = TrackingService()
    
    var body: some View {
        NavigationStack {
            Group {
                if activeHabits.isEmpty {
                    ContentUnavailableView(
                        "No Active Habits",
                        systemImage: "checklist",
                        description: Text("Create a daily habit to start building consistency.")
                    )
                } else {
                    List {
                        ForEach(activeHabits) { habit in
                            HabitRow(habit: habit, trackingService: trackingService)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        habitToEdit = habit
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        delete(habit)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        archive(habit)
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                HabitEditorView()
            }
            .sheet(item: $habitToEdit) { habit in
                HabitEditorView(habitToEdit: habit)
            }
        }
    }
    
    private func archive(_ habit: Habit) {
        habit.isArchived = true
        try? modelContext.save()
    }
    
    private func delete(_ habit: Habit) {
        modelContext.delete(habit)
        try? modelContext.save()
    }
}

struct HabitRow: View {
    let habit: Habit
    let trackingService: TrackingService
    @Environment(\.modelContext) private var modelContext
    
    private var isCompletedToday: Bool {
        ProgressService.isCompleted(habit, on: Date())
    }
    
    private var currentStreak: Int {
        ProgressService.streak(completionDates: habit.completions.map { $0.date }, through: Date())
    }
    
    private var color: Color {
        switch habit.tintName {
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .blue
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: habit.symbol)
                .font(.title2)
                .foregroundStyle(isCompletedToday ? .secondary : color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(habit.title)
                    .font(.headline)
                    .strikethrough(isCompletedToday)
                    .foregroundStyle(isCompletedToday ? .secondary : .primary)
                
                HStack {
                    Text("\(habit.xpReward) XP")
                    Text("•")
                    Text("Streak: \(currentStreak) days")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                try? trackingService.toggleHabit(habit, on: Date(), context: modelContext)
            } label: {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompletedToday ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCompletedToday ? "Complete" : "Mark complete")
        }
        .padding(.vertical, 4)
    }
}
