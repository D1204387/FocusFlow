    // Views/RunningView.swift
import SwiftUI
import SwiftData
import Combine
import UIKit
import Charts

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
    @Query(sort: \RunningRecord.date, order: .reverse) private var runs: [RunningRecord]
    
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
                        pill("連續 \(streakDays) 天", sf: "flame.fill", tint: Theme.Run.solid)
                        pill("本週 \(weeklyMinutes) 分鐘", sf: "clock.badge.checkmark", tint: Theme.Run.solid)
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
                        // 本週完成狀態卡片（圖表）
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("本週完成狀態")
                                .font(.headline)
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Text("\(weeklyPercent)%")
                                .font(.headline.bold())
                                .foregroundStyle(Theme.Run.solid)
                        }
                        
                        Chart(weekDays.map { day in
                            DayPoint(date: day, minutes: minutesByDay[Calendar.current.startOfDay(for: day)] ?? 0)
                        }) { p in
                            BarMark(
                                x: .value("日期", p.date, unit: .day),
                                y: .value("分鐘", p.minutes)
                            )
                            .foregroundStyle(Theme.Run.solid)
                            .cornerRadius(6)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { v in
                                AxisGridLine().foregroundStyle(.clear)
                                AxisTick().foregroundStyle(.clear)
                                if let d = v.as(Date.self) {
                                    AxisValueLabel {
                                        Text(d, format: .dateTime.weekday(.narrow)) // 一、二、三…
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(Theme.cardStroke)
                                AxisValueLabel()
                            }
                        }
                        .frame(height: 200)
                    }
                    .padding(16)
                    .background(Theme.bg)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardStroke))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .softShadow()
                    
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
    
        // 當週區間（依系統地區決定週起始）
    private var weekInterval: DateInterval {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
    }
    
        // 本週所有日期（7 天）
    private var weekDays: [Date] {
        let start = Calendar.current.startOfDay(for: weekInterval.start)
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }
    
        // 本週的所有跑步紀錄
    private var runsThisWeek: [RunningRecord] {
        runs.filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }
    }
    
        // 本週總分鐘數
    private var weeklyMinutes: Int {
        Int(runsThisWeek.reduce(0) { $0 + $1.duration } / 60)
    }
    
        // 每日分鐘（用於圖表）
    private var minutesByDay: [Date: Double] {
        var map: [Date: Double] = [:]
        for r in runsThisWeek {
            let day = Calendar.current.startOfDay(for: r.date)
            map[day, default: 0] += r.duration / 60
        }
        return map
    }
    
        // 本週完成百分比 = 本週分鐘 / (每天目標 * 7)
    private var weeklyPercent: Int {
        let denom = max(1, settings.runTargetMinutes * 7)
        let pct = (Double(weeklyMinutes) / Double(denom)) * 100
        return min(100, max(0, Int(round(pct))))
    }
    
        // 連續天數（從今天開始往回數，一天有任意跑步即算 1）
    private var streakDays: Int {
        let daysWithRun: Set<Date> = Set(
            runs.map { Calendar.current.startOfDay(for: $0.date) }
        )
        var c = 0
        var d = Calendar.current.startOfDay(for: Date())
        while daysWithRun.contains(d) {
            c += 1
            d = Calendar.current.date(byAdding: .day, value: -1, to: d)!
        }
        return c
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
private struct DayPoint: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Double
}


#Preview("Running • 1 分鐘示範") {
        // In-memory SwiftData 容器（不落地）
    let schema = Schema([RunningRecord.self, PomodoroRecord.self, GameRecord.self])
    let container = try! ModelContainer(
        for: schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
        // 環境物件
    let co = ModuleCoordinator()
    co.energy = 2
    
    let settings = AppSettings.shared
    settings.runTargetMinutes = 1       // 預覽好測
    settings.bgmOn = false              // 預設關掉，避免預覽時誤播
    settings.metronomeOn = false
    settings.metronomeBPM = 180
    settings.hapticsOn = true
    
    return RunningView()
        .environment(co)
        .environment(settings)
        .modelContainer(container)
        .preferredColorScheme(.light)
}

#Preview("Running • 預設 20 分鐘") {
    let schema = Schema([RunningRecord.self, PomodoroRecord.self, GameRecord.self])
    let container = try! ModelContainer(
        for: schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let co = ModuleCoordinator()
    co.energy = 5
    
    let settings = AppSettings.shared
    settings.runTargetMinutes = 20
    settings.bgmOn = false
    settings.metronomeOn = false
    settings.metronomeBPM = 180
    settings.hapticsOn = true
    
    return RunningView()
        .environment(co)
        .environment(settings)
        .modelContainer(container)
        .preferredColorScheme(.light)
}

