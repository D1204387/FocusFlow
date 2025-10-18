import AppIntents

// MARK: - AppIntents：Widget 手動記錄
// ManualRecordIntent：在 Widget 上手動記錄一次專注/跑步/遊戲
// category: 記錄類型
// perform: 執行記錄動作

struct ManualRecordIntent: AppIntent {
    static var title: LocalizedStringResource = "手動記錄一次"
    static var description = IntentDescription("在 Widget 上手動記錄一次專注/跑步/遊戲。")

    @Parameter(title: "類型")
    var category: String

    func perform() async throws -> some IntentResult {
        // 這裡可以根據 category 來記錄不同類型
        // 例如呼叫 Shared/FocusFlowShared.swift 的方法
        // 目前僅示範 log
        print("手動記錄: \(category)")
        return .result()
    }
}
