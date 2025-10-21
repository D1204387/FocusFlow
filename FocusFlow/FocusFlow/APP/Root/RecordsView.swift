import SwiftUI
import SwiftData
import Charts
import WidgetKit

// 這個檔案負責顯示用戶的跑步、專注、遊戲等記錄，並以圖表與列表方式呈現
// 包含資料彙總、圖表、摘要列、記錄列表等 SwiftUI 元件
// MARK: - 檔案層級輔助資料結構
// SeriesPoint: 折線圖資料點
// DayBin: 每日彙總資料（跑步、專注、遊戲）
// aggregate: 彙總指定區間的所有資料
// Date/Calendar 擴充：取得當天起訖

    // MARK: - Helpers (file-scope)

struct SeriesPoint: Identifiable {
    // 折線圖的資料點
    let id = UUID()
    let date: Date
    let value: Double
    let series: String
}

struct DayBin: Identifiable {
    // 每日彙總資料
    let id = UUID()
    let date: Date
    var runMinutes: Double // 跑步分鐘數
    var focusMinutes: Double // 專注分鐘數
    var gamePlays: Int // 遊戲局數
    
    static func aggregate(range: DateInterval,
                          runs: [RunningRecord],
                          pomos: [PomodoroRecord],
                          games: [GameRecord]) -> [DayBin] {
        // 彙總指定區間的所有資料，依天分組
        let days = Calendar.current.dates(from: range.start.startOfDay, to: range.end.startOfDay)
        var table: [Date: DayBin] = Dictionary(uniqueKeysWithValues: days.map {
            ($0, DayBin(date: $0, runMinutes: 0, focusMinutes: 0, gamePlays: 0))
        })
        for r in runs {
            let d = r.date.startOfDay
            if var v = table[d] { v.runMinutes += r.duration / 60; table[d] = v }
        }
        for p in pomos {
            let d = p.date.startOfDay
            if var v = table[d] { v.focusMinutes += Double(p.focus); table[d] = v }
        }
        for g in games {
            let d = g.date.startOfDay
            if var v = table[d] { v.gamePlays += 1; table[d] = v }
        }
        return days.compactMap { table[$0] }
    }
}

extension Date {
    // 取得當天的起始與結束時間
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var endOfDay:   Date { Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)! }
}

extension Calendar {
    // 取得從 start 到 end 的所有日期陣列
    func dates(from start: Date, to end: Date) -> [Date] {
        var out: [Date] = []; var cur = start
        while cur <= end { out.append(cur); cur = date(byAdding: .day, value: 1, to: cur)! }
        return out
    }
}

    // MARK: - Main View

struct RecordsView: View {
    // 類別選擇（全部、跑步、專注、遊戲）
    enum Category: String, CaseIterable, Identifiable {
        case all = "全部", running = "跑步", focus = "專注", game = "遊戲"
        var id: Self { self }
    }
    // 區間選擇（近 7 天、近 30 天）
    enum RangePreset: String, CaseIterable, Identifiable {
        case week = "近 7 天", month = "近 30 天"
        var id: Self { self }
        var interval: DateInterval {
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: self == .week ? -6 : -29, to: end)!
            return DateInterval(start: start.startOfDay, end: end.endOfDay)
        }
    }
    
    @Environment(\.modelContext) private var ctx // SwiftData context
    @Environment(ModuleCoordinator.self) private var co // 能量協調器
    
    @State private var category: Category = .all // 當前選擇的類別
    @State private var preset: RangePreset = .week // 當前選擇的區間
    @State private var bins: [DayBin] = [] // 彙總後的每日資料
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack { pill("能量 \(co.energy)"); Spacer() } // 顯示能量
                    
                    Picker("", selection: $category) {
                        ForEach(Category.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    
                    Picker("", selection: $preset) {
                        ForEach(RangePreset.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    
                    SummaryRow(bins: bins) // 摘要列
                    
                    ChartView(bins: bins, category: category)
                        .frame(height: 260)
                        .background(Theme.bg)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardStroke))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .softShadow()
                    
                    RecordsList(bins: bins, category: category) // 記錄列表
                }
                .padding()
            }
            .background(Theme.bg)
            .navigationTitle("記錄")
            .toolbarEnergy(title: "記錄", tint: .gray)
        }
        .task(id: category) { await reload() } // 切換類別時重新載入
        .task(id: preset)   { await reload() } // 切換區間時重新載入
        .onAppear           { Task { await reload() } } // 首次顯示時載入
    }
    
        // MARK: - Load
    private func reload() async {
        // 讀取資料並彙總
        let store = RecordsStore(context: ctx)   // 你專案裡的簡易查詢器
        let range = preset.interval
        let runs  = (try? store.runs(in: range))      ?? []
        let poms  = (try? store.pomodoros(in: range)) ?? []
        let games = (try? store.games(in: range))     ?? []
        bins = DayBin.aggregate(range: range, runs: runs, pomos: poms, games: games)
    }
    
        // MARK: - UI helpers
    private func pill(_ text: String) -> some View {
        // 膠囊樣式的文字顯示
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.pillBG)
            .clipShape(Capsule())
    }
}

    // MARK: - Chart

private struct ChartView: View {
    // 圖表顯示
    let bins: [DayBin]
    let category: RecordsView.Category
    
