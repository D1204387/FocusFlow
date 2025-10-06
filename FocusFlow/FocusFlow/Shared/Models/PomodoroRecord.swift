//
//  PomodoroRecord.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/9/27.
//

import Foundation
import SwiftData

@Model
final class PomodoroRecord {
    var date: Date
    var focus: Int   // 分鐘
    var rest: Int
    
    init(date: Date = .now, focus: Int, rest: Int) {
        self.date = date
        self.focus = focus
        self.rest = rest
    }
}
