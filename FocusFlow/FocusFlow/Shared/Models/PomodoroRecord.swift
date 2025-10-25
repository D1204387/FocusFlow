//

import Foundation
import SwiftData

// MARK: - 資料模型：番茄紀錄
// PomodoroRecord 用於儲存每次番茄鐘的日期、專注分鐘、休息分鐘

@Model
final class PomodoroRecord {
    @Attribute(.unique) var id: UUID = UUID() // 唯一識別碼
    var date: Date
    var focus: Int   // 分鐘
    var rest: Int
    
    init(date: Date = .now, focus: Int, rest: Int) {
        self.id = UUID() // 初始化唯一識別碼
        self.date = date
        self.focus = focus
        self.rest = rest
    }
}
