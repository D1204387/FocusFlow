//
//  ModuleCoordinator.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/1.
//
import Foundation
import Observation
import SwiftData

@Observable
final class ModuleCoordinator {
    var energy: Int = 0
    var showGainToast = false
    var lastGain = 0
    
    enum FlowEvent {
        case runCompleted(minutes: Int)
        case pomodoroCompleted(focus: Int, rest: Int)
        case gameFinished(score: Int, seconds: Int)
    }
    
    @MainActor
    func apply(_ e: FlowEvent, modelContext: ModelContext) {
        let gain: Int
        switch e {
        case .runCompleted(let m):            gain = max(1, m / 20)   // 20 分鐘 +1（可改）
        case .pomodoroCompleted(let f, _):    gain = max(1, f / 25)   // 25 分鐘 +1
        case .gameFinished:                   gain = 0                // 玩完不加
        }
        if gain > 0 { addEnergy(gain) }
        try? modelContext.save()
    }
    
    @discardableResult
    func spendEnergy(_ n: Int) -> Bool {
        guard energy >= n else { return false }
        energy -= n
        return true
    }
    
    @MainActor
    private func addEnergy(_ n: Int) {
        energy += n
        lastGain = n
        showGainToast = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            showGainToast = false
        }
    }
}
