//
//  GameRecord.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/9/27.
//

import Foundation
import SwiftData

@Model
final class GameRecord {
    var date: Date
    var score: Int
    var seconds: Int
    
    init(date: Date = .now, score: Int, seconds: Int) {
        self.date = date
        self.score = score
        self.seconds = seconds
    }
}
