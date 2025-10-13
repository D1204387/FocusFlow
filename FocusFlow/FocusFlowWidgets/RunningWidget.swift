import WidgetKit
import SwiftUI

    // 依賴你已放在 Shared/ 的 RunningState、RunStore

private func tStr(_ sec: TimeInterval) -> String {
    let m = Int(sec) / 60, s = Int(sec) % 60
    return String(format: "%02d:%02d", m, s)
}
private func paceStr(_ p: Double) -> String {
    guard p > 0 else { return "--'--\"" }
    let m = Int(p) / 60, s = Int(p) % 60
    return String(format: "%d'%02d\"", m, s)
}

struct RunEntry: TimelineEntry {
    let date: Date
    let phase: RunningState.Phase
    let elapsed: TimeInterval
    let distance: Double
    let pace: Double
}

struct RunProvider: TimelineProvider {
    func placeholder(in: Context) -> RunEntry {
        .init(date: .now, phase: .running, elapsed: 600, distance: 2000, pace: 330)
    }
    func getSnapshot(in: Context, completion: @escaping (RunEntry)->Void) {
        completion(makeEntry())
    }
    func getTimeline(in: Context, completion: @escaping (Timeline<RunEntry>)->Void) {
        let e = makeEntry()
            // 跑步中 30 秒刷新，其他 15 分鐘
        let next = Date().addingTimeInterval(e.phase == .running ? 30 : 900)
        completion(Timeline(entries: [e], policy: .after(next)))
    }
    private func makeEntry() -> RunEntry {
        let s = RunStore.load()
        var elapsed = s.elapsedSec
        if s.phase == .running, let start = s.startDate { elapsed += Date().timeIntervalSince(start) }
        return .init(date: .now,
                     phase: s.phase,
                     elapsed: max(0, elapsed),
                     distance: max(0, s.distanceMeters),
                     pace: max(0, s.paceSecPerKm))
    }
}

struct RunningContentView: View {
    let e: RunEntry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("慢跑").font(.headline)
                Spacer()
                Text(status)
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.thinMaterial).clipShape(Capsule())
            }
            
            if family == .systemSmall {
                Text(tStr(e.elapsed))
                    .font(.system(.title3, design: .rounded))
                    .monospacedDigit()
                HStack { Image(systemName: "speedometer"); Text(paceStr(e.pace)) }
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text("時間").font(.caption2).foregroundStyle(.secondary)
                        Text(tStr(e.elapsed)).font(.title2).monospacedDigit()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("距離").font(.caption2).foregroundStyle(.secondary)
                        Text(String(format: "%.2f km", e.distance/1000)).font(.title3)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("配速").font(.caption2).foregroundStyle(.secondary)
                        Text(paceStr(e.pace)).font(.title3).monospacedDigit()
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var status: String {
        switch e.phase { case .running: "RUN"; case .paused: "PAUSE"; case .idle: "IDLE" }
    }
}

struct RunningWidget: Widget {
    private let kind = "FocusFlowRunning"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RunProvider()) { entry in
            RunningContentView(e: entry)
        }
        .configurationDisplayName("FocusFlow 跑步")
        .description("顯示慢跑時間、距離與配速。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
