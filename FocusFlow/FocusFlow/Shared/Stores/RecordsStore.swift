    // Shared/Stores/RecordsStore.swift
import Foundation
import SwiftData

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


