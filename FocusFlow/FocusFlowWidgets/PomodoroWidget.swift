import WidgetKit
import SwiftUI
import AppIntents

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
            guard s.isRunning, let end = s.endDate else {
                print("❌ Widget: 沒有運行或結束時間為空")
                return 0 }
            let remainingTime = max(0, end.timeIntervalSince(now))
            print("⏰ Widget: 剩餘時間 \(Int(remainingTime/60)):\(Int(remainingTime.truncatingRemainder(dividingBy: 60)))")
            return remainingTime
        }()
        
            // 2) ✅ 優先使用 App Group UserDefaults（與 RecordsStore 同步）
        let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow")
        let todayFocusMinutes = userDefaults?.integer(forKey: "todayFocusMinutes") ?? 0
        let todayPomodoroCount = userDefaults?.integer(forKey: "todayPomodoroCount") ?? 0
        
            // ✅ 詳細除錯輸出
        print("🔄 Widget 完整狀態:")
        print("   - 階段: \(s.phase)")
        print("   - 運行中: \(s.isRunning)")
        print("   - 結束時間: \(s.endDate?.description ?? "無")")
        print("   - 剩餘時間: \(Int(remaining))秒")
        print("   - 今日專注: \(todayFocusMinutes)分")
        print("   - 完成次數: \(todayPomodoroCount)次")
                
        return .init(date: now,
                     phase: s.phase,
                     isRunning: s.isRunning,
                     remaining: remaining,
                     focusMinutesToday: todayFocusMinutes,
                     sessionsToday: todayPomodoroCount)
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
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: "timer")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("專注蕃茄")
                    .font(.caption2).fontWeight(.medium)
                    .foregroundStyle(.green)
                Spacer()
            }
            
            Text(statusText)
                .font(.caption2).fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(phaseColor, in: Capsule())
            
            Spacer(minLength: 2)
            
            Text(entry.isRunning ? timeStr(entry.remaining) : "--:--")
                .font(.title2).fontWeight(.bold)
                .foregroundStyle(entry.isRunning ? .green : .secondary)
                .monospacedDigit()
            
            if entry.isRunning {
                ProgressView(value: progress, total: 1)
                    .progressViewStyle(.linear)
                    .tint(.green)
                    .scaleEffect(y: 0.7)
                    .padding(.vertical, 1)
            } else {
                ProgressView(value: 0, total: 1)
                    .progressViewStyle(.linear)
                    .tint(.gray)
                    .scaleEffect(y: 0.7)
                    .padding(.vertical, 1)
            }
            
            Spacer(minLength: 1)
            
            Text("\(entry.focusMinutesToday)分・\(entry.sessionsToday)次")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            
            Spacer(minLength: 0)
        }
        .padding(6)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
        // Medium：左側狀態區 + 右側統計卡
    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: entry.phase == .focus ? "bolt.fill" : "cup.and.saucer")
                        .font(.title3)
                        .foregroundStyle(.green)
                    Text(statusText)
                        .font(.headline).fontWeight(.semibold)
                        .foregroundStyle(phaseColor)
                    Spacer()
                }
                
                Text(entry.isRunning ? timeStr(entry.remaining) : (entry.phase == .focus ? "準備專注" : "準備休息"))
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundStyle(entry.isRunning ?
                        .primary : .secondary)
                    .monospacedDigit()
                
                ProgressView(value: entry.isRunning ? progress : 0, total: 1)
                    .progressViewStyle(.linear)
                    .tint(.green)
                    .scaleEffect(y: 1.2)
                
                Spacer()
            }
            
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8){
                metricCard(title: "今日", value: "\(entry.focusMinutesToday)", unit: "分", icon: "clock.fill")
                metricCard(title: "完成", value: "\(entry.sessionsToday)", unit: "次", icon: "checkmark.circle.fill")
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func metricCard(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.green)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3).fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 60)
        .padding(10)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .overlay(            RoundedRectangle(cornerRadius: 10)
            .stroke(.green.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var statusText: String {
        entry.phase == .focus ? "專注中" : "休息中"
    }
    private var phaseColor: Color {
        entry.phase == .focus ? .green : .orange
    }
    private var progress: Double {
        let total: Double = {
            if entry.phase == .focus {
                return 25*60
            } else {
                return 5*60
            }
        }()
        let r = min(max(entry.remaining, 0), total)
        let progressValue = total == 0 ? 0 : 1 - (r / total)
        
            // ✅ 除錯進度計算
        print("📊 進度計算: 剩餘\(Int(r/60)):\(Int(r.truncatingRemainder(dividingBy: 60))), 總計\(Int(total/60))分, 進度\(Int(progressValue*100))%")
        
        return progressValue
        
    }
}

    // MARK: - Widget 主體宣告
struct PomodoroWidget: Widget {
    let kind: String = "PomodoroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomodoroProvider()) { entry in
            PomodoroView(entry: entry)
        }
        .configurationDisplayName("專注番茄")
        .description("追蹤你的番茄鐘專注狀態。")
        .supportedFamilies([.systemSmall, .systemMedium]) // 支援主畫面 Widget
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
