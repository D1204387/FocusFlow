    //
    //  FocusFlowWidget.swift
    //  FocusFlowWidgetsExtension
    //
    //  顯示：慢跑狀態、本週累積分鐘、連續天數（無互動）
    //  依賴 Shared/RunningShared.swift（RunStore / RunningState）
    //  App 端請定期寫入：run_weeklyMinutes、run_streakDays 兩個整數到 App Group
    //

import WidgetKit
import SwiftUI

    // 小工具需要的資料
struct RunSummaryEntry: TimelineEntry {
    let date: Date
    let phase: RunningState.Phase
    let weeklyMinutes: Int
    let streakDays: Int
}

    // Provider：讀取 App Group 中的資料，決定刷新頻率
struct RunSummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> RunSummaryEntry {
        RunSummaryEntry(date: .now, phase: .idle, weeklyMinutes: 0, streakDays: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (RunSummaryEntry) -> Void) {
        completion(loadEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<RunSummaryEntry>) -> Void) {
        let entry = loadEntry()
            // 跑步中就 30 秒刷新；否則 30 分鐘
        let next = Date().addingTimeInterval(entry.phase == .running ? 30 : 1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    
    private func loadEntry() -> RunSummaryEntry {
            // 1) 跑步即時狀態（來自 Shared/RunStore）
        let state = RunStore.load()
        
            // 2) 本週分鐘 / 連續天數（請由 App 端更新到 App Group）
        let ud = UserDefaults(suiteName: "group.com.buildwithharry.focusflow")!
        let weekly = ud.integer(forKey: "run_weeklyMinutes")
        let streak = ud.integer(forKey: "run_streakDays")
        
        return RunSummaryEntry(date: .now, phase: state.phase, weeklyMinutes: weekly, streakDays: streak)
    }
}

    // UI：沿用同學的版型
struct FocusFlowWidgetEntryView: View {
    var entry: RunSummaryEntry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                // 標頭
            HStack {
                Image(systemName: "bolt.fill")
                Text("FocusFlow")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.blue)
            .padding(.bottom, 4)
            
                // 內容
            Text("慢跑狀態：\(statusText)")
                .font(.subheadline)
            Text("本週累積：\(entry.weeklyMinutes) 分鐘")
                .font(.subheadline)
            Text("連續天數：\(entry.streakDays) 天")
                .font(.subheadline)
            
            if family != .systemSmall { Spacer() }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var statusText: String {
        switch entry.phase {
        case .running: return "跑步中"
        case .paused:  return "已暫停"
        case .idle:    return "待機"
        }
    }
}

    // 註冊 Widget（注意 kind 要在專案中唯一）
struct FocusFlowWidget: Widget {
    let kind: String = "FocusFlowRunningSummary"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RunSummaryProvider()) { entry in
            FocusFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("跑步摘要")
        .description("顯示慢跑狀態、本週累積與連續天數（無互動）。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

    // 預覽
#Preview(as: .systemSmall) {
    FocusFlowWidget()
} timeline: {
    RunSummaryEntry(date: .now, phase: .idle, weeklyMinutes: 0, streakDays: 0)
    RunSummaryEntry(date: .now, phase: .running, weeklyMinutes: 42, streakDays: 3)
}

