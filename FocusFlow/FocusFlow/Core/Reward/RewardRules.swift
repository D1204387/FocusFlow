//
//  RewardRules.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/1.
//

import Foundation

enum RewardRules {
        /// 事件對應的能量獲得規則
    static func energy(for event: ModuleCoordinator.FlowEvent) -> Int {
        switch event {
        case .runCompleted(let minutes):
                // 每 10 分鐘 +1（至少 1）
            return max(1, minutes / 10)
        case .pomodoroCompleted(let focus, _):
                // 25 分鐘番茄 +1（可依設定調整）
            return max(1, focus / 25)
        case .gameFinished(let score, _):
                // 2048 達標 +1
            return score >= 2048 ? 1 : 0
        }
    }
}

