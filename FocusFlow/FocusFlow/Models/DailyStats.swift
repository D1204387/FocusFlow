//
//  DailyStats.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/9/27.
//

import Foundation
import SwiftData

    /// 每日彙總（可選，之後做快取/趨勢用）
    /// - streak: 連續完成天數
    /// - energy: 當日結束時的能量（可作為快照）
@Model
final class DailyStats {
    var date: Date
    var streak: Int
    var energy: Int
    
    init(date: Date = .now, streak: Int, energy: Int) {
        self.date = date
        self.streak = streak
        self.energy = energy
    }
}

