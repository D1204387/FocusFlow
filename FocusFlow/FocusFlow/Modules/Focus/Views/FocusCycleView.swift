import SwiftUI
import Combine
import SwiftData

    /// 專注（番茄）頁：工作→短休→工作…；每 N 顆進入長休
    /// - 右上角：⚡ 能量
    /// - 中央：分段圓環 + 大時間 + 剩餘 + 完成%
    /// - 顶部：今天幾顆（🍅）、當前模式與分鐘
    /// - 底部：開始/暫停、跳過、重置
struct FocusCycleView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(ModuleCoordinator.self) private var co
    
        // 與 SettingsView 對齊
    @AppStorage("focusMinutes")          private var focusMinutes: Int = 25
    @AppStorage("shortBreakMinutes")     private var shortBreakMinutes: Int = 5
    @AppStorage("longBreakMinutes")      private var longBreakMinutes: Int = 15
    @AppStorage("roundsBeforeLongBreak") private var roundsBeforeLongBreak: Int = 4
    @AppStorage("autoContinue")          private var autoContinue: Bool = true
    
        // 狀態
    enum Phase { case focus, shortBreak, longBreak }
    @State private var phase: Phase = .focus
    @State private var secondsLeft: Int = 25 * 60
    @State private var targetSeconds: Int = 25 * 60
    @State private var cycleCount: Int = 0     // 今日完成顆數
    @State private var isRunning = false
    
        // 計時
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
        // 衍生
    private var elapsed: Int { max(0, targetSeconds - secondsLeft) }
    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        let p = Double(elapsed) / Double(targetSeconds)
        return p < 0 ? 0 : (p > 1 ? 1 : p)
    }
    private var weekdayShort: String {
        let df = DateFormatter(); df.dateFormat = "E"; return df.string(from: Date())
    }
    private var phaseTitle: String {
        switch phase { case .focus: "專注中"; case .shortBreak: "短休中"; case .longBreak: "長休中" }
    }
    private var phaseIcon: String {
        switch phase { case .focus: "timer"; case .shortBreak: "leaf"; case .longBreak: "bed.double" }
    }
    
    var body: some View {
            // 若上層已有 NavigationStack，改成 Group { content } 即可
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
                    pill("🍅 \(weekdayShort) 今天 \(cycleCount) 顆", sf: "record.circle", tint: Theme.Focus.solid)
                    pill("\(phaseTitle.replacingOccurrences(of: "中", with: "")) \(targetSeconds/60) 分鐘",
                         sf: phaseIcon, tint: Theme.Focus.solid)
                    Spacer()
                }
                
                    // 分段圓環 + 時間群
                SegmentedGaugeRing(
                    progress: progress,
                    size: 320,
                    tickCount: 60,
                    tickSize: .init(width: 7, height: 32),
                    innerPadding: 20,
                    active: Theme.Focus.solid,
                    inactive: Color(.systemGray4)
                ) {
                    TimeCluster(
                        elapsed: Int(elapsed),
                        targetSeconds: targetSeconds,
                        title: titleForPhase(phase),   // e.g. 「專注中 / 短休中 / 長休中」
                        accent: colorForPhase(phase)
                    )
                }
                .padding(.top, 6)
                
                    // 當前這顆的設定摘要（你說「下方要顯示這次的設定內容」）
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
        .background(Theme.bg)
        .onAppear { loadPhase(.focus) }
        .onReceive(tick) { _ in countdownIfNeeded() }
    }
    
    private var settingsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("現在：\(phaseTitle)", systemImage: phaseIcon)
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
            // 同一色系做輕微明度變化：專注最飽和、短休次之、長休最淡
        switch p {
        case .focus:      return Theme.Focus.solid
        case .shortBreak: return Theme.Focus.solid.opacity(0.90)
        case .longBreak:  return Theme.Focus.solid.opacity(0.75)
        }
    }
    
    private func iconForPhase(_ p: Phase) -> String {
            // 若你在頂部 pill 仍有用到圖示，保留這個
        switch p {
        case .focus:      return "timer"
        case .shortBreak: return "leaf"
        case .longBreak:  return "bed.double"
        }
    }

}

