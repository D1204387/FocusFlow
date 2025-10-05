    // Modules/Core/Coordinator/ModuleCoordinator.swift
import Foundation
import Observation
import SwiftData

@Observable
final class ModuleCoordinator {
        // MARK: - Persisted energy
    private enum Key { static let energy = "co.energy" }
    var energy: Int {
        didSet { UserDefaults.standard.set(energy, forKey: Key.energy) }
    }
    
    init() {
        energy = UserDefaults.standard.object(forKey: Key.energy) as? Int ?? 0
    }
    
    enum FlowEvent {
        case runCompleted(minutes: Int)
        case pomodoroCompleted(focus: Int, rest: Int)
        case gameFinished(score: Int, seconds: Int)
    }
    
        // MARK: - Apply app-wide events
    @MainActor
    func apply(_ e: FlowEvent, modelContext: ModelContext) {
        let gain = energyGain(for: e)
        if gain > 0 { addEnergy(gain) }
        try? modelContext.save()
    }
    
    private func energyGain(for e: FlowEvent) -> Int {
        switch e {
        case .runCompleted(let m):         return max(1, m / 20)   // 每 20 分 +1
        case .pomodoroCompleted(let f, _): return max(1, f / 20)   // 每 20 分 +1
        case .gameFinished:                return 0
        }
    }
    
        // MARK: - Spend / Add
        /// 嘗試消耗指定能量；成功回傳 true（已扣點）
    @discardableResult
    func trySpendEnergy(_ amount: Int) -> Bool {
        guard amount > 0, energy >= amount else { return false }
        energy -= amount
        return true
    }
    
        /// 舊名相容（若你其他地方已呼叫 spendEnergy）
    @discardableResult
    func spendEnergy(_ n: Int) -> Bool { trySpendEnergy(n) }
    
    @MainActor
    private func addEnergy(_ n: Int) {
        guard n > 0 else { return }
        energy += n
    }
    
        // 方便測試
    func resetEnergy(_ value: Int = 0) { energy = max(0, value) }
}
