//
//  RunningShared.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/13.
//

import Foundation

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
    private static let suite = "group.com.buildwithharry.focusflow"
    private static var ud: UserDefaults { UserDefaults(suiteName: suite)! }
    private static let key = "RunningState"
    
    public static func load() -> RunningState {
        if let data = ud.data(forKey: key),
           let s = try? JSONDecoder().decode(RunningState.self, from: data) { return s }
        return RunningState()
    }
    
    public static func save(_ s: RunningState) {
        if let data = try? JSONEncoder().encode(s) { ud.set(data, forKey: key) }
    }
}

