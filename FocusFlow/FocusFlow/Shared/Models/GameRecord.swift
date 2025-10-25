//

import Foundation
import SwiftData

// MARK: - 資料模型：遊戲紀錄
// GameRecord 用於儲存每次遊戲的日期、分數、秒數

@Model
final class GameRecord {
    @Attribute(.unique) var id: UUID = UUID() // 唯一識別碼
    var date: Date
    var score: Int
    var seconds: Int
    
    init(date: Date = .now, score: Int, seconds: Int) {
        self.id = UUID() // 初始化唯一識別碼
        self.date = date
        self.score = score
        self.seconds = seconds
    }
}
