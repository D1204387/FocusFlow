// Shared/Stores/RecordsStore.swift
import Foundation
import SwiftData

// MARK: - 資料存取工具
// RecordsStore: 提供依日期區間查詢跑步、番茄、遊戲紀錄的方法
// runs: 查詢指定區間的 RunningRecord
// pomodoros: 查詢指定區間的 PomodoroRecord
// games: 查詢指定區間的 GameRecord
// 統計方法：getTodayStats、getWeekStats
// Widget 同步：syncTodayStatsToAppGroup

struct RecordsStore {
    let context: ModelContext
    
    init(context: ModelContext) { self.context = context }
    
    func runs(in range: DateInterval) throws -> [RunningRecord] {
        let fd = FetchDescriptor<RunningRecord>(
            predicate: #Predicate { $0.date >= range.start && $0.date <= range.end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(fd)
    }
    
    func pomodoros(in range: DateInterval) throws -> [PomodoroRecord] {
        let fd = FetchDescriptor<PomodoroRecord>(
            predicate: #Predicate { $0.date >= range.start && $0.date <= range.end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(fd)
    }
    
    func games(in range: DateInterval) throws -> [GameRecord] {
        let fd = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.date >= range.start && $0.date <= range.end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(fd)
    }
    
    // MARK：統計方法
    /// 獲取今天的統計數據
    func getTodayStats() -> (runMinutes: Int, focusMinutes: Int, gameCount: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let range = DateInterval(start: today, end: tomorrow)
        
        let runMinutes = (try? runs(in: range).map { $0.minutes }.reduce(0, +)) ?? 0
        let focusMinutes = (try? pomodoros(in: range).map { $0.focus }.reduce(0, +)) ?? 0
        let gameCount = (try?  games(in: range).count) ?? 0
        
        return (runMinutes, focusMinutes, gameCount)
    }
    
    /// 獲取本週(過去7天)的統計數據
    func getWeekStats() -> (runMinutes: Int, focusMinutes: Int, gameCount: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        let range = DateInterval(start: weekAgo, end: today)
        
        let runs = (try? runs(in: range)) ?? []
        let pomodoros = (try? pomodoros(in: range)) ?? []
        let games = (try? games(in: range)) ?? []
        
        var stats: [Date: (runMinutes: Int, focusMinutes: Int, gameCount: Int)] = [:]
        
        for i in 0..<7 {
            let day = Calendar.current.date(byAdding: .day, value: i, to: weekAgo)!
            let dayStart = Calendar.current.startOfDay(for: day)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
            let dayRange = DateInterval(start: dayStart, end: dayEnd)
            
            let runMins = runs.filter { dayRange.contains($0.date) }
                .map { $0.minutes }.reduce(0, +)
            let focusMins = pomodoros.filter { dayRange.contains($0.date) }
                .map { $0.focus }.reduce(0, +)
            let gameCnt = games.filter { dayRange.contains($0.date) }.count
            
            stats[day] = (runMins, focusMins, gameCnt)
        }
        
        // 彙總整週數據
        let totalRunMinutes = stats.values.map { $0.runMinutes }.reduce(0, +)
        let totalFocusMinutes = stats.values.map { $0.focusMinutes }.reduce(0, +)
        let totalGameCount = stats.values.map { $0.gameCount }.reduce(0, +)
        return (
            totalRunMinutes,
            totalFocusMinutes,
            totalGameCount
        )
    }
    
    // MARK: - Widget 同步
   
    /// 獲取今天的跑步分鐘數
    func getTodayRunMinutes() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let range = DateInterval(start: today, end: tomorrow)
        
        return(try? runs(in: range).map { $0.minutes }.reduce(0, +)) ?? 0
    }
    
    /// 獲取今天的番茄統計數據
    func getTodayPomodoroCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let range = DateInterval(start: today, end: tomorrow)
        
        return(try? pomodoros(in: range).count) ?? 0
    }
    
    /// 獲取今天的遊戲統計數據
    func getTodayGameCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let range = DateInterval(start: today, end: tomorrow)
        
        return(try? games(in: range).count) ?? 0
    }
    
    
    /// 同步今天的統計數據到 App Group 的 UserDefaults
    func syncTodayStatsToAppGroup(){
        guard let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow") else { return }
        
        let todayRunMinutes = getTodayRunMinutes()
        let todayPomodoroCount = getTodayPomodoroCount()
        let todayGameCount = getTodayGameCount()
        
        let todayMinutes = todayRunMinutes + (todayPomodoroCount * 25) // 假設每個番茄是25分鐘
        let todayCount = todayPomodoroCount + todayGameCount
        
        userDefaults.set(todayRunMinutes, forKey: "todayRunMinutes")
        userDefaults.set(todayPomodoroCount, forKey: "todayPomodoroCount")
        userDefaults.set(todayGameCount, forKey: "todayGameCount")
        
        userDefaults.set(todayMinutes, forKey: "todayMinutes")
        userDefaults.set(todayCount, forKey: "todayCount")
        
        userDefaults.synchronize()
    }
    
    /// 同步本週的統計數據到 App Group 的 UserDefaults
    func syncWeekStatsToAppGroup(){
        guard let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow") else { return }
        
        let (weekRunMinutes, weekFocusMinutes, weekGameCount) = getWeekStats()
        let weekTotalMinutes = weekRunMinutes + weekFocusMinutes
        userDefaults.set(weekRunMinutes, forKey: "weekRunMinutes")
        userDefaults.set(weekFocusMinutes, forKey: "weekFocusMinutes")
        userDefaults.set(weekGameCount, forKey: "weekGameCount")
        userDefaults.set(weekTotalMinutes, forKey: "weekTotalMinutes")
        userDefaults.synchronize()
    }
}

//extension RecordsStore {
//    func syncTodayStatsToAppGroup() {
//        let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow")
//        let today = Calendar.current.startOfDay(for: Date())
//        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
//        let range = DateInterval(start: today, end: tomorrow)
//        let todayRunMinutes = (try? runs(in: range).map { $0.minutes }.reduce(0, +)) ?? 0
//        let todayRunCount = (try? runs(in: range).count) ?? 0
//        let todayFocusMinutes = (try? pomodoros(in: range).map { $0.focus }.reduce(0, +)) ?? 0
//        let todayFocusCount = (try? pomodoros(in: range).count) ?? 0
//        // 合併所有紀錄
//        userDefaults?.set(todayRunMinutes + todayFocusMinutes, forKey: "todayMinutes")
//        userDefaults?.set(todayRunCount + todayFocusCount, forKey: "todayCount")
//        userDefaults?.synchronize()
//    }
//}
