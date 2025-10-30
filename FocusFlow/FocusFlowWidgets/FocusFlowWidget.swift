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
    let todayMinutes: Int
}

struct RunSummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> RunSummaryEntry {
        .init(date: .now, phase: .idle, weeklyMinutes: 0, streakDays: 0, todayMinutes: 0)
    }
    func getSnapshot(in context: Context, completion: @escaping (RunSummaryEntry) -> Void) {
        completion(loadEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<RunSummaryEntry>) -> Void) {
        let entry = loadEntry()
        
            // ✅ 修正：根據狀態調整更新頻率
        let updateInterval: TimeInterval
        switch entry.phase {
        case .running:
            updateInterval = 10 // 跑步中每 10 秒更新
        case .paused:
            updateInterval = 30 // 暫停時每 30 秒更新
        case .idle:
            updateInterval = 300 // 待機時每 5 分鐘更新
        }
        
        let nextUpdate = Calendar.current.date(
            byAdding: .second,
            value: Int(updateInterval),
            to: Date()) ?? Date()
        
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    private func loadEntry() -> RunSummaryEntry {
        
        let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow")
        
        var phase: RunningState.Phase = .idle
        if let phaseData = userDefaults?.data(forKey: "currentRunningPhase"),
           let decodedPhase = try? JSONDecoder().decode(
            RunningState.Phase.self,
            from: phaseData) {
            phase = decodedPhase
        }
        
        let todayMinutes = userDefaults?.integer(forKey: "todayMinutes") ?? 0
        let weeklyMinutes = userDefaults?.integer(forKey: "weekRunMinutes") ?? 0
        let streakDays = userDefaults?.integer(forKey: "streakDays") ?? 0
        
            // ✅ 除錯：印出讀取的資料
        print("📊 Widget 載入資料:")
        print("  Phase: \(phase)")
        print("  Today: \(todayMinutes) 分")
        print("  Weekly: \(weeklyMinutes) 分")
        print("  Streak: \(streakDays) 天")
        
        return .init(
            date: .now,
            phase: phase,
            weeklyMinutes: weeklyMinutes,
            streakDays: streakDays,
            todayMinutes: todayMinutes
        )
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text("跑步統計")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                    // ✅ 新增：重新整理按鈕
                Button(intent: RefreshWidgetIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                    // Status indicator
                Circle()
                    .fill(phaseColor)
                    .frame(width: 5, height: 5)
            }
                // Status text
            Text(statusText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(phaseColor)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(phaseColor.opacity(0.1), in: Capsule())
            
            Spacer(minLength: 2)
            
            // Stats
            VStack(alignment: .leading, spacing: 3) {
                StatRow(icon: "clock.fill", label: "今日", value: "\(entry.todayMinutes)", unit: "分")
                StatRow(icon: "calendar", label: "本週", value: "\(entry.weeklyMinutes)", unit: "分")
                StatRow(icon: "flame.fill", label: "連續", value: "\(entry.streakDays)", unit: "天")
            }
            
            Spacer(minLength: 0)
        }
        .padding(8)
        .containerBackground(.regularMaterial, for: .widget)
    }
    
        // MARK: - Medium
    private var mediumView: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("跑步統計")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(phaseColor)
                                .frame(width: 4, height: 4)
                            
                            Text(statusText)
                                .font(.caption2)
                                .foregroundStyle(phaseColor)
                        }
                    }
                    
                    Spacer()
                        // ✅ 新增：重新整理按鈕
                    Button(intent: RefreshWidgetIntent()) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Text(subtitleText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日表現")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        
                        Text("\(entry.todayMinutes) 分")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            
            // 卡片
            VStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text("本週")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                
                    Text("\(entry.weeklyMinutes)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    
                    Text("分鐘")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                        
                 VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("連續")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("\(entry.streakDays)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    
                    Text("天")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
            }
            .frame(width: 70)
        }
        .padding(10)
        .containerBackground(.regularMaterial, for: .widget)
    }
                  
    private struct StatRow: View {
        let icon: String
        let label: String
        let value: String
        let unit: String
        
        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .frame(width: 10)
                
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 1) {
                    Text(value)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .monospacedDigit()
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
        // 文字與顏色
    private var statusText: String {
        switch entry.phase {
        case .running: "跑步中"
        case .paused: "暫停"
        case .idle: "待機"
        }
    }
    
    private var subtitleText: String {
        switch entry.phase {
        case .running: "保持配速！"
        case .paused:  "點按繼續"
        case .idle:    "開始運動？"
        }
    }
    
    private var phaseColor: Color {
        switch entry.phase {
        case .running: .green
        case .paused: .orange
        case .idle: .blue
        }
    }
}

struct FocusFlowWidget: Widget {
    private let kind = "FocusFlowRunningSummary"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RunSummaryProvider()) { entry in
            FocusFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("跑步統計")
        .description("顯示跑步狀態、今日與本週累積數據。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

    // MARK: - Previews
#Preview(as: .systemSmall) {
    FocusFlowWidget()
} timeline: {
    RunSummaryEntry(date: .now, phase: .running, weeklyMinutes: 42, streakDays: 3, todayMinutes: 10)
    RunSummaryEntry(date: .now, phase: .idle,    weeklyMinutes: 0,  streakDays: 0, todayMinutes: 0)
}

#Preview(as: .systemMedium) {
    FocusFlowWidget()
} timeline: {
    RunSummaryEntry(date: .now, phase: .paused,  weeklyMinutes: 18, streakDays: 5, todayMinutes: 5)
    RunSummaryEntry(date: .now, phase: .running, weeklyMinutes: 60, streakDays: 10, todayMinutes: 30)
}
