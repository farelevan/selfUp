import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.createdAt) private var activeHabits: [Habit]
    
    @State private var showingEditor = false
    @State private var habitToEdit: Habit? = nil
    @State private var showingSettings = false
    
    private let trackingService = TrackingService()
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
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
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(activeHabits) { habit in
                                HabitCard(habit: habit, trackingService: trackingService)
                                    .contextMenu {
                                        Button {
                                            habitToEdit = habit
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button {
                                            archive(habit)
                                        } label: {
                                            Label("Archive", systemImage: "archivebox")
                                        }
                                        
                                        Button(role: .destructive) {
                                            delete(habit)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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

struct HabitCard: View {
    let habit: Habit
    let trackingService: TrackingService
    @Environment(\.modelContext) private var modelContext
    
    private var isCompletedToday: Bool {
        ProgressService.isCompleted(habit, on: Date())
    }
    
    private var currentStreak: Int {
        ProgressService.streak(completionDates: habit.completions.map { $0.date }, through: Date())
    }
    
    private var tintColor: Color {
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
    
    private var last7DaysCompletions: [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return false }
            return ProgressService.isCompleted(habit, on: date)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Icon & Action row
            HStack {
                ZStack {
                    Circle()
                        .fill(isCompletedToday ? tintColor : tintColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: habit.symbol)
                        .font(.headline)
                        .foregroundStyle(isCompletedToday ? .white : tintColor)
                }
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        _ = try? trackingService.toggleHabit(habit, on: Date(), context: modelContext)
                    }
                } label: {
                    Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isCompletedToday ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Text Details
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if currentStreak > 0 {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(currentStreak) day streak")
                    } else {
                        Text("\(habit.xpReward) XP reward")
                    }
                }
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)
            }
            
            // Mini 7-day grid representation
            HStack(spacing: 4) {
                ForEach(0..<7) { index in
                    Circle()
                        .fill(last7DaysCompletions[index] ? tintColor : Color.gray.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color(white: 0, opacity: 0.03), radius: 6, x: 0, y: 3)
    }
}
