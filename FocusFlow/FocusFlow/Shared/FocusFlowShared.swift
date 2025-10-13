//
//  FocusFlowShared.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/13.
//

import Foundation

public enum FFPhase: String, Codable { case focus, `break` }

public struct FocusFlowState: Codable {
    public var phase: FFPhase = .focus
    public var endDate: Date? = nil
    public var isRunning: Bool = false
    public var completedCount: Int = 0
}

public enum FocusFlowStore {
    private static let suite = "group.com.buildwithharry.focusflow"
    private static var ud: UserDefaults { UserDefaults(suiteName: suite)! }
    private static let key = "FocusFlowState"
    
    public static func load() -> FocusFlowState {
        if let data = ud.data(forKey: key),
           let s = try? JSONDecoder().decode(FocusFlowState.self, from: data) { return s }
        return FocusFlowState()
    }
    
    public static func save(_ s: FocusFlowState) {
        if let data = try? JSONEncoder().encode(s) { ud.set(data, forKey: key) }
    }
}

