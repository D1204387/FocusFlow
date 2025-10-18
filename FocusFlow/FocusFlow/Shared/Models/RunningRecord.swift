//

import Foundation
import SwiftData

// MARK: - 資料模型：跑步紀錄
// RunningRecord 用於儲存每次跑步的日期、持續秒數、步頻（可選）
// minutes: 由 duration 換算的分鐘數

@Model
final class RunningRecord {
    var date: Date
    var duration: TimeInterval   // 秒
    var bpm: Int?                // 可選：當時的節拍/步頻
    
    init(date: Date = .now, duration: TimeInterval, bpm: Int? = nil) {
        self.date = date
        self.duration = duration
        self.bpm = bpm
    }
    
    @Transient var minutes: Int { Int(duration/60) }
}
