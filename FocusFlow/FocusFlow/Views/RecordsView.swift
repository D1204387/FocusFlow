import SwiftUI
import SwiftData
import Charts

struct RecordsView: View {
    enum Category: String, CaseIterable, Identifiable {
        case all = "全部"
        case running = "跑步"
        case focus = "專注"
        case game = "遊戲"
        var id: Self { self }
    }
    
    enum RangePreset: String, CaseIterable, Identifiable {
        case week = "近 7 天"
        case month = "近 30 天"
        var id: Self { self }
        
        var interval: DateInterval {
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: self == .week ? -6 : -29, to: end)!
            return DateInterval(start: start.startOfDay, end: end.endOfDay)
        }
    }
    
    @Environment(\.modelContext) private var ctx
    @Environment(ModuleCoordinator.self) private var co
    
    @State private var category: Category = .all
    @State private var preset: RangePreset = .week
    @State private var bins: [DayBin] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                        // 能量
                    HStack {
                        pill("能量 \(co.energy)")
                        Spacer()
                    }
                    
                        // 篩選
                    Picker("", selection: $category) {
                        ForEach(Category.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("", selection: $preset) {
                        ForEach(RangePreset.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    
                    SummaryRow(bins: bins)
                    
                    ChartView(bins: bins, category: category)
                        .frame(height: 260)
                        .background(Theme.bg)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardStroke))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .softShadow()
                    
                    RecordsList(bins: bins, category: category)
                }
                .padding()
            }
            .background(Theme.bg)
            .navigationTitle("記錄")
        }
        .task(id: category) { await reload() }
        .task(id: preset)   { await reload() }
        .onAppear           { Task { await reload() } }
    }
    
        // MARK: - Load
    private func reload() async {
        let store = RecordsStore(context: ctx)
        let range = preset.interval
        let runs  = (try? store.runs(in: range))      ?? []
        let poms  = (try? store.pomodoros(in: range)) ?? []
        let games = (try? store.games(in: range))     ?? []
        bins = DayBin.aggregate(range: range, runs: runs, pomos: poms, games: games)
    }
    
        // MARK: - UI helpers
    private func pill(_ text: String) -> some View {
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
    let bins: [DayBin]
    let category: RecordsView.Category
    
    var body: some View {
        let data = seriesData // 拆出，降低型別推斷複雜度
        
        Chart(data) { pt in
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
                    AxisValueLabel {
                        Text(d, format: .dateTime.weekday(.narrow))
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
        .padding(12)
    }
    
    private func color(for series: String) -> Color {
        switch series {
        case "跑步":  return Theme.Run.solid
        case "專注":  return Theme.Focus.solid
        default:      return .gray.opacity(0.35)
        }
    }
    
    private var seriesData: [SeriesPoint] {
        switch category {
        case .running:
            return bins.map { SeriesPoint(date: $0.date, value: $0.runMinutes, series: "跑步") }
        case .focus:
            return bins.map { SeriesPoint(date: $0.date, value: $0.focusMinutes, series: "專注") }
        case .game:
            return bins.map { SeriesPoint(date: $0.date, value: Double($0.gamePlays), series: "遊戲") }
        case .all:
            return bins.flatMap {
                [
                    SeriesPoint(date: $0.date, value: $0.runMinutes, series: "跑步"),
                    SeriesPoint(date: $0.date, value: $0.focusMinutes, series: "專注")
                ]
            }
        }
    }
}

    // MARK: - Summary

private struct SummaryRow: View {
    let bins: [DayBin]
    
    private var totalRun: Int   { Int(bins.reduce(0) { $0 + $1.runMinutes }) }
    private var totalFocus: Int { Int(bins.reduce(0) { $0 + $1.focusMinutes }) }
    private var totalGame: Int  { bins.reduce(0) { $0 + $1.gamePlays } }
    
    var body: some View {
        HStack(spacing: 12) {
            stat("跑步(分)", value: totalRun, color: Theme.Run.solid)
            stat("專注(分)", value: totalFocus, color: Theme.Focus.solid)
            stat("遊戲(局)", value: totalGame, color: .gray)
        }
    }
    
    private func stat(_ title: String, value: Int, color: Color) -> some View {
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

    // MARK: - Aggregation

private struct SeriesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let series: String
}

private struct DayBin: Identifiable {
    let id = UUID()
    let date: Date
    var runMinutes: Double
    var focusMinutes: Double
    var gamePlays: Int
    
    static func aggregate(range: DateInterval,
                          runs: [RunningRecord],
                          pomos: [PomodoroRecord],
                          games: [GameRecord]) -> [DayBin] {
        
        let days = Calendar.current.dates(from: range.start.startOfDay, to: range.end.startOfDay)
        var map: [Date: DayBin] = Dictionary(uniqueKeysWithValues: days.map {
            ($0, DayBin(date: $0, runMinutes: 0, focusMinutes: 0, gamePlays: 0))
        })
        
        for r in runs {
            let day = r.date.startOfDay
            if var v = map[day] { v.runMinutes += r.duration/60; map[day] = v }
        }
        for p in pomos {
            let day = p.date.startOfDay
            if var v = map[day] { v.focusMinutes += Double(p.focus); map[day] = v }
        }
        for g in games {
            let day = g.date.startOfDay
            if var v = map[day] { v.gamePlays += 1; map[day] = v }
        }
        
        return days.compactMap { map[$0] }
    }
}

private extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var endOfDay: Date { Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)! }
}

private extension Calendar {
    func dates(from start: Date, to end: Date) -> [Date] {
        var result: [Date] = []
        var cur = start
        while cur <= end {
            result.append(cur)
            cur = date(byAdding: .day, value: 1, to: cur)!
        }
        return result
    }
}

