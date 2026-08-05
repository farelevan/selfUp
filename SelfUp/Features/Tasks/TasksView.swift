import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]
    
    @State private var showingEditor = false
    @State private var taskToEdit: TaskItem? = nil
    @State private var showingSettings = false
    @State private var selectedStatusFilter = 0 // 0 = Pending, 1 = Completed
    
    private let trackingService = TrackingService()
    
    private var pendingTasks: [TaskItem] {
        allTasks.filter { $0.completedAt == nil }
    }
    
    private var completedTasks: [TaskItem] {
        allTasks.filter { $0.completedAt != nil }
    }
    
    private var completionPercentage: Double {
        guard !allTasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(allTasks.count)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Metrics Banner
                if !allTasks.isEmpty {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TASK OVERVIEW")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(SelfUpStyle.primaryIndigo)
                                .tracking(1)
                            Text("\(completedTasks.count) of \(allTasks.count) Tasks Finished")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(Color.primary.opacity(0.08), lineWidth: 5)
                                .frame(width: 44, height: 44)
                            Circle()
                                .trim(from: 0, to: CGFloat(completionPercentage))
                                .stroke(SelfUpStyle.heroGradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 44, height: 44)
                            Text("\(Int(completionPercentage * 100))%")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                    }
                    .premiumCard(cornerRadius: 16)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                
                // Filter Segmented Control
                Picker("Status", selection: $selectedStatusFilter) {
                    Text("Pending (\(pendingTasks.count))").tag(0)
                    Text("Completed (\(completedTasks.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Group {
                    let displayedTasks = selectedStatusFilter == 0 ? pendingTasks : completedTasks
                    
                    if displayedTasks.isEmpty {
                        Spacer()
                        ContentUnavailableView(
                            selectedStatusFilter == 0 ? "No Pending Tasks" : "No Completed Tasks",
                            systemImage: "checkmark.seal.fill",
                            description: Text(selectedStatusFilter == 0 ? "You're all caught up! Create a new focus task." : "Tasks you complete will show up here.")
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
                                        .tint(SelfUpStyle.primaryIndigo)
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
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Tasks")
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
                TaskEditorView()
            }
            .sheet(item: $taskToEdit) { task in
                TaskEditorView(taskToEdit: task)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
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
    
    private var isCompleted: Bool {
        task.completedAt != nil
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high: return Color.coral
        case .medium: return Color.orange
        case .low: return SelfUpStyle.primaryIndigo
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    if isCompleted {
                        task.completedAt = nil
                        Haptics.light()
                    } else {
                        try? trackingService.toggleTask(task, on: Date(), context: modelContext)
                        Haptics.success()
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.emerald : Color.primary.opacity(0.06))
                        .frame(width: 28, height: 28)
                    Image(systemName: isCompleted ? "checkmark" : "")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .pressableScale(scale: 0.88)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                
                HStack(spacing: 6) {
                    // Priority Pill
                    Text(task.priority.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(priorityColor.opacity(0.12))
                        .foregroundStyle(priorityColor)
                        .clipShape(Capsule())
                    
                    if let dueDate = task.dueDate {
                        Text("•")
                        Text("Due: \(dueDate, style: .date)")
                    }
                    
                    Text("•")
                    Text("+\(task.xpReward) XP")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

