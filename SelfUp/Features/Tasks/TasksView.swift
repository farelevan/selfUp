import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]
    
    @State private var showingEditor = false
    @State private var taskToEdit: TaskItem? = nil
    
    private let trackingService = TrackingService()
    
    private var pendingTasks: [TaskItem] {
        allTasks.filter { $0.completedAt == nil }
    }
    
    private var completedTasks: [TaskItem] {
        allTasks.filter { $0.completedAt != nil }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if allTasks.isEmpty {
                    ContentUnavailableView(
                        "No Tasks",
                        systemImage: "checklist",
                        description: Text("Create a task to track your goals.")
                    )
                } else {
                    List {
                        if !pendingTasks.isEmpty {
                            Section(header: Text("Pending")) {
                                ForEach(pendingTasks) { task in
                                    TaskRow(task: task, trackingService: trackingService)
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
                        }
                        
                        if !completedTasks.isEmpty {
                            Section(header: Text("Completed")) {
                                ForEach(completedTasks) { task in
                                    TaskRow(task: task, trackingService: trackingService)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                delete(task)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
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
                TaskEditorView()
            }
            .sheet(item: $taskToEdit) { task in
                TaskEditorView(taskToEdit: task)
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
        HStack {
            Button {
                if isCompleted {
                    task.completedAt = nil
                } else {
                    try? trackingService.toggleTask(task, on: Date(), context: modelContext)
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                
                HStack {
                    Text(task.priority.rawValue.capitalized)
                        .foregroundStyle(priorityColor)
                        .bold()
                    
                    if let dueDate = task.dueDate {
                        Text("•")
                        Text("Due: \(dueDate, style: .date)")
                    }
                    
                    Text("•")
                    Text("\(task.xpReward) XP")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
