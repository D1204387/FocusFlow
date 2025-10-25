// Shared/Stores/RecordsStore.swift
import Foundation
import SwiftData

// MARK: - 資料存取工具
// RecordsStore: 提供依日期區間查詢跑步、番茄、遊戲紀錄的方法
// runs: 查詢指定區間的 RunningRecord
// pomodoros: 查詢指定區間的 PomodoroRecord
// games: 查詢指定區間的 GameRecord

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
}

extension RecordsStore {
    func syncTodayStatsToAppGroup() {
        let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow")
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let range = DateInterval(start: today, end: tomorrow)
        let todayRunMinutes = (try? runs(in: range).map { $0.minutes }.reduce(0, +)) ?? 0
        let todayRunCount = (try? runs(in: range).count) ?? 0
        let todayFocusMinutes = (try? pomodoros(in: range).map { $0.focus }.reduce(0, +)) ?? 0
        let todayFocusCount = (try? pomodoros(in: range).count) ?? 0
        // 合併所有紀錄
        userDefaults?.set(todayRunMinutes + todayFocusMinutes, forKey: "todayMinutes")
        userDefaults?.set(todayRunCount + todayFocusCount, forKey: "todayCount")
        userDefaults?.synchronize()
    }
}
