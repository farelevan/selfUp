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
    
    private var completedTodayCount: Int {
        activeHabits.filter { ProgressService.isCompleted($0, on: Date()) }.count
    }
    
    private var completionRate: Double {
        guard !activeHabits.isEmpty else { return 0 }
        return Double(completedTodayCount) / Double(activeHabits.count)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if activeHabits.isEmpty {
                    ContentUnavailableView(
                        "Build Your First Habit",
                        systemImage: "flame.circle.fill",
                        description: Text("Small daily habits lead to extraordinary long-term growth.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Habits Summary Metric Banner
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("DAILY HABIT STREAK")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(SelfUpStyle.primaryIndigo)
                                        .tracking(1.2)
                                    Text("\(completedTodayCount) of \(activeHabits.count) Done")
                                        .font(.system(.title3, design: .rounded))
                                        .fontWeight(.bold)
                                }
                                
                                Spacer()
                                
                                ZStack {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 6)
                                        .frame(width: 52, height: 52)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(completionRate))
                                        .stroke(SelfUpStyle.incomeGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 52, height: 52)
                                    Text("\(Int(completionRate * 100))%")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundStyle(SelfUpStyle.cyberLime)
                                }
                            }
                            .bentoCard(cornerRadius: 24)
                            .padding(.horizontal)
                            
                            // Habit Cards Grid
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(activeHabits) { habit in
                                    HabitCard(habit: habit, trackingService: trackingService)
                                        .contextMenu {
                                            Button {
                                                habitToEdit = habit
                                            } label: {
                                                Label("Edit Habit", systemImage: "pencil")
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
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
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
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SelfUpStyle.primaryIndigo)
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
        case "green": return .emerald
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .coral
        case "teal": return .teal
        case "indigo": return SelfUpStyle.primaryIndigo
        default: return SelfUpStyle.primaryIndigo
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
            // Icon & Toggle Row
            HStack {
                ZStack {
                    Circle()
                        .fill(isCompletedToday ? tintColor : tintColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: habit.symbol)
                        .font(.title3)
                        .foregroundStyle(isCompletedToday ? .white : tintColor)
                }
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        _ = try? trackingService.toggleHabit(habit, on: Date(), context: modelContext)
                        if !isCompletedToday {
                            Haptics.success()
                        } else {
                            Haptics.light()
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isCompletedToday ? SelfUpStyle.cyberLime : Color.primary.opacity(0.06))
                            .frame(width: 34, height: 34)
                        Circle()
                            .stroke(isCompletedToday ? Color.clear : Color.primary.opacity(0.12), lineWidth: 1.5)
                            .frame(width: 34, height: 34)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(isCompletedToday ? .white : Color.primary.opacity(0.35))
                    }
                }
                .pressableScale(scale: 0.88)
            }
            
            // Text Details
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(currentStreak)d streak")
                        }
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                        .foregroundStyle(.orange)
                    } else {
                        Text("+\(habit.xpReward) XP")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(SelfUpStyle.primaryIndigo.opacity(0.1)))
                            .foregroundStyle(SelfUpStyle.primaryIndigo)
                    }
                }
            }
            
            // 7-day Dot Matrix
            HStack(spacing: 4) {
                ForEach(0..<7) { index in
                    Capsule()
                        .fill(last7DaysCompletions[index] ? tintColor : Color.primary.opacity(0.1))
                        .frame(height: 5)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isCompletedToday ? tintColor.opacity(0.4) : Color.primary.opacity(0.06), lineWidth: 1.5)
        )
    }
}

