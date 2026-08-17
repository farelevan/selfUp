import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct VibeScoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> VibeScoreEntry {
        VibeScoreEntry(date: Date(), snapshot: sampleSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (VibeScoreEntry) -> Void) {
        let snapshot = WidgetDataStore.shared.loadSnapshot()
        completion(VibeScoreEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VibeScoreEntry>) -> Void) {
        let snapshot = WidgetDataStore.shared.loadSnapshot()
        let entry = VibeScoreEntry(date: Date(), snapshot: snapshot)
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private var sampleSnapshot: WidgetSnapshot {
        WidgetSnapshot(vibeScore: 88, level: 3, xp: 340, completedHabits: 4, totalHabits: 5, pendingTasks: 2, lastUpdated: Date())
    }
}

struct VibeScoreEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

// MARK: - Widget Views
struct VibeScoreWidgetEntryView: View {
    var entry: VibeScoreProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallVibeWidget(snapshot: entry.snapshot)
        case .systemMedium:
            MediumVibeWidget(snapshot: entry.snapshot)
        case .accessoryCircular:
            LockScreenCircularWidget(snapshot: entry.snapshot)
        case .accessoryRectangular:
            LockScreenRectangularWidget(snapshot: entry.snapshot)
        case .accessoryInline:
            Label("Life \(entry.snapshot.vibeScore) • \(entry.snapshot.completedHabits)/\(entry.snapshot.totalHabits) Habits", systemImage: "sparkles")
        default:
            SmallVibeWidget(snapshot: entry.snapshot)
        }
    }
}

// MARK: - Home Screen Small Widget
struct SmallVibeWidget: View {
    let snapshot: WidgetSnapshot
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("LVL \(snapshot.level)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(SelfUpStyle.brand.opacity(0.14)))
                    .foregroundStyle(SelfUpStyle.brand)
                Spacer()
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(SelfUpStyle.success)
            }
            
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                    .frame(width: 72, height: 72)
                
                Circle()
                    .trim(from: 0, to: CGFloat(snapshot.vibeScore) / 100.0)
                    .stroke(
                        SelfUpStyle.lifeScoreGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 72, height: 72)
                
                VStack(spacing: 0) {
                    Text("\(snapshot.vibeScore)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                    Text("LIFE")
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(SelfUpStyle.success)
                }
            }
            
            Text("\(snapshot.completedHabits)/\(snapshot.totalHabits) Habits Done")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            Color(.secondarySystemGroupedBackground)
        }
    }
}

// MARK: - Home Screen Medium Widget
struct MediumVibeWidget: View {
    let snapshot: WidgetSnapshot
    
    var body: some View {
        HStack(spacing: 16) {
            // Gauge Left Section
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 10)
                    .frame(width: 86, height: 86)
                
                Circle()
                    .trim(from: 0, to: CGFloat(snapshot.vibeScore) / 100.0)
                    .stroke(
                        SelfUpStyle.lifeScoreGradient,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 86, height: 86)
                
                VStack(spacing: 0) {
                    Text("\(snapshot.vibeScore)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                    Text("LIFE")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(SelfUpStyle.success)
                }
            }
            
            // Stats Right Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(SelfUpStyle.achievement)
                        Text("LEVEL \(snapshot.level)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    Text("\(snapshot.xp) XP")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Habit Streaks")
                            .font(.system(size: 11, weight: .semibold))
                        Spacer()
                        Text("\(snapshot.completedHabits)/\(snapshot.totalHabits)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SelfUpStyle.success)
                    }
                    
                    let habitProgress = snapshot.totalHabits > 0 ? Double(snapshot.completedHabits) / Double(snapshot.totalHabits) : 0.0
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 6)
                            Capsule()
                                .fill(SelfUpStyle.electricLimeGradient)
                                .frame(width: max(6, geo.size.width * CGFloat(habitProgress)), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.caption2)
                        .foregroundStyle(SelfUpStyle.brand)
                    Text("Focus Tasks: \(snapshot.pendingTasks) Pending")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color(.secondarySystemGroupedBackground)
        }
    }
}

// MARK: - Lock Screen Circular Widget
struct LockScreenCircularWidget: View {
    let snapshot: WidgetSnapshot
    
    var body: some View {
        Gauge(value: Double(snapshot.vibeScore), in: 0...100) {
            Image(systemName: "sparkles")
        } currentValueLabel: {
            Text("\(snapshot.vibeScore)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

// MARK: - Lock Screen Rectangular Widget
struct LockScreenRectangularWidget: View {
    let snapshot: WidgetSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text("SelfUp Life: \(snapshot.vibeScore)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            Text("Habits: \(snapshot.completedHabits)/\(snapshot.totalHabits) Done")
                .font(.system(size: 11, weight: .medium))
            Text("Tasks: \(snapshot.pendingTasks) Due")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget Configuration
struct VibeScoreWidget: Widget {
    let kind: String = "VibeScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VibeScoreProvider()) { entry in
            VibeScoreWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SelfUp Life & Progress")
        .description("Track your Life Score, habit streaks, and XP level from your Home or Lock Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
