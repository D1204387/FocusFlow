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
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try context.fetch(fd)
    }
    
    func pomodoros(in range: DateInterval) throws -> [PomodoroRecord] {
        let fd = FetchDescriptor<PomodoroRecord>(
            predicate: #Predicate { $0.date >= range.start && $0.date <= range.end },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try context.fetch(fd)
    }
    
    func games(in range: DateInterval) throws -> [GameRecord] {
        let fd = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.date >= range.start && $0.date <= range.end },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try context.fetch(fd)
    }
}
