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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                            systemImage: "checkmark.seal",
                            description: Text(selectedStatusFilter == 0 ? "You're all caught up! Create a task to track a goal." : "Tasks you complete will show up here.")
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
                                        .tint(.blue)
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
                        Image(systemName: "plus")
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
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring()) {
                    if isCompleted {
                        task.completedAt = nil
                    } else {
                        try? trackingService.toggleTask(task, on: Date(), context: modelContext)
                    }
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.body)
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
                    Text("\(task.xpReward) XP")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
