    // Views/RunningView.swift
import SwiftUI
import SwiftData
import Combine

    /// 跑步頁（淺色主題 / 藍色系）
struct RunningView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(ModuleCoordinator.self) private var co
    
        // 與 SettingsView 的 key 一致
    @AppStorage(FFKey.runTargetMinutes) private var runTargetMinutes: Int = 20
    @AppStorage(FFKey.bgmOn)            private var bgmOn: Bool = true
    @AppStorage(FFKey.metronomeOn)      private var metronomeOn: Bool = true
    @AppStorage(FFKey.metronomeBPM)     private var metronomeBPM: Int = 180
    @AppStorage(FFKey.hapticsOn)        private var hapticsOn: Bool = true
    @AppStorage("enableMusic")     private var enableMusic: Bool = true
    @AppStorage("enableMetronome") private var enableMetronome: Bool = true

    @AppStorage("enableHaptics")   private var enableHaptics: Bool = true
    
    @State private var isRunning = false
    @State private var startAt: Date?
    @State private var now = Date()
    
        // 讓進度更順
    private let tick = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
        // 衍生
    private var elapsed: TimeInterval {
        guard let s = startAt else { return 0 }
        return max(0, now.timeIntervalSince(s))
    }
    private var targetSeconds: Int { max(1, runTargetMinutes) * 60 }
    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(1, elapsed / Double(targetSeconds))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    
                        // 統計 pill（示意數字）
                    HStack(spacing: 10) {
                        pill("連續 7 天", sf: "flame.fill", tint: Theme.Run.solid)
                        pill("本週 85 分鐘", sf: "clock.badge.checkmark", tint: Theme.Run.solid)
                        Spacer()
                    }
                    
                        // 分段圓環 + 時間群
                    SegmentedGaugeRing(
                        progress: progress,
                        size: 320,
                        tickCount: 60,
                        tickSize: .init(width: 7, height: 32),
                        innerPadding: 20,
                        active: Theme.Run.solid,
                        inactive: Color(.systemGray4)
                    ) {
                        TimeCluster(
                            elapsed: Int(elapsed),          // ⬅️ 傳 Int（秒）
                            targetSeconds: targetSeconds,
                            accent: Theme.Run.solid
                        )
                    }
                    .padding(.top, 6)
                    
                        // 中段資訊列：目標時間 / 音樂 / 節拍器
                    InfoStrip(icon: "target", text: "目標 \(runTargetMinutes) 分鐘")
                    InfoStrip(icon: enableMusic ? "pause.fill" : "play.fill",
                              text: "背景音樂已\(enableMusic ? "開啟" : "關閉")")
                    InfoStrip(icon: "metronome.fill",
                              text: "BPM \(metronomeBPM)  節拍\(enableMetronome ? "開啟" : "關閉")")
                    
                        // 操作按鈕（主/次一致風格）
                    HStack(spacing: 12) {
                        Button(isRunning ? "結束" : "開始") { isRunning ? finish() : start() }
                            .buttonStyle(PrimaryButtonStyle(.primary(Theme.Run.solid)))
                        
                        if isRunning {
                            Button("暫停") { pause() }
                                .buttonStyle(PrimaryButtonStyle(.secondary(Theme.Run.solid)))
                            Button("重置") { reset() }
                                .buttonStyle(PrimaryButtonStyle(.secondary(Theme.Run.solid)))
                        }
                    }
                }
                .padding()
            }
            .background(Theme.bg)
            .toolbarEnergy(title: "慢跑時光", tint: Theme.Run.solid) // ⬅️ 統一用共用 Toolbar
            .onAppear { AudioService.shared.stopRunSession() }     // 防止一進頁就播
            .onDisappear { AudioService.shared.stopRunSession() }  // 離頁一定關閉
            .onReceive(tick) { t in if isRunning { now = t } }
            
                // 只有在「跑步進行中」才會套用設定變更
            .onChange(of: metronomeBPM) { _, v in
                if isRunning, enableMetronome { AudioService.shared.setBPM(v) }
            }
            .onChange(of: enableMetronome) { _, on in
                guard isRunning else { return }
                on ? AudioService.shared.startMetronome(bpm: metronomeBPM)
                : AudioService.shared.stopMetronome()
            }
            .onChange(of: enableMusic) { _, on in
                guard isRunning else { return }
                on ? AudioService.shared.startBGM()
                : AudioService.shared.stopBGM()
            }
        }
    }
    
        // MARK: - Actions
    private func start() {
        startAt = .now
        now = .now
        isRunning = true

        AudioService.shared.startRunSession(
            enableMusic: bgmOn,
            enableMetronome: metronomeOn,
            bpm: metronomeBPM,
            haptics: hapticsOn
        )
    }
    
    private func pause() {
        isRunning = false
        AudioService.shared.pauseMetronome() // 音樂保持原狀，節拍器暫停即可
    }
    
    private func finish() {
        isRunning = false
        let sec = elapsed
        guard sec >= 60 else { reset(); return }
        
            // 紀錄 + 加能量
        ctx.insert(RunningRecord(duration: sec))
        co.apply(.runCompleted(minutes: Int(sec / 60)), modelContext: ctx)
        
        reset()
    }
    
    private func reset() {
        startAt = nil
        now = .now
        isRunning = false
        AudioService.shared.stopRunSession()
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
}

    // 純資訊條（白底、輕陰影）
private struct InfoStrip: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text).font(.subheadline)
            Spacer()
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .softShadow()
    }
}
