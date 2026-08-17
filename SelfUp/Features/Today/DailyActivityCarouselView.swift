import SwiftUI
import SwiftData

enum ActivityCarouselPage: Int, CaseIterable, Identifiable, Hashable {
    case habits = 0
    case tasks = 1
    case money = 2
    
    var id: Int { rawValue }
    
    var shortTitle: String {
        switch self {
        case .habits: return "Habits"
        case .tasks: return "Tasks"
        case .money: return "Money"
        }
    }
    
    var title: String {
        switch self {
        case .habits: return "DAILY HABITS"
        case .tasks: return "TODAY'S TASKS"
        case .money: return "MONEY FLOW"
        }
    }
    
    var symbol: String {
        switch self {
        case .habits: return "flame.fill"
        case .tasks: return "target"
        case .money: return "dollarsign.circle.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .habits: return SelfUpStyle.success
        case .tasks: return SelfUpStyle.brand
        case .money: return SelfUpStyle.danger
        }
    }
}

struct DailyActivityCarouselView: View {
    let habits: [Habit]
    let openTasks: [TaskItem]
    let moneySummary: MoneySummary
    let currencySymbol: String
    
    @State private var currentPage: ActivityCarouselPage = .habits
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let trackingService = TrackingService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Daily activity", selection: $currentPage) {
                ForEach(ActivityCarouselPage.allCases) { page in
                    Text(page.shortTitle).tag(page)
                }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: SelfUpStyle.minimumControlSize)
            .onChange(of: currentPage) { _, _ in Haptics.selection() }
            
            // Carousel Content Container with Multi-Directional Gesture Support
            ZStack {
                switch currentPage {
                case .habits:
                    habitsView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .tasks:
                    tasksView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .money:
                    moneyView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .frame(minHeight: 165)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        if abs(horizontalAmount) > abs(value.translation.height) {
                            if horizontalAmount < -25 {
                                switchPage(delta: 1)
                            } else if horizontalAmount > 25 {
                                switchPage(delta: -1)
                            }
                        }
                    }
            )
        }
        .premiumCard(cornerRadius: 18)
        .padding(.horizontal)
    }
    
    private func switchPage(delta: Int) {
        let count = ActivityCarouselPage.allCases.count
        let nextIndex = (currentPage.rawValue + delta + count) % count
        if let newPage = ActivityCarouselPage(rawValue: nextIndex) {
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75)) {
                currentPage = newPage
            }
        }
    }
    
    // MARK: - Habits Carousel Page
    private var habitsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if habits.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(SelfUpStyle.success)
                    Text("No habits set for today yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(habits) { habit in
                            HabitQuickCell(habit: habit)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Tasks Carousel Page
    private var tasksView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if openTasks.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(SelfUpStyle.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All Goals Completed!")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("Zero focus tasks pending for today.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(openTasks.prefix(3)) { task in
                        HStack(spacing: 10) {
                            Capsule()
                                .fill(task.priority == .high ? SelfUpStyle.danger : (task.priority == .medium ? SelfUpStyle.warning : SelfUpStyle.info))
                                .frame(width: 4, height: 22)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.system(.subheadline, design: .default))
                                    .fontWeight(.bold)
                                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                                Text("\(task.priority.rawValue.capitalized) priority")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.6)) {
                                    _ = try? trackingService.toggleTask(task, on: Date(), context: modelContext)
                                    Haptics.success()
                                }
                            } label: {
                                Image(systemName: "circle")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: SelfUpStyle.minimumControlSize, height: SelfUpStyle.minimumControlSize)
                            }
                            .pressableScale(scale: 0.88)
                            .accessibilityLabel("Complete \(task.title)")
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.04)))
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Money Carousel Page
    private var moneyView: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SelfUpStyle.spacingLG) {
                incomeSummary
                expenseSummary
            }
            VStack(spacing: SelfUpStyle.spacingSM) {
                incomeSummary
                expenseSummary
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var incomeSummary: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.right.circle.fill")
                        .foregroundStyle(SelfUpStyle.success)
                        .font(.caption)
                    Text("Income")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("\(currencySymbol) \(moneySummary.income, format: .number)")
                    .font(.system(.headline, design: .default))
                    .fontWeight(.bold)
                    .foregroundStyle(SelfUpStyle.success)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18).fill(SelfUpStyle.success.opacity(0.1)))
            .accessibilityElement(children: .combine)
    }

    private var expenseSummary: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundStyle(SelfUpStyle.danger)
                        .font(.caption)
                    Text("Expenses")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("\(currencySymbol) \(moneySummary.expenses, format: .number)")
                    .font(.system(.headline, design: .default))
                    .fontWeight(.bold)
                    .foregroundStyle(SelfUpStyle.danger)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18).fill(SelfUpStyle.danger.opacity(0.1)))
            .accessibilityElement(children: .combine)
    }
}
