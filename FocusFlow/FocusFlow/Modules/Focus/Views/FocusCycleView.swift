import SwiftUI
import Combine
import SwiftData

struct FocusCycleView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(ModuleCoordinator.self) private var co
    
        // 與 SettingsView 對齊（統一用 FFKey）
    @AppStorage(FFKey.focusMinutes)          private var focusMinutes: Int = 25
    @AppStorage(FFKey.shortBreakMinutes)     private var shortBreakMinutes: Int = 5
    @AppStorage(FFKey.longBreakMinutes)      private var longBreakMinutes: Int = 15
    @AppStorage(FFKey.roundsBeforeLongBreak) private var roundsBeforeLongBreak: Int = 4
    @AppStorage(FFKey.autoContinue)          private var autoContinue: Bool = true
    
        // 狀態
    enum Phase { case focus, shortBreak, longBreak }
    @State private var phase: Phase = .focus
    @State private var secondsLeft: Int = 25 * 60
    @State private var targetSeconds: Int = 25 * 60
    @State private var cycleCount: Int = 0
    @State private var isRunning = false
    
        // 計時
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
        // 衍生
    private var elapsed: Int { max(0, targetSeconds - secondsLeft) }
    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return max(0, min(1, Double(elapsed) / Double(targetSeconds)))
    }
    private var weekdayShort: String {
        let df = DateFormatter(); df.dateFormat = "E"; return df.string(from: Date())
    }
    
    var body: some View {
        NavigationStack {
            content
                .background(Theme.bg)
                .toolbarEnergy(title: "專注番茄", tint: Theme.Focus.solid)
        }
    }
    
        // MARK: - 主內容
    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                
                    // 頂部統計
                HStack(spacing: 10) {
                    pill("🍅 \(weekdayShort) 今天 \(cycleCount) 顆",
                         sf: "record.circle",
                         tint: Theme.Focus.solid)
                    pill("\(titleForPhase(phase).replacingOccurrences(of: "中", with: "")) \(targetSeconds/60) 分鐘",
                         sf: iconForPhase(phase),
                         tint: Theme.Focus.solid)
                    Spacer()
                }
                
                    // 分段進度環 + 時間群（60 刻度、12 點起點）
                SegmentedGaugeRing(
                    progress: progress,
                    size: 320,
                    tickCount: 60,
                    tickSize: .init(width: 8, height: 34),
                    innerPadding: 18,
                    active: colorForPhase(phase),
                    inactive: Color(.systemGray4)
                ) {
                    VStack(spacing: 6) {
                        Text(titleForPhase(phase))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        TimeCluster(
                            elapsed: elapsed,
                            targetSeconds: targetSeconds,
                            accent: colorForPhase(phase)
                        )
                    }
                }
                .padding(.top, 6)
                
                    // 當前這顆的設定摘要
                settingsSummary
                    .padding(.top, 4)
                
                    // 控制按鈕
                HStack(spacing: 12) {
                    Button(isRunning ? "暫停" : "開始") { isRunning ? pause() : start() }
                        .buttonStyle(PrimaryButtonStyle(.primary(Theme.Focus.solid)))
                    Button("跳過") { skipPhase() }
                        .buttonStyle(PrimaryButtonStyle(.secondary(Theme.Focus.solid)))
                    Button("重置") { resetAll() }
                        .buttonStyle(PrimaryButtonStyle(.secondary(Theme.Focus.solid)))
                }
            }
            .padding()
        }
        .onAppear { loadPhase(.focus) }
        .onReceive(tick) { _ in countdownIfNeeded() }
    }
    
    private var settingsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("現在：\(titleForPhase(phase))", systemImage: iconForPhase(phase))
                .foregroundStyle(Theme.text)
            Label("本次設定：專注 \(focusMinutes) 分 • 短休 \(shortBreakMinutes) 分 • 長休 \(longBreakMinutes) 分",
                  systemImage: "gearshape")
            .foregroundStyle(Theme.text)
            Label("每 \(roundsBeforeLongBreak) 顆進入長休", systemImage: "record.circle")
                .foregroundStyle(Theme.text)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .softShadow()
    }
    
        // MARK: - 行為
    private func start() { isRunning = true }
    private func pause() { isRunning = false }
    
    private func resetAll() {
        isRunning = false
        cycleCount = 0
        loadPhase(.focus)
    }
    
    private func skipPhase() {
        isRunning = false
        nextPhase(completedFocus: phase == .focus)
    }
    
    private func countdownIfNeeded() {
        guard isRunning else { return }
        if secondsLeft > 0 {
            secondsLeft -= 1
        } else {
            isRunning = false
            let completedFocus = (phase == .focus)
            if completedFocus {
                cycleCount += 1
                co.apply(.pomodoroCompleted(
                    focus: focusMinutes,
                    rest: currentRestMinutes()
                ), modelContext: ctx)
            }
            nextPhase(completedFocus: completedFocus)
        }
    }
    
    private func nextPhase(completedFocus: Bool) {
        if completedFocus {
            if cycleCount > 0, cycleCount % max(1, roundsBeforeLongBreak) == 0 {
                loadPhase(.longBreak)
            } else {
                loadPhase(.shortBreak)
            }
        } else {
            loadPhase(.focus)
        }
        if autoContinue { isRunning = true }
    }
    
    private func loadPhase(_ p: Phase) {
        phase = p
        switch p {
        case .focus:      targetSeconds = max(1, focusMinutes) * 60
        case .shortBreak: targetSeconds = max(1, shortBreakMinutes) * 60
        case .longBreak:  targetSeconds = max(1, longBreakMinutes) * 60
        }
        secondsLeft = targetSeconds
    }
    
    private func currentRestMinutes() -> Int {
        switch phase {
        case .shortBreak: return shortBreakMinutes
        case .longBreak:  return longBreakMinutes
        default:          return 0
        }
    }
    
        // MARK: - 小元件
    private func pill(_ text: String, sf: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: sf).imageScale(.small).foregroundStyle(tint)
            Text(text).font(.subheadline).foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.pillBG)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.cardStroke, lineWidth: 1))
    }
    
        // MARK: - Phase helpers
    private func titleForPhase(_ p: Phase) -> String {
        switch p {
        case .focus:      return "專注中"
        case .shortBreak: return "短休中"
        case .longBreak:  return "長休中"
        }
    }
    
    private func colorForPhase(_ p: Phase) -> Color {
        switch p {
        case .focus:      return Theme.Focus.solid
        case .shortBreak: return Theme.Focus.solid.opacity(0.90)
        case .longBreak:  return Theme.Focus.solid.opacity(0.75)
        }
    }
    
    private func iconForPhase(_ p: Phase) -> String {
        switch p {
        case .focus:      return "timer"
        case .shortBreak: return "leaf"
        case .longBreak:  return "bed.double"
        }
    }
}

