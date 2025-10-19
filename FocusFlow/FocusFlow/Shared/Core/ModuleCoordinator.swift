// ModuleCoordinator.swift
import Foundation
import Observation
import SwiftData

// MARK: - 模組協調器
// ModuleCoordinator: 管理全域能量與事件分派的 Observable 物件
// energy: 當前能量
// FlowEvent: 事件型別（跑步完成、番茄完成、遊戲結束）
// apply: 根據事件增加能量並儲存
// canEnterGame: 判斷能否進入遊戲
// spendForGameEntry: 扣除遊戲入場能量
// spendEnergy/refundEnergy: 能量增減

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
