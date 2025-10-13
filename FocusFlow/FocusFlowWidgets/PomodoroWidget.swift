import WidgetKit
import SwiftUI

    // 依賴你已放在 Shared/ 的 FFPhase、FocusFlowStore

private func timeString(_ sec: TimeInterval) -> String {
    let m = Int(sec) / 60, s = Int(sec) % 60
    return String(format: "%02d:%02d", m, s)
}

struct PomodoroEntry: TimelineEntry {
    let date: Date
    let phase: FFPhase
    let isRunning: Bool
    let remaining: TimeInterval
    let completedCount: Int
}

struct PomodoroProvider: TimelineProvider {
    func placeholder(in: Context) -> PomodoroEntry {
        .init(date: .now, phase: .focus, isRunning: false, remaining: 25*60, completedCount: 0)
    }
    func getSnapshot(in: Context, completion: @escaping (PomodoroEntry)->Void) {
        completion(makeEntry())
    }
    func getTimeline(in: Context, completion: @escaping (Timeline<PomodoroEntry>)->Void) {
        let e = makeEntry()
            // 無互動：倒數時 60 秒刷新、靜止時 15 分鐘
        let next = Date().addingTimeInterval(e.isRunning ? 60 : 900)
        completion(Timeline(entries: [e], policy: .after(next)))
    }
    private func makeEntry() -> PomodoroEntry {
        let s = FocusFlowStore.load()
        let now = Date()
        let remaining: TimeInterval = {
            guard s.isRunning, let end = s.endDate else { return 0 }
            return max(0, end.timeIntervalSince(now))
        }()
        return .init(date: now, phase: s.phase, isRunning: s.isRunning,
                     remaining: remaining, completedCount: s.completedCount)
    }
}

struct PomodoroContentView: View {
    let e: PomodoroEntry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(e.phase == .focus ? "專注中" : "休息中").font(.headline)
            Text(e.isRunning ? timeString(e.remaining) : "未在倒數")
                .font(family == .systemSmall ? .title3 : .title2)
                .monospacedDigit()
            
            ProgressView(value: progress, total: 1)
                .progressViewStyle(.linear)
            
            if family != .systemSmall {
                Text("今日完成：\(e.completedCount)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var progress: Double {
        let total: Double = (e.phase == .focus) ? 25*60 : 5*60
        let r = min(max(e.remaining, 0), total)
        return total == 0 ? 0 : 1 - (r / total)
    }
}

struct PomodoroWidget: Widget {
    private let kind = "FocusFlowPomodoro"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomodoroProvider()) { entry in
            PomodoroContentView(e: entry)
        }
        .configurationDisplayName("FocusFlow 番茄鐘")
        .description("顯示專注/休息與剩餘時間。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
