import WidgetKit
import SwiftUI

    // MARK: - Entry
struct PomodoroEntry: TimelineEntry {
    let date: Date
    let phase: FFPhase
    let isRunning: Bool
    let remaining: TimeInterval
    let focusMinutesToday: Int
    let sessionsToday: Int
}

    // MARK: - Provider
struct PomodoroProvider: TimelineProvider {
    func placeholder(in: Context) -> PomodoroEntry {
        .init(date: .now, phase: .focus, isRunning: false, remaining: 25*60,
              focusMinutesToday: 0, sessionsToday: 0)
    }
    
    func getSnapshot(in: Context, completion: @escaping (PomodoroEntry)->Void) {
        completion(makeEntry())
    }
    
    func getTimeline(in: Context, completion: @escaping (Timeline<PomodoroEntry>)->Void) {
        let e = makeEntry()
            // 計時中 60 秒刷新；否則 15 分鐘
        let next = Date().addingTimeInterval(e.isRunning ? 60 : 900)
        completion(Timeline(entries: [e], policy: .after(next)))
    }
    
    private func makeEntry() -> PomodoroEntry {
            // 1) 即時狀態（Shared/FocusFlowStore）
        let s = FocusFlowStore.load()
        let now = Date()
        let remaining: TimeInterval = {
            guard s.isRunning, let end = s.endDate else { return 0 }
            return max(0, end.timeIntervalSince(now))
        }()
        
            // 2) 今天統計（Shared/WidgetDataManager）
        let (focusMin, sessions) = WidgetDataManager.shared.computePomodoroToday()
        
        return .init(date: now,
                     phase: s.phase,
                     isRunning: s.isRunning,
                     remaining: remaining,
                     focusMinutesToday: focusMin,
                     sessionsToday: sessions)
    }
}

    // MARK: - View
struct PomodoroView: View {
    let entry: PomodoroEntry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        switch family {
        case .systemSmall: smallView
        default: mediumView
        }
    }
    
    private func timeStr(_ sec: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(sec) / 60, Int(sec) % 60)
    }

    
        // Small：狀態膠囊 + 大倒數 + 今日累積
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                Text("Pomodoro")
                    .font(.subheadline).fontWeight(.semibold)
                    .lineLimit(1)
            }
            .foregroundStyle(.blue)
            
            Text(statusText)
                .font(.title3).fontWeight(.bold)
                .foregroundStyle(phaseColor)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(phaseColor.opacity(0.12), in: Capsule())
            
            Text(entry.isRunning ? timeStr(entry.remaining) : "未在倒數")
                .font(.title2).monospacedDigit()
            
            ProgressView(value: progress, total: 1)
                .progressViewStyle(.linear)
            
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle")
                Text("\(entry.focusMinutesToday) 分（\(entry.sessionsToday) 次）")
                    .font(.footnote).monospacedDigit()
                Spacer()
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
        // Medium：左側狀態區 + 右側統計卡
    private var mediumView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: entry.phase == .focus ? "bolt.fill" : "cup.and.saucer")
                    Text(statusText)
                        .font(.headline).fontWeight(.semibold)
                        .foregroundStyle(phaseColor)
                }
                Text(entry.isRunning ? timeStr(entry.remaining) : "未在倒數")
                    .font(.title2).monospacedDigit()
                
                ProgressView(value: progress, total: 1)
                    .progressViewStyle(.linear)
                
                Spacer()
            }
            
            Spacer()
            
            metricCard(title: "今日累積", value: "\(entry.focusMinutesToday)", unit: "分", icon: "clock")
            metricCard(title: "完成次數", value: "\(entry.sessionsToday)", unit: "次", icon: "checkmark.circle")
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func metricCard(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Text(value).font(.title3).bold().monospacedDigit()
            Text(unit).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var statusText: String {
        entry.phase == .focus ? "專注中" : "休息中"
    }
    private var phaseColor: Color {
        entry.phase == .focus ? .green : .orange
    }
    private var progress: Double {
        let total: Double = (entry.phase == .focus) ? 25*60 : 5*60
        let r = min(max(entry.remaining, 0), total)
        return total == 0 ? 0 : 1 - (r / total)
    }
}

    // MARK: - Widget
struct PomodoroWidget: Widget {
    private let kind = "FocusFlowPomodoro"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomodoroProvider()) { entry in
            PomodoroView(entry: entry)
        }
        .configurationDisplayName("FocusFlow 番茄鐘")
        .description("顯示專注/休息倒數與今天累積。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

    // MARK: - Previews
#Preview(as: .systemSmall) {
    PomodoroWidget()
} timeline: {
    PomodoroEntry(date: .now, phase: .focus, isRunning: true,  remaining: 19*60+5, focusMinutesToday: 45, sessionsToday: 3)
    PomodoroEntry(date: .now, phase: .break, isRunning: false, remaining: 0,         focusMinutesToday: 0,  sessionsToday: 0)
}

#Preview(as: .systemMedium) {
    PomodoroWidget()
} timeline: {
    PomodoroEntry(date: .now, phase: .focus, isRunning: true,  remaining: 7*60+12,  focusMinutesToday: 60, sessionsToday: 4)
    PomodoroEntry(date: .now, phase: .break, isRunning: false, remaining: 0,         focusMinutesToday: 25, sessionsToday: 1)
}
