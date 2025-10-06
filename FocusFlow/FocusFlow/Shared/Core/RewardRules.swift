// RewardRules.swift
// 跑步（Running)：完成一次就 +1 能量（不看時長）
// 專注（Focus/Pomodoro）：完成一顆番茄就 +1 能量（不看分鐘數）
// 遊戲（Game）：開始一局 -1 能量（不看勝負）；條件：能量 ≥ 1 才能開始；若能量 = 0，顯示鎖定導引（請先完成跑步/專注以獲得能量）； 玩完不加能量

import Foundation

enum RewardRules {
        /// 開始一局遊戲需要消耗的能量
    static let gameEntryCost: Int = 1
    
        /// 完成事件時得到的能量
    static func energy(for event: ModuleCoordinator.FlowEvent) -> Int {
        switch event {
        case .runCompleted:                  return 1
        case .pomodoroCompleted:             return 1
        case .gameFinished:                  return 0   // 玩完不加點
        }
    }
    
        /// 是否可進入遊戲
    static func canEnterGame(energy: Int) -> Bool {
        energy >= gameEntryCost
    }
}
