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
        
        let runMinutes = (try? runs(in: range).map { Int($0.duration/60) }.reduce(0, +)) ?? 0
        let focusMinutes = (try? pomodoros(in: range).map { $0.focus }.reduce(0, +)) ?? 0
        let gameCount = (try?  games(in: range).count) ?? 0
        
        return (runMinutes, focusMinutes, gameCount)
    }
    
        /// 獲取本週的統計數據
    func getWeekStats() -> (runMinutes: Int, focusMinutes: Int, gameCount: Int) {
        let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
        
        let runs = (try? runs(in: weekInterval)) ?? []
        let pomodoros = (try? pomodoros(in: weekInterval)) ?? []
        let games = (try? games(in: weekInterval)) ?? []
        
//        var stats: [Date: (runMinutes: Int, focusMinutes: Int, gameCount: Int)] = [:]
    
            // 彙總整週數據
        let totalRunMinutes = runs.map { Int($0.duration / 60) } .reduce(0, +)
        let totalFocusMinutes = pomodoros.map { $0.focus }.reduce(0, +)
        let totalGameCount = games.count
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
        
        return(try? runs(in: range).map { Int($0.duration / 60) }.reduce(0, +)) ?? 0
    }
    
        /// 取得本週每日分鐘數（用於圖表）
    func getWeeklyRunMinutesByDay() -> [Date: Double] {
        let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
        let runs = (try? runs(in: weekInterval)) ?? []
        
        var map: [Date: Double] = [:]
        for run in runs {
            let day = Calendar.current.startOfDay(for: run.date)
            map[day, default: 0] += run.duration / 60
        }
        return map
    }
   
    private func getRunsInWeek(_ weekInterval: DateInterval) -> [RunningRecord] {
        return (try? runs(in: weekInterval)) ?? []
    }
    
        // 週區間計算
    private func getCurrentWeekInterval() -> DateInterval {
        return Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
    }
    
        /// 獲取今天的番茄統計數據
    func getTodayPomodoroCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let range = DateInterval(start: today, end: tomorrow)
        
        return(try? pomodoros(in: range).count) ?? 0
    }
    
        // 新增專用函式（給 Widget 使用）
    func getTodayPomodoroStats() -> (focusMinutes: Int, sessions: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let range = DateInterval(start: today, end: tomorrow)
        
        let pomodoros = (try? pomodoros(in: range)) ?? []
        let focusMinutes = pomodoros.map { $0.focus }.reduce(0, +)
        let sessions = pomodoros.count
        
        return (focusMinutes, sessions)
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
        let (todayFocusMinutes, todayPomodoroCount) = getTodayPomodoroStats()
//        let todayPomodoroCount = getTodayPomodoroCount()
        let todayGameCount = getTodayGameCount()
        let streakDays = getStreakDays()
        
        let todayMinutes = todayRunMinutes + (todayPomodoroCount * 25) // 假設每個番茄是25分鐘
        let todayCount = todayPomodoroCount + todayGameCount
        
        userDefaults.set(todayRunMinutes, forKey: "todayRunMinutes")
        userDefaults.set(todayPomodoroCount, forKey: "todayPomodoroCount")
        userDefaults.set(todayFocusMinutes, forKey: "todayFocusMinutes") // 新
        
        userDefaults.set(todayGameCount, forKey: "todayGameCount")
        
        userDefaults.set(todayMinutes, forKey: "todayMinutes")
        userDefaults.set(todayCount, forKey: "todayCount")
        
        userDefaults.set(streakDays, forKey: "streakDays")
        
        userDefaults.synchronize()
        
            // ✅ 新增除錯資訊
        print("📊 同步今日統計: 跑步 \(todayRunMinutes) 分, 番茄 \(todayPomodoroCount) 個, 總計 \(todayMinutes) 分, 連續 \(streakDays) 天")
    }
    
        /// 同步本週的統計數據到 App Group 的 UserDefaults
    func syncWeekStatsToAppGroup(){
        guard let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow") else { return }
        
        let (weekRunMinutes, weekFocusMinutes, weekGameCount) = getWeekStats()

        userDefaults.set(weekRunMinutes, forKey: "weekRunMinutes")
        userDefaults.set(weekFocusMinutes, forKey: "weekFocusMinutes")
        userDefaults.set(weekGameCount, forKey: "weekGameCount")

        userDefaults.synchronize()
        
        print("📊 同步週統計到 Widget:")
        print("  weekRunMinutes: \(weekRunMinutes) 分")
        print("  weekFocusMinutes: \(weekFocusMinutes) 分")
        print("  weekGameCount: \(weekGameCount) 次")
    }
    
    func getStreakDays() -> Int {
        let calendar = Calendar.current
        var streakDays: Int = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let range = DateInterval(start: currentDate, end: nextDay)
            
            let hasRunning = (try? runs(in: range).isEmpty == false) ?? false
            let hasPomodoro = (try? pomodoros(in: range).isEmpty  == false) ?? false
            
            if hasRunning || hasPomodoro {
                streakDays += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
            
            if streakDays > 365 {
                break
            }
        }
        
        return streakDays
    }
}
