import Foundation
import SwiftData
import WidgetKit

    // MARK: - App Group / 共用工具
// FFAppGroup 用於取得 App Group 的 UserDefaults 與 container 路徑，方便主程式與 Widget 共享資料
public enum FFAppGroup {
    public static let id = "group.com.buildwithharry.focusflow"
    
    public static var userDefaults: UserDefaults {
        UserDefaults(suiteName: id)!
    }
    public static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)!
    }
}

    // MARK: - 番茄鐘狀態（即時）
// FFPhase: 番茄鐘的階段（專注/休息）
// FocusFlowState: 番茄鐘的狀態資料結構
public enum FFPhase: String, Codable { case focus, `break` }

public struct FocusFlowState: Codable {
    public var phase: FFPhase = .focus
    public var endDate: Date? = nil
    public var isRunning: Bool = false
    public var completedCount: Int = 0
}

public enum FocusFlowStore {
    private static let key = "FocusFlowState"
    private static var ud: UserDefaults { FFAppGroup.userDefaults }
    
    public static func load() -> FocusFlowState {
        if let data = ud.data(forKey: key),
           let s = try? JSONDecoder().decode(FocusFlowState.self, from: data) { return s }
        return FocusFlowState()
    }
    public static func save(_ s: FocusFlowState) {
        if let data = try? JSONEncoder().encode(s) { ud.set(data, forKey: key) }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

    // MARK: - 跑步狀態（即時）
// RunningState: 跑步功能的狀態資料結構
public struct RunningState: Codable {
    public enum Phase: String, Codable { case idle, running, paused }
    public var phase: Phase = .idle
    public var startDate: Date? = nil
    public var elapsedSec: TimeInterval = 0
    public var distanceMeters: Double = 0
    public var paceSecPerKm: Double = 0
    public var lastUpdate: Date = .now
}

public enum RunStore {
    private static let key = "RunningState"
    private static var ud: UserDefaults { FFAppGroup.userDefaults }
    
    public static func load() -> RunningState {
        if let data = ud.data(forKey: key),
           let s = try? JSONDecoder().decode(RunningState.self, from: data) { return s }
        return RunningState()
    }
    public static func save(_ s: RunningState) {
        if let data = try? JSONEncoder().encode(s) { ud.set(data, forKey: key) }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

    // MARK: - SwiftData 共用容器 + 小工具統計（App/Widget 共用）
// WidgetDataManager: 負責管理 SwiftData 的 ModelContainer，並提供統計資料的計算方法
public struct WidgetDataManager {
    public static let shared = WidgetDataManager()
    
    private let modelContainer: ModelContainer
    
    private init() {
        let url = FFAppGroup.containerURL.appendingPathComponent("FocusFlow.sqlite")
        let config = ModelConfiguration(url: url)
        do {
            modelContainer = try ModelContainer(
                for: RunningRecord.self, PomodoroRecord.self,
                configurations: config
            )
        } catch {
            fatalError("ModelContainer error: \(error)")
        }
    }
    
    private func ctx() -> ModelContext { ModelContext(modelContainer) }
    
        /// 跑步摘要：本週分鐘 + 連續天數
    public func computeRunSummary(now: Date = .now) -> (weeklyMinutes: Int, streakDays: Int) {
        let context = ctx()
        let cal = Calendar.current
        let startOfWeek = cal.startOfWeek(for: now)
        let endOfWeek   = cal.date(byAdding: .day, value: 7, to: startOfWeek)!
        let twoWeeksAgo = cal.date(byAdding: .day, value: -14, to: now)!
        
        let weeklyFD = FetchDescriptor<RunningRecord>(
            predicate: #Predicate { $0.date >= startOfWeek && $0.date < endOfWeek }
        )
        let recentFD = FetchDescriptor<RunningRecord>(
            predicate: #Predicate { $0.date >= twoWeeksAgo && $0.date <= now }
        )
        
        do {
            let weekly = try context.fetch(weeklyFD)
            let recent = try context.fetch(recentFD)
            let weeklyMinutes = weekly.reduce(0) { $0 + Int($1.duration / 60) }
            
            var streak = 0
            for i in 0..<14 {
                guard let day = cal.date(byAdding: .day, value: -i, to: now) else { break }
                let s = cal.startOfDay(for: day)
                let e = cal.date(byAdding: .day, value: 1, to: s)!
                let didRun = recent.contains { $0.date >= s && $0.date < e }
                if didRun { streak += 1 } else { break }
            }
            return (weeklyMinutes, streak)
        } catch {
            print("SwiftData fetch error:", error)
            return (0, 0)
        }
    }
    
        /// 番茄鐘摘要：今天累積專注分鐘 + 次數
    public func computePomodoroToday(now: Date = .now) -> (focusMinutes: Int, sessions: Int) {
        let context = ctx()
        let cal = Calendar.current
        let s = cal.startOfDay(for: now)
        let e = cal.date(byAdding: .day, value: 1, to: s)!
        let fd = FetchDescriptor<PomodoroRecord>(
            predicate: #Predicate { $0.date >= s && $0.date < e }
        )
        do {
            let list = try context.fetch(fd)
            let total = list.reduce(0) { $0 + $1.focus }
            return (total, list.count)
        } catch {
            print("SwiftData fetch error:", error)
            return (0, 0)
        }
    }
}

    // MARK: - Helpers
public extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? startOfDay(for: date)
    }
}
