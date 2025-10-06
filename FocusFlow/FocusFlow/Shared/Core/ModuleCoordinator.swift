    // ModuleCoordinator.swift
import Foundation
import Observation
import SwiftData

@Observable
final class ModuleCoordinator {
    var energy: Int = 0
    
    enum FlowEvent {
        case runCompleted(minutes: Int)
        case pomodoroCompleted(focus: Int, rest: Int)
        case gameFinished(score: Int, seconds: Int)
    }
    
    @MainActor
    func apply(_ event: FlowEvent, modelContext: ModelContext) {
        let gain = RewardRules.energy(for: event)
        if gain > 0 { energy += gain }
        try? modelContext.save()
    }
    
        // 遊戲進入規則（依 RewardRules）
    func canEnterGame() -> Bool { RewardRules.canEnterGame(energy: energy) }
    @discardableResult
    func spendForGameEntry() -> Bool { spendEnergy(RewardRules.gameEntryCost) }
    
    @discardableResult
    func spendEnergy(_ n: Int) -> Bool {
        guard energy >= n else { return false }
        energy -= n
        return true
    }
    
    func refundEnergy(_ n: Int) {
        guard n > 0 else { return }
        energy += n
    }
}

