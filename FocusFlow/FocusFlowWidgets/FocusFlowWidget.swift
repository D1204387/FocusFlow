import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget 主要資料結構與 Provider
// RunSummaryEntry: 跑步摘要資料
// RunSummaryProvider: 提供 Widget Timeline 資料
// FocusFlowWidgetEntryView: 根據 Widget 大小顯示不同內容

struct RunSummaryEntry: TimelineEntry {
    let date: Date
    let phase: RunningState.Phase
    let weeklyMinutes: Int
    let streakDays: Int
}

struct RunSummaryProvider: TimelineProvider {
    func placeholder(in: Context) -> RunSummaryEntry {
        .init(date: .now, phase: .idle, weeklyMinutes: 0, streakDays: 0)
    }
    func getSnapshot(in: Context, completion: @escaping (RunSummaryEntry)->Void) {
        completion(loadEntry())
    }
    func getTimeline(in: Context, completion: @escaping (Timeline<RunSummaryEntry>)->Void) {
        let e = loadEntry()
        completion(Timeline(entries: [e], policy: .atEnd))
    }
    private func loadEntry() -> RunSummaryEntry {
        let phase = RunStore.load().phase
        let (weekly, streak) = WidgetDataManager.shared.computeRunSummary()
        return .init(date: .now, phase: phase, weeklyMinutes: weekly, streakDays: streak)
    }
}

// MARK: - Small/Medium Widget 畫面
struct FocusFlowWidgetEntryView: View {
    let entry: RunSummaryEntry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        switch family {
        case .systemSmall: smallView
        default: mediumView
        }
    }
    
        // MARK: - Small
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                Text("FocusFlow")
                    .font(.subheadline).fontWeight(.semibold)
                    .lineLimit(1)
            }
            .foregroundStyle(.blue)
            
            Text(statusText)
                .font(.title3).fontWeight(.bold)
                .foregroundStyle(phaseColor)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(phaseColor.opacity(0.12), in: Capsule())
            
            HStack {
                Image(systemName: "clock.badge.checkmark")
                Text("\(entry.weeklyMinutes) 分").monospacedDigit()
                Spacer()
            }
            .font(.footnote)
            
            HStack {
                Image(systemName: "flame.fill")
                Text("\(entry.streakDays) 天").monospacedDigit()
                Spacer()
            }
            .font(.footnote)
            
            // 將原本的 AppIntentButton 移除，改為普通 Button 或直接移除
            Button(action: {
                // 這裡不能直接觸發 AppIntent，只能打開 App 或顯示提示
            }) {
                Label("手動記錄跑步", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: CGFloat.infinity) // 明確指定型別
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
        // MARK: - Medium
    private var mediumView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.run")
                    Text(statusText)
                        .font(.headline).fontWeight(.semibold)
                        .foregroundStyle(phaseColor)
                }
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Spacer()
            
            metricCard(title: "本週", value: "\(entry.weeklyMinutes)", unit: "分", icon: "clock.badge.checkmark")
            metricCard(title: "連續", value: "\(entry.streakDays)", unit: "天", icon: "flame.fill")
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
        // 小卡片
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
    
        // 文字與顏色
    private var statusText: String {
        switch entry.phase { case .running: "跑步中"; case .paused: "暫停"; case .idle: "待機" }
    }
    private var subtitleText: String {
        switch entry.phase {
        case .running: "保持配速，加油！"
        case .paused:  "點按繼續於 App"
        case .idle:    "今天動一動？"
        }
    }
    private var phaseColor: Color {
        switch entry.phase { case .running: .green; case .paused: .orange; case .idle: .gray }
    }
}

struct FocusFlowWidget: Widget {
    private let kind = "FocusFlowRunningSummary"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RunSummaryProvider()) { entry in
            FocusFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("跑步摘要")
        .description("顯示慢跑狀態、本週累積與連續天數。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

    // MARK: - Previews
#Preview(as: .systemSmall) {
    FocusFlowWidget()
} timeline: {
    RunSummaryEntry(date: .now, phase: .running, weeklyMinutes: 42, streakDays: 3)
    RunSummaryEntry(date: .now, phase: .idle,    weeklyMinutes: 0,  streakDays: 0)
}

#Preview(as: .systemMedium) {
    FocusFlowWidget()
} timeline: {
    RunSummaryEntry(date: .now, phase: .paused,  weeklyMinutes: 18, streakDays: 5)
    RunSummaryEntry(date: .now, phase: .running, weeklyMinutes: 60, streakDays: 10)
}
