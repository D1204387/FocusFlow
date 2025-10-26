import SwiftUI
import Combine
import SwiftData
import Charts

struct FocusCycleView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(ModuleCoordinator.self) private var co
    @Environment(AppSettings.self) private var settings
    
    
        // MARK: - 狀態
        // phase: 當前階段（專注、短休、長休）
        // secondsLeft: 剩餘秒數
        // targetSeconds: 目標秒數
        // cycleCount: 已完成的番茄數
        // isRunning: 計時器是否運行中
        // showAddTask: 是否顯示新增任務視窗
        // currentTask: 當前任務
        // tasks: 任務列表
        // showFinishSheet: 是否顯示完成提示
        // finishedTask: 剛完成的任務
    enum Phase { case focus, shortBreak, longBreak }
    @State private var phase: Phase = .focus
    @State private var secondsLeft: Int = 25 * 60
    @State private var targetSeconds: Int = 25 * 60
    @State private var cycleCount: Int = 0
    @State private var isRunning = false
    @State private var showAddTask = false
    @State private var currentTask: TaskModel? = nil
    @State private var tasks: [TaskModel] = []
    @State private var showFinishSheet = false
    @State private var finishedTask: TaskModel? = nil
    
        // MARK: - 計時
        // tick: 每秒觸發一次的計時器
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
        // MARK: - 衍生
        // elapsed: 已經過的秒數
        // progress: 當前進度（0~1）
        // weekdayShort: 今天是星期幾（短格式）
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
        .sheet(isPresented: $showFinishSheet) {
            CompletionSheet(task: finishedTask, tint: Theme.Focus.solid) {
                showFinishSheet = false
                finishedTask = nil
                // 關閉完成提示後才進入下一階段
                nextPhase(completedFocus: true)
            }
        }
    }
    
        // MARK: - 主內容
        // content: 主畫面內容
    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                
                    // 頂部統計
                HStack(spacing: 10) {
                    InfoChip("🍅 \(weekdayShort) 今天 \(cycleCount) 顆",
                             icon: "record.circle",
                             tint: Theme.Focus.solid)
                    InfoChip("\(phaseLabel(phase)) 剩餘 \(max(0, secondsLeft / 60)) 分",
                             icon: iconForPhase(phase),
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
                    startAngle: .degrees(0), // 從3點鐘方向開始
                    active: colorForPhase(phase),
                    inactive: Color(.systemGray4)
                ) {
                    VStack(spacing: 6) {
                        Text(currentTask?.name ?? titleForPhase(phase))
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
                
                    // 新增任務按鈕移到時鐘下方
                Button(action: { showAddTask = true }) {
                    Text("新增任務 +")
                        .foregroundStyle(.black)
                }
                .buttonStyle(PrimaryButtonStyle(.tertiary(Theme.Focus.solid)))
                
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
                    // 任務紀錄列表移到控制按鈕下方，並加上完成打勾圖案
                if !tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("任務紀錄")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        ForEach(tasks) { task in
                            HStack {
                                Text(task.name)
                                    .font(.body)
                                Spacer()
                                Text(String(format: "%02d:%02d", task.minutes, task.seconds))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    // 完成打勾圖案
                                if task.isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                            // 新增長條圖
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("本週完成狀態")
                                    .font(.headline)
                                    .foregroundStyle(Theme.text)
                                Spacer()
                                Text("\(weeklyPercent)%")
                                    .font(.headline.bold())
                                    .foregroundStyle(Theme.Focus.solid)
                            }
                            Chart(weekDays.map { day in
                                DayPoint(date: day, count: pomodorosByDay[Calendar.current.startOfDay(for: day)] ?? 0)
                            }) { p in
                                BarMark(
                                    x: .value("日期", p.date, unit: .day),
                                    y: .value("番茄數", p.count)
                                )
                                .foregroundStyle(Theme.Focus.solid)
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
                            .frame(height: 120)
                        }
                        .padding(16)
                        .background(Theme.bg)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardStroke))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .softShadow()
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView { task in
                currentTask = task
                tasks.append(task)
                phase = .focus
                targetSeconds = task.totalSeconds
                secondsLeft = task.totalSeconds
            }
        }
        .onAppear { loadPhase(.focus) }
        .onReceive(tick) { _ in countdownIfNeeded() }
        .onChange(of: settings.focusMinutes) { _, _ in
            guard !isRunning, phase == .focus else { return }
            loadPhase(.focus)
        }
        .onChange(of: settings.shortBreakMinutes) { _, _ in
            guard !isRunning, phase == .shortBreak else { return }
            loadPhase(.shortBreak)
        }
        .onChange(of: settings.longBreakMinutes) { _, _ in
            guard !isRunning, phase == .longBreak else { return }
            loadPhase(.longBreak)
        }
        
    }
    
    private var settingsSummary: some View {
        StatusSummaryCard {
            Label("現在：\(titleForPhase(phase))", systemImage: iconForPhase(phase))
                .foregroundStyle(Theme.text)
            Label("本次設定：專注 \(settings.focusMinutes) 分 • 短休 \(settings.shortBreakMinutes) 分 • 長休 \(settings.longBreakMinutes) 分",
                  systemImage: "gearshape")
            .foregroundStyle(Theme.text)
            Label("每 \(settings.roundsBeforeLongBreak) 顆進入長休", systemImage: "record.circle")
                .foregroundStyle(Theme.text)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .softShadow()
    }
    
        // MARK: - 行為
        // start: 開始計時
        // pause: 暫停計時
        // resetAll: 重置所有狀態
        // skipPhase: 跳過當前階段
        // countdownIfNeeded: 倒數計時
        // nextPhase: 進入下一階段
        // loadPhase: 載入指定階段
        // currentRestMinutes: 取得當前休息分鐘數
    private func start() {
        isRunning = true
            // 若有任務，啟動時用任務時間
        if let task = currentTask {
            targetSeconds = task.totalSeconds
            secondsLeft = task.totalSeconds
        }
    }
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
                ctx.insert(PomodoroRecord(date: .now, focus: targetSeconds / 60, rest: currentRestMinutes()))
                co.apply(.pomodoroCompleted(
                    focus: settings.focusMinutes,
                    rest: currentRestMinutes()
                ), modelContext: ctx)
                // 標記 currentTask 為完成
                if let currentId = currentTask?.id, let idx = tasks.firstIndex(where: { $0.id == currentId }) {
                    tasks[idx].isCompleted = true
                    finishedTask = tasks[idx]
                    showFinishSheet = true // 顯示完成提示
                    return // 完成任務時暫停，不自動進入下一階段
                }
            }
            nextPhase(completedFocus: completedFocus)
        }
    }
    
    private func nextPhase(completedFocus: Bool) {
        if completedFocus {
            if cycleCount > 0, cycleCount % max(1, settings.roundsBeforeLongBreak) == 0 {
                loadPhase(.longBreak)
            } else {
                loadPhase(.shortBreak)
            }
        } else {
            loadPhase(.focus)
        }
        // 進入新階段時一律暫停，需手動按開始
        isRunning = false
    }
    
    private func loadPhase(_ p: Phase) {
        phase = p
        switch p {
        case .focus:      targetSeconds = max(1, settings.focusMinutes) * 60
        case .shortBreak: targetSeconds = max(1, settings.shortBreakMinutes) * 60
        case .longBreak:  targetSeconds = max(1, settings.longBreakMinutes) * 60
        }
        secondsLeft = targetSeconds
    }
    
    private func currentRestMinutes() -> Int {
        switch phase {
        case .shortBreak: return settings.shortBreakMinutes
        case .longBreak:  return settings.longBreakMinutes
        default:          return 0
        }
    }
    
        // MARK: - 小元件
        // pill: 標籤樣式元件
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
        // titleForPhase: 取得階段標題
        // phaseLabel: 取得階段簡短標籤
        // minutesForPhase: 取得階段分鐘數
        // colorForPhase: 取得階段顏色
        // iconForPhase: 取得階段圖示
    private func titleForPhase(_ p: Phase) -> String {
        switch p {
        case .focus:      return "專注中"
        case .shortBreak: return "短休中"
        case .longBreak:  return "長休中"
        }
    }
    
    private func phaseLabel(_ p: Phase) -> String {
        switch p {
        case .focus:      return "專注"
        case .shortBreak: return "短休"
        case .longBreak:  return "長休"
        }
    }
    
    private func minutesForPhase(_ p: Phase) -> Int {
        switch p {
        case .focus:      return settings.focusMinutes
        case .shortBreak: return settings.shortBreakMinutes
        case .longBreak:  return settings.longBreakMinutes
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
    
    @Query(sort: \PomodoroRecord.date, order: .reverse) private var pomodoros: [PomodoroRecord]
    
        // 本週區間（依系統地區決定週起始）
        // weekInterval: 本週的日期區間
        // weekDays: 本週的所有日期
        // pomodorosThisWeek: 本週的所有番茄紀錄
        // pomodorosByDay: 每日番茄數
        // weeklyPomodoroCount: 本週總番茄數
        // weeklyPercent: 本週完成百分比
    private var weekInterval: DateInterval {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
    }
        // 本週所有日期（7 天）
    private var weekDays: [Date] {
        let start = Calendar.current.startOfDay(for: weekInterval.start)
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }
        // 本週的所有番茄紀錄
    private var pomodorosThisWeek: [PomodoroRecord] {
        pomodoros.filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }
    }
        // 每日番茄數（用於圖表）
    private var pomodorosByDay: [Date: Int] {
        var map: [Date: Int] = [:]
        for r in pomodorosThisWeek {
            let day = Calendar.current.startOfDay(for: r.date)
            map[day, default: 0] += 1
        }
        return map
    }
        // 本週總番茄數
    private var weeklyPomodoroCount: Int {
        pomodorosThisWeek.count
    }
        // 本週完成百分比 = 本週番茄 / (每天目標 * 7)
    private var weeklyPercent: Int {
        let denom = max(1, settings.pomodoroTargetPerDay * 7)
        let pct = (Double(weeklyPomodoroCount) / Double(denom)) * 100
        return min(100, max(0, Int(round(pct))))
    }
}

