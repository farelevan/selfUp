import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.createdAt) private var activeHabits: [Habit]
    
    @State private var showingEditor = false
    @State private var habitToEdit: Habit? = nil
    @State private var showingSettings = false
    
    private let trackingService = TrackingService()
    
    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [
            GridItem(
                .adaptive(minimum: 156, maximum: 280),
                spacing: SelfUpStyle.Spacing.large
            )
        ]
    }

    private var scheduledHabitsToday: [Habit] {
        activeHabits.filter { $0.isScheduled(on: Date()) }
    }
    
    private var completedTodayCount: Int {
        scheduledHabitsToday.filter { ProgressService.isCompleted($0, on: Date()) }.count
    }
    
    private var completionRate: Double {
        guard !scheduledHabitsToday.isEmpty else { return 0 }
        return Double(completedTodayCount) / Double(scheduledHabitsToday.count)
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
                                        .foregroundStyle(SelfUpStyle.brand)
                                        .tracking(1.2)
                                    Text("\(completedTodayCount) of \(scheduledHabitsToday.count) Done")
                                        .font(.system(.title3, design: .default))
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
                                        .font(.system(size: 11, weight: .bold, design: .default))
                                        .foregroundStyle(SelfUpStyle.success)
                                }
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Today's habit completion")
                            .accessibilityValue("\(completedTodayCount) of \(scheduledHabitsToday.count), \(Int(completionRate * 100)) percent")
                            .bentoCard(cornerRadius: SelfUpStyle.Radius.medium)
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
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SelfUpStyle.brand)
                    }
                    .accessibilityLabel("Add habit")
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrationToken = 0
    
    private var isCompletedToday: Bool {
        ProgressService.isCompleted(habit, on: Date())
    }
    
    private var currentStreak: Int {
        ProgressService.streak(completionDates: habit.completions.map { $0.date }, through: Date())
    }
    
    private var tintColor: Color {
        SelfUpStyle.habitTint(named: habit.tintName)
    }

    private var tintFillColor: Color {
        SelfUpStyle.habitFill(named: habit.tintName)
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
                        .fill(isCompletedToday ? tintFillColor : tintColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: habit.symbol)
                        .font(.title3)
                        .foregroundStyle(isCompletedToday ? .white : tintColor)
                }
                Spacer()
                
                Button(action: toggleCompletion) {
                    ZStack {
                        Circle()
                            .fill(isCompletedToday ? SelfUpStyle.successFill : Color.primary.opacity(0.06))
                            .frame(width: SelfUpStyle.Control.compactIcon, height: SelfUpStyle.Control.compactIcon)
                        Circle()
                            .stroke(isCompletedToday ? Color.clear : Color.primary.opacity(0.12), lineWidth: 1.5)
                            .frame(width: SelfUpStyle.Control.compactIcon, height: SelfUpStyle.Control.compactIcon)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isCompletedToday ? .white : Color.primary.opacity(0.35))
                        if celebrationToken > 0 {
                            CompletionMotionView(color: tintFillColor, compact: true)
                                .id(celebrationToken)
                        }
                    }
                    .frame(
                        minWidth: SelfUpStyle.Control.minimumTapTarget,
                        minHeight: SelfUpStyle.Control.minimumTapTarget
                    )
                    .contentShape(Rectangle())
                }
                .pressableScale(scale: 0.88)
                .accessibilityLabel("Completion for \(habit.title)")
                .accessibilityValue(isCompletedToday ? "Completed today" : "Not completed today")
                .accessibilityHint(isCompletedToday ? "Double tap to mark incomplete" : "Double tap to mark complete")
            }
            
            // Text Details
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.system(.headline, design: .default))
                    .fontWeight(.bold)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                
                HStack(spacing: 6) {
                    if currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(SelfUpStyle.warning)
                            Text("\(currentStreak)d streak")
                        }
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(SelfUpStyle.warning.opacity(0.12)))
                        .foregroundStyle(SelfUpStyle.warning)
                    } else {
                        Text("+\(habit.xpReward) XP")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(SelfUpStyle.brand.opacity(0.1)))
                            .foregroundStyle(SelfUpStyle.brand)
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Last seven days")
            .accessibilityValue("\(last7DaysCompletions.filter { $0 }.count) days completed")
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

    private func toggleCompletion() {
        if reduceMotion {
            applyCompletionToggle()
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                applyCompletionToggle()
            }
        }
    }

    private func applyCompletionToggle() {
        let didComplete = (try? trackingService.toggleHabit(habit, on: Date(), context: modelContext)) == true
        if didComplete {
            celebrationToken += 1
            Haptics.success()
        } else {
            Haptics.light()
        }
    }
}