    private var seriesData: [SeriesPoint] {
        // 根據類別產生對應的資料點
        switch category {
        case .running: return bins.map { .init(date: $0.date, value: $0.runMinutes,  series: "跑步") }
        case .focus:   return bins.map { .init(date: $0.date, value: $0.focusMinutes, series: "專注") }
        case .game:    return bins.map { .init(date: $0.date, value: Double($0.gamePlays), series: "遊戲") }
        case .all:
            return bins.flatMap {
                [.init(date: $0.date, value: $0.runMinutes,  series: "跑步"),
                 .init(date: $0.date, value: $0.focusMinutes, series: "專注")]
            }
        }
    }
    
    var body: some View {
        Chart(seriesData) { pt in
            BarMark(
                x: .value("日期", pt.date, unit: .day),
                y: .value("值", pt.value)
            )
            .foregroundStyle(color(for: pt.series))
            .cornerRadius(6)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { v in
                AxisGridLine().foregroundStyle(.clear)
                AxisTick().foregroundStyle(.clear)
                if let d = v.as(Date.self) {
                    AxisValueLabel { Text(d, format: .dateTime.weekday(.narrow)) }
                }
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.cardStroke)
                AxisValueLabel()
            }
        }
        .padding(12)
    }
    
    private func color(for s: String) -> Color {
        // 根據系列名稱給顏色
        switch s {
        case "跑步": return Theme.Run.solid
        case "專注": return Theme.Focus.solid
        case "遊戲": return Theme.Game.solid
        default:     return .gray.opacity(0.35)
        }
    }
}

    // MARK: - Summary

private struct SummaryRow: View {
    // 摘要列顯示
    let bins: [DayBin]
    private var totalRun: Int   { Int(bins.reduce(0) { $0 + $1.runMinutes }) } // 跑步總分鐘
    private var totalFocus: Int { Int(bins.reduce(0) { $0 + $1.focusMinutes }) } // 專注總分鐘
    private var totalGame: Int  { bins.reduce(0) { $0 + $1.gamePlays } } // 遊戲總局數
    
    var body: some View {
        HStack(spacing: 12) {
            stat("跑步(分)", value: totalRun,   color: Theme.Run.solid)
            stat("專注(分)", value: totalFocus, color: Theme.Focus.solid)
            stat("遊戲(局)", value: totalGame,  color: Theme.Game.solid)
        }
    }
    
    private func stat(_ title: String, value: Int, color: Color) -> some View {
        // 單一統計項目
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(Theme.subtext)
            Text("\(value)").font(.title2.bold()).foregroundStyle(color).monospacedDigit()
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Theme.pillBG)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

    // MARK: - List

private struct RecordsList: View {
    // 記錄列表顯示
    let bins: [DayBin]
    let category: RecordsView.Category
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(bins) { d in
                HStack {
                    Text(d.date, format: .dateTime.month().day().weekday(.wide))
                        .font(.subheadline)
                        .foregroundStyle(Theme.text)
                    Spacer()
                    if category == .all || category == .running {
                        Label("\(Int(d.runMinutes)) 分", systemImage: "figure.run")
                            .foregroundStyle(Theme.Run.solid)
                    }
                    if category == .all || category == .focus {
                        Label("\(Int(d.focusMinutes)) 分", systemImage: "timer")
                            .foregroundStyle(Theme.Focus.solid)
                    }
                    if category == .all || category == .game {
                        Label("\(d.gamePlays) 局", systemImage: "gamecontroller")
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.vertical, 6)
                .overlay(Divider(), alignment: .bottom)
            }
        }
        .padding()
        .background(Theme.bg)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardStroke))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .softShadow()
    }
}

    // MARK: - Widget 資料同步方法

extension RecordsView {
    func updateWidgetRunSummary(runs: [RunningRecord]) {
        let today = Date().startOfDay
        let todayRuns = runs.filter { $0.date.startOfDay == today }
        let todayMinutes = todayRuns.reduce(0) { $0 + Int($1.duration / 60) }
        let todayCount = todayRuns.count
        let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow")
        userDefaults?.set(todayMinutes, forKey: "todayMinutes")
        userDefaults?.set(todayCount, forKey: "todayCount")
        print("寫入 Widget 資料：todayMinutes=\(todayMinutes), todayCount=\(todayCount)")
        print("AppGroup containerURL:", FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.buildwithharry.focusflow")?.path ?? "nil")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview("記錄（假資料）") {
        // 建 in-memory SwiftData 容器
    let schema = Schema([RunningRecord.self, PomodoroRecord.self, GameRecord.self])
    let container = try! ModelContainer(
        for: schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext
    let cal = Calendar.current
    
        // 塞 10 天的示範資料
    for i in 0..<10 {
        let day = cal.date(byAdding: .day, value: -i, to: .now)!
        
            // 跑步（每隔一天）
        if i % 2 == 0 {
            let r = RunningRecord(duration: Double([600, 1200, 1800, 2400].randomElement()!)) // 秒
            r.date = day
            ctx.insert(r)
        }
        
            // 番茄（每 3 天）
        if i % 3 == 0 {
            let p = PomodoroRecord(focus: [15, 25, 30].randomElement()!, rest: 5)
            p.date = day
            ctx.insert(p)
        }
        
            // 遊戲（每 4 天）
        if i % 4 == 0 {
            let g = GameRecord(score: [256, 512, 1024, 2048].randomElement()!, seconds: 120)
            g.date = day
            ctx.insert(g)
        }
    }
    
        // 提供能量顯示需要的 coordinator
    let co = ModuleCoordinator()
    co.energy = 3
    
    return NavigationStack {
        RecordsView()
    }
    .environment(co)
    .modelContainer(container)
    .preferredColorScheme(.light)
}
