//
//  RecordsStore.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/2.
//


    // Core/RecordsStore.swift
import Foundation
import SwiftData

@MainActor
struct RecordsStore {
    let context: ModelContext
    
        // MARK: - Create
    func logRun(seconds: TimeInterval, bpm: Int? = nil) throws {
        context.insert(RunningRecord(duration: seconds, bpm: bpm))
        try context.save()
    }
    
    func logPomodoro(focus: Int, rest: Int) throws {
        context.insert(PomodoroRecord(focus: focus, rest: rest))
        try context.save()
    }
    
    func logGame(score: Int, seconds: Int) throws {
        context.insert(GameRecord(score: score, seconds: seconds))
        try context.save()
    }
    
        // MARK: - Read (with optional range)
    func runs(in range: DateInterval? = nil) throws -> [RunningRecord] {
        let predicate: Predicate<RunningRecord>? = range.map {
            let start = $0.start; let end = $0.end
            return #Predicate<RunningRecord> { $0.date >= start && $0.date <= end }
        }
        let fd = FetchDescriptor<RunningRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(fd)
    }
    
    func pomodoros(in range: DateInterval? = nil) throws -> [PomodoroRecord] {
        let predicate: Predicate<PomodoroRecord>? = range.map {
            let start = $0.start; let end = $0.end
            return #Predicate<PomodoroRecord> { $0.date >= start && $0.date <= end }
        }
        let fd = FetchDescriptor<PomodoroRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(fd)
    }
    
    func games(in range: DateInterval? = nil) throws -> [GameRecord] {
        let predicate: Predicate<GameRecord>? = range.map {
            let start = $0.start; let end = $0.end
            return #Predicate<GameRecord> { $0.date >= start && $0.date <= end }
        }
        let fd = FetchDescriptor<GameRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(fd)
    }
}
