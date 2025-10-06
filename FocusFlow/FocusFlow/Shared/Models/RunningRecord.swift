//

import Foundation
import SwiftData

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

