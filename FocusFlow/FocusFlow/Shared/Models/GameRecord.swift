//

import Foundation
import SwiftData

// MARK: - 資料模型：遊戲紀錄
// GameRecord 用於儲存每次遊戲的日期、分數、秒數

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
