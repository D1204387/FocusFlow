import AppIntents
import WidgetKit

// MARK: - AppIntents：Widget 手動記錄
// ManualRecordIntent：在 Widget 上手動記錄一次專注/跑步/遊戲
// category: 記錄類型
// perform: 執行記錄動作

struct ManualRunIntent: AppIntent {
    static var title: LocalizedStringResource = "手動記錄一次"
    static var description = IntentDescription("在 Widget 上手動記錄一次專注/跑步/遊戲。")
    
    

//    @Parameter(title: "類型")
//    var category: String

    func perform() async throws -> some IntentResult {
        // 讀取並更新 App Group 的 UserDefaults
        guard let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow") else {
            return .result(value: "Failed to access UserDefaults")
        }
        let currentCount = userDefaults.integer(forKey: "todayCount")
        let currentMinutes = userDefaults.integer(forKey: "todayMinutes")
        
        // 添加 5 分鐘的跑步記錄
        userDefaults.set(currentCount + 1, forKey: "todayCount")
        userDefaults.set(currentMinutes + 5, forKey: "todayMinutes")
        userDefaults.synchronize()

        print("Widget 手動記錄一次，更新 todayCount 為 \(currentCount + 1)，todayMinutes 為 \(currentMinutes + 5)")
        
        // 通知 Widget 更新
        WidgetCenter.shared.reloadTimelines(ofKind: "FocusFlowRunningSummary")
        return .result(value: "Successfully recorded a run session")
    }
}
