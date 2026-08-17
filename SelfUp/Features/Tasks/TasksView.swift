import SwiftUI
import SwiftData

private enum TaskStatusFilter: String, CaseIterable, Identifiable {
    case active
    case planned
    case inProgress
    case blocked
    case completed

    var id: Self { self }

    var title: String {
        switch self {
        case .active: return "Active"
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .blocked: return "Blocked"
        case .completed: return "Completed"
        }
    }
}

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]

    @State private var showingEditor = false
    @State private var taskToEdit: TaskItem?
    @State private var showingSettings = false
    @State private var selectedPeriod: TaskPeriod = .today
    @State private var selectedStatus: TaskStatusFilter = .active

    private let trackingService = TrackingService()

    private var completedTasks: [TaskItem] {
        allTasks.filter { $0.effectiveStatus == .completed }
    }

    private var completionPercentage: Double {
        guard !allTasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(allTasks.count)
    }

    private var displayedTasks: [TaskItem] {
        allTasks.filter { task in
            guard task.effectivePeriod == selectedPeriod else { return false }
            switch selectedStatus {
            case .active: return task.effectiveStatus != .completed
            case .planned: return task.effectiveStatus == .planned
            case .inProgress: return task.effectiveStatus == .inProgress
            case .blocked: return task.effectiveStatus == .blocked
            case .completed: return task.effectiveStatus == .completed
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !allTasks.isEmpty {
                    overview
                }

                periodPicker
                statusPicker

                if displayedTasks.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No \(selectedStatus.title) Tasks",
                        systemImage: selectedPeriod.symbol,
                        description: Text("Nothing in \(selectedPeriod.title.lowercased()) yet. Add a task or choose another period.")
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(displayedTasks) { task in
                            TaskRow(task: task, trackingService: trackingService)
                                .listRowBackground(Color(.secondarySystemGroupedBackground))
                                .swipeActions(edge: .leading) {
                                    Button {
                                        taskToEdit = task
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(SelfUpStyle.brandFill)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(task)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .animation(reduceMotion ? nil : .snappy, value: displayedTasks.map(\.id))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingEditor = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SelfUpStyle.brand)
                    }
                    .accessibilityLabel("Add task")
                }
            }
            .sheet(isPresented: $showingEditor) {
                TaskEditorView(defaultPeriod: selectedPeriod)
            }
            .sheet(item: $taskToEdit) { task in
                TaskEditorView(taskToEdit: task)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var overview: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TASK OVERVIEW")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SelfUpStyle.brand)
                    .tracking(1)
                Text("\(completedTasks.count) of \(allTasks.count) finished")
                    .font(.subheadline.weight(.semibold))
                Text("\(allTasks.filter { $0.effectiveStatus == .inProgress }.count) in progress · \(allTasks.filter { $0.effectiveStatus == .blocked }.count) blocked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: completionPercentage)
                    .stroke(SelfUpStyle.brand, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(completionPercentage * 100))%")
                    .font(.caption2.weight(.bold))
            }
            .frame(width: 46, height: 46)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Task overview")
        .accessibilityValue("\(completedTasks.count) of \(allTasks.count) finished, \(Int(completionPercentage * 100)) percent")
        .premiumCard(cornerRadius: SelfUpStyle.Radius.medium)
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var periodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskPeriod.allCases) { period in
                    Button {
                        withAnimation(reduceMotion ? nil : .snappy) { selectedPeriod = period }
                        Haptics.selection()
                    } label: {
                        Label(period.title, systemImage: period.symbol)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .frame(minHeight: SelfUpStyle.Control.minimumTapTarget)
                            .foregroundStyle(selectedPeriod == period ? .white : .primary)
                            .background(
                                Capsule().fill(selectedPeriod == period ? SelfUpStyle.brandFill : Color(.secondarySystemGroupedBackground))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(period.title) task period")
                    .accessibilityValue(selectedPeriod == period ? "Selected" : "Not selected")
                    .accessibilityAddTraits(selectedPeriod == period ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 14)
    }

    private var statusPicker: some View {
        Picker("Status", selection: $selectedStatus) {
            ForEach(TaskStatusFilter.allCases) { status in
                Text(status.title).tag(status)
            }
        }
        .pickerStyle(.menu)
        .frame(minHeight: SelfUpStyle.Control.minimumTapTarget)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .tint(SelfUpStyle.brand)
        .accessibilityValue(selectedStatus.title)
    }

    private func delete(_ task: TaskItem) {
        modelContext.delete(task)
        try? modelContext.save()
    }
}

struct TaskRow: View {
    let task: TaskItem
    let trackingService: TrackingService

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrationToken = 0

    private var isCompleted: Bool { task.effectiveStatus == .completed }

    private var priorityColor: Color {
        switch task.priority {
        case .high: return SelfUpStyle.danger
        case .medium: return SelfUpStyle.warning
        case .low: return SelfUpStyle.brand
        }
    }

    private var statusColor: Color {
        switch task.effectiveStatus {
        case .planned: return .secondary
        case .inProgress: return SelfUpStyle.brand
        case .blocked: return SelfUpStyle.danger
        case .completed: return SelfUpStyle.success
        }
    }

    private var metadataLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            return AnyLayout(VStackLayout(alignment: .leading, spacing: SelfUpStyle.Spacing.xSmall))
        }
        return AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: SelfUpStyle.Spacing.small))
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: toggleCompletion) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? SelfUpStyle.successFill : Color.primary.opacity(0.06))
                        .frame(width: SelfUpStyle.Control.compactIcon, height: SelfUpStyle.Control.compactIcon)
                    Circle()
                        .stroke(isCompleted ? Color.clear : Color.primary.opacity(0.14), lineWidth: 1)
                        .frame(width: SelfUpStyle.Control.compactIcon, height: SelfUpStyle.Control.compactIcon)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
                    }
                    if celebrationToken > 0 {
                        CompletionMotionView(compact: true)
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
            .accessibilityLabel("Completion for \(task.title)")
            .accessibilityValue(isCompleted ? "Completed" : "Not completed")
            .accessibilityHint(isCompleted ? "Double tap to mark planned" : "Double tap to mark complete")

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.body.weight(.medium))
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)

                metadataLayout {
                    Menu {
                        ForEach(TaskWorkflowStatus.allCases) { status in
                            Button {
                                updateStatus(status)
                            } label: {
                                Label(status.title, systemImage: status.symbol)
                            }
                        }
                    } label: {
                        Label(task.effectiveStatus.title, systemImage: task.effectiveStatus.symbol)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(statusColor)
                            .frame(minHeight: SelfUpStyle.Control.minimumTapTarget, alignment: .leading)
                    }
                    .accessibilityLabel("Status for \(task.title)")
                    .accessibilityValue(task.effectiveStatus.title)

                    Text(task.priority.rawValue.capitalized)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(priorityColor)

                    if let dueDate = task.dueDate {
                        Text("Due \(dueDate, style: .date)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if dynamicTypeSize.isAccessibilitySize {
                    Text("\(task.xpReward) XP")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !dynamicTypeSize.isAccessibilitySize {
                Text("+\(task.xpReward)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(task.xpReward) XP reward")
            }
        }
        .padding(.vertical, 6)
    }

    private func toggleCompletion() {
        if reduceMotion {
            applyCompletionToggle()
        } else {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.65)) {
                applyCompletionToggle()
            }
        }
    }

    private func updateStatus(_ status: TaskWorkflowStatus) {
        if reduceMotion {
            applyStatusUpdate(status)
        } else {
            withAnimation(.snappy) {
                applyStatusUpdate(status)
            }
        }
    }

    private func applyCompletionToggle() {
        if isCompleted {
            task.move(to: .planned)
            Haptics.light()
        } else {
            _ = try? trackingService.toggleTask(task, on: Date(), context: modelContext)
            createNextOccurrenceIfNeeded()
            celebrationToken += 1
            Haptics.success()
        }
        try? modelContext.save()
    }

    private func applyStatusUpdate(_ status: TaskWorkflowStatus) {
        let wasCompleted = isCompleted
        task.move(to: status)
        if !wasCompleted && status == .completed {
            createNextOccurrenceIfNeeded()
            celebrationToken += 1
            Haptics.success()
        } else {
            Haptics.selection()
        }
        try? modelContext.save()
    }

    private func createNextOccurrenceIfNeeded() {
        guard task.recurrenceAdvancedAt == nil,
              let nextDate = task.nextOccurrence(after: task.dueDate ?? Date()) else { return }
        let next = TaskItem(
            title: task.title,
            dueDate: nextDate,
            priority: task.priority,
            xpReward: task.xpReward,
            period: task.effectivePeriod,
            recurrence: task.effectiveRecurrence,
            reminderHour: task.reminderHour,
            reminderMinute: task.reminderMinute
        )
        task.recurrenceAdvancedAt = Date()
        modelContext.insert(next)
        NotificationManager.scheduleTask(next)
    }
}
