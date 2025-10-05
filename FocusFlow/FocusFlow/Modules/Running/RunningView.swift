    // Views/RunningView.swift
import SwiftUI
import SwiftData
import Combine

    /// 跑步頁（淺色主題 / 藍色系）
struct RunningView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(ModuleCoordinator.self) private var co
    @Environment(AppSettings.self) private var settings

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
    private var targetSeconds: Int { max(1, settings.runTargetMinutes) * 60 }
    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(1, Double(elapsed) / Double(targetSeconds))
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
                    
                        // 分段進度環 + 時間群（60 刻度、12 點起點）
                    SegmentedGaugeRing(
                        progress: progress,
                        size: 320,
                        tickCount: 60,
                        tickSize: .init(width: 8, height: 34),
                        innerPadding: 18,
                        active: Theme.Run.solid,
                        inactive: Color(.systemGray4)
                    ) {
                        TimeCluster(
                            elapsed: Int(elapsed),
                            targetSeconds: targetSeconds,
                            accent: Theme.Run.solid
                        )
                    }
                    .padding(.top, 6)
                    settingsSummary
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
            .toolbarEnergy(title: "慢跑時光", tint: Theme.Run.solid)
            
            .onAppear { AudioService.shared.stopRunSession() }
            .onDisappear { AudioService.shared.stopRunSession() }
            
                // 計時更新
            .onReceive(tick) { t in if isRunning { now = t } }
            
                // 設定變更 → 僅在「跑步中」才作用到音訊
            .onChange(of: settings.metronomeBPM) { _, v in
                if isRunning, settings.metronomeOn { AudioService.shared.setBPM(v) }
            }
            .onChange(of: settings.metronomeOn) { _, on in
                guard isRunning else { return }
                on ? AudioService.shared.startMetronome(bpm: settings.metronomeBPM)
                : AudioService.shared.stopMetronome()
            }
            .onChange(of: settings.bgmOn) { _, on in
                guard isRunning else { return }
                on ? AudioService.shared.startBGM()
                : AudioService.shared.stopBGM()
            }
        }
        
    }
    
    private var settingsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("目標 \(settings.runTargetMinutes) 分鐘", systemImage: "target")
                .foregroundStyle(Theme.text)
            Label(            "背景音樂已\(settings.bgmOn ? "開啟" : "關閉")",
                              systemImage:  settings.bgmOn ? "pause.fill" : "play.fill")
            .foregroundStyle(Theme.text)
            Label("BPM \(settings.metronomeBPM)  節拍\(settings.metronomeOn ? "開啟" : "關閉")", systemImage: "metronome.fill")
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
    
        // MARK: - Actions
    private func start() {
        startAt = .now
        now = .now
        isRunning = true
        
        AudioService.shared.startRunSession(
            enableMusic: settings.bgmOn,
            enableMetronome: settings.metronomeOn,
            bpm: settings.metronomeBPM,
            haptics: settings.hapticsOn
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

