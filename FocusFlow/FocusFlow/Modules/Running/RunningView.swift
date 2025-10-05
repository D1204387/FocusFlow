    // Views/RunningView.swift
import SwiftUI
import SwiftData
import Combine
import AudioToolbox

    /// 跑步頁（淺色主題 / 藍色系）
struct RunningView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(ModuleCoordinator.self) private var co
    @Environment(AppSettings.self) private var settings
    
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var showFinishSheet = false
    @State private var startAt: Date?
    @State private var now = Date()
    @State private var accumulated: TimeInterval = 0 // 暫停時的累積秒數
    
    private let tick = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
        // 衍生
    private var elapsed: TimeInterval {
        let runningPart = startAt.map { max(0, now.timeIntervalSince($0))} ?? 0
        return max(0, accumulated + runningPart)
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
                    
                        // 分段進度環
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
                        if isPaused {
                            Button("繼續") {resume()}
                                .buttonStyle(PrimaryButtonStyle(.primary(Theme.Run.solid)))
                            Button("結束"){finish()}
                                .buttonStyle(
                                    PrimaryButtonStyle(.secondary(Theme.Run.solid)
                                                      )
                                )
                        } else if isRunning {
                            Button("結束"){finish()}
                                .buttonStyle(PrimaryButtonStyle(.primary(Theme.Run.solid)))
                            Button("暫停"){pause()}
                                .buttonStyle(PrimaryButtonStyle(.secondary(Theme.Run.solid)))
                        } else {
                            Button("開始"){start()}
                                .buttonStyle(
                                    PrimaryButtonStyle(.primary(Theme.Run.solid)))
                        }
                    }
                    .padding()
                }
                .background(Theme.bg)
                .toolbarEnergy(title: "慢跑時光", tint: Theme.Run.solid)
                .onAppear { AudioService.shared.stopRunSession() }
                .onDisappear { AudioService.shared.stopRunSession() }
                .onReceive(tick) { t in
                    guard isRunning else {return}
                    now = t
                    if elapsed >= Double(targetSeconds) { reachTarget()
                    }}
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
        .sheet(isPresented: $showFinishSheet) {
            CompletionSheet(minutes: targetSeconds / 60, tint: Theme.Run.solid) {
                showFinishSheet = false
                reset()
            }
        }
    }
    
    private var settingsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("目標 \(settings.runTargetMinutes) 分鐘", systemImage: "target")
                .foregroundStyle(Theme.text)
            Label("背景音樂已\(settings.bgmOn ? "開啟" : "關閉")",systemImage:  settings.bgmOn ? "pause.fill" : "play.fill")
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
        accumulated = 0
        isRunning = true
        isPaused = false
        
        AudioService.shared.startRunSession(
            enableMusic: settings.bgmOn,
            enableMetronome: settings.metronomeOn,
            bpm: settings.metronomeBPM,
            haptics: settings.hapticsOn
        )
    }
    
    private func pause() {
        if let s = startAt {
            accumulated += max(0, now.timeIntervalSince(s))
        }
        startAt = nil
        isRunning = false
        isPaused = true
        
        AudioService.shared.stopBGM()
        AudioService.shared.pauseMetronome()
    }
    
    private func resume() {
        startAt = .now
        now = .now
        isRunning = true
        isPaused = false
        
        if settings.bgmOn{AudioService.shared.startBGM()}
        if settings.metronomeOn{AudioService.shared.startMetronome(bpm: settings.metronomeBPM)}
    }
    
    private func finish() {
        isRunning = false
        isPaused = false
        AudioService.shared.stopRunSession()
        
        let sec = elapsed
        guard sec >= 60 else {reset(); return }
        
            // 紀錄 + 加能量
        ctx.insert(RunningRecord(duration: sec))
        co.apply(.runCompleted(minutes: Int(sec / 60)), modelContext: ctx)
        
        showFinishSheet = true // 🎉 顯示完成視窗
    }
    
    private func reset() {
        startAt = nil
        now = .now
        accumulated = 0
        isRunning = false
        isPaused = false
        AudioService.shared.stopRunSession()
    }
    
    private func reachTarget() {
        isRunning = false
        isPaused = false
        AudioService.shared.stopRunSession()
        
        let sec = max(Double(targetSeconds), elapsed)
        
        ctx.insert(RunningRecord(duration: sec))
        co.apply(.runCompleted(minutes: Int(sec / 60)), modelContext: ctx)
        
        if settings.hapticsOn {
            UINotificationFeedbackGenerator().notificationOccurred(.success)}
        
        showFinishSheet = true // 🎉 顯示完成視窗
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

private struct CompletionSheet: View {
    let minutes: Int
    let tint: Color
    var onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(tint)
            Text("完成 \(minutes) 分鐘！")
                .font(.title2).bold()
            Text("太棒了，已幫你記錄並加上能量 ⚡️")
                .foregroundStyle(.secondary)
            Button("好的") { onClose() }
                .buttonStyle(PrimaryButtonStyle(.primary(tint)))
                .padding(.top, 8)
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}

#Preview {
    RunningView()
}

