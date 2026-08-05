import SwiftUI
import SwiftData

enum ActivityCarouselPage: Int, CaseIterable, Identifiable {
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
        case .tasks: return "FOCUS GOALS"
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
        case .habits: return SelfUpStyle.cyberLime
        case .tasks: return SelfUpStyle.primaryIndigo
        case .money: return SelfUpStyle.hyperMagenta
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
    private let trackingService = TrackingService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Segmented Header Bar with Tap Pills & Controls
            HStack {
                HStack(spacing: 6) {
                    ForEach(ActivityCarouselPage.allCases) { page in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                currentPage = page
                                Haptics.selection()
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: page.symbol)
                                    .font(.system(size: 11, weight: .bold))
                                Text(page.shortTitle)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(currentPage == page ? page.accentColor : Color.primary.opacity(0.06))
                            )
                            .foregroundStyle(currentPage == page ? .white : .secondary)
                        }
                        .pressableScale(scale: 0.92)
                    }
                }
                
                Spacer()
                
                // Chevron Arrows
                HStack(spacing: 2) {
                    Button {
                        switchPage(delta: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                    }
                    .pressableScale(scale: 0.88)
                    
                    Button {
                        switchPage(delta: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                    }
                    .pressableScale(scale: 0.88)
                }
            }
            
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
            .frame(height: 165)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height
                        
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            if horizontalAmount < -25 {
                                switchPage(delta: 1) // Swipe Left -> Next
                            } else if horizontalAmount > 25 {
                                switchPage(delta: -1) // Swipe Right -> Prev
                            }
                        } else {
                            if verticalAmount < -25 {
                                switchPage(delta: 1) // Swipe Up -> Next
                            } else if verticalAmount > 25 {
                                switchPage(delta: -1) // Swipe Down -> Prev
                            }
                        }
                    }
            )
            
            // Footer Hint & Page Index
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "hand.draw.fill")
                        .font(.caption2)
                    Text("Swipe left/right or up/down inside box")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.tertiary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(ActivityCarouselPage.allCases) { page in
                        Circle()
                            .fill(currentPage == page ? page.accentColor : Color.primary.opacity(0.18))
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .cyberGlowingCard(color: currentPage.accentColor, cornerRadius: 24)
        .padding(.horizontal)
    }
    
    private func switchPage(delta: Int) {
        let count = ActivityCarouselPage.allCases.count
        let nextIndex = (currentPage.rawValue + delta + count) % count
        if let newPage = ActivityCarouselPage(rawValue: nextIndex) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                currentPage = newPage
                Haptics.selection()
            }
        }
    }
    
    // MARK: - Habits Carousel Page
    private var habitsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if habits.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(SelfUpStyle.cyberLime)
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
                        .foregroundStyle(SelfUpStyle.cyberLime)
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
                                .fill(task.priority == .high ? SelfUpStyle.hyperMagenta : (task.priority == .medium ? Color.orange : SelfUpStyle.cyberCyan))
                                .frame(width: 4, height: 22)
                            
                            Text(task.title)
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                    _ = try? trackingService.toggleTask(task, on: Date(), context: modelContext)
                                    Haptics.success()
                                }
                            } label: {
                                Image(systemName: "circle")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                            .pressableScale(scale: 0.88)
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
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.right.circle.fill")
                        .foregroundStyle(SelfUpStyle.cyberLime)
                        .font(.caption)
                    Text("Income")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("\(currencySymbol) \(moneySummary.income, format: .number)")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(SelfUpStyle.cyberLime)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18).fill(SelfUpStyle.cyberLime.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundStyle(SelfUpStyle.hyperMagenta)
                        .font(.caption)
                    Text("Expenses")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("\(currencySymbol) \(moneySummary.expenses, format: .number)")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(SelfUpStyle.hyperMagenta)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18).fill(SelfUpStyle.hyperMagenta.opacity(0.1)))
        }
        .frame(maxHeight: .infinity)
    }
}