#Preview("FocusCycle • Demo") {
        // In-memory SwiftData（不寫入真資料）
    let schema = Schema([RunningRecord.self, PomodoroRecord.self, GameRecord.self])
    let container = try! ModelContainer(
        for: schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
        // 環境物件
    let co = ModuleCoordinator()
    co.energy = 2                      // 隨意給一點能量
    
    let settings = AppSettings.shared  // 用你的單例；調成預覽友善的數值
    settings.focusMinutes = 5
    settings.shortBreakMinutes = 2
    settings.longBreakMinutes = 10
    settings.roundsBeforeLongBreak = 4
    settings.autoContinue = false
    
    return FocusCycleView()
        .environment(co)
        .environment(settings)
        .modelContainer(container)
        .preferredColorScheme(.light)
}

#Preview("FocusCycle • Tiny (1min)") {
    let schema = Schema([RunningRecord.self, PomodoroRecord.self, GameRecord.self])
    let container = try! ModelContainer(
        for: schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let co = ModuleCoordinator()
    co.energy = 1
    
    let settings = AppSettings.shared
    settings.focusMinutes = 1
    settings.shortBreakMinutes = 1
    settings.longBreakMinutes = 2
    settings.roundsBeforeLongBreak = 2
    settings.autoContinue = true
    
    return FocusCycleView()
        .environment(co)
        .environment(settings)
        .modelContainer(container)
        .preferredColorScheme(.light)
}

private struct DayPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

private struct CompletionSheet: View {
    let task: TaskModel?
    let tint: Color
    var onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(tint)
            if let task = task {
                Text("完成『\(task.name)』！")
                    .font(.title2).bold()
                Text("已完成 \(task.minutes) 分鐘，太棒了！")
                    .foregroundStyle(.secondary)
            } else {
                Text("已完成專注任務！")
                    .font(.title2).bold()
            }
            Button("好的") { onClose() }
                .buttonStyle(PrimaryButtonStyle(.primary(tint)))
                .padding(.top, 8)
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}
