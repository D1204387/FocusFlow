import AppIntents
import WidgetKit

// MARK: - AppIntents：Widget 手動刷新
// RefreshWidgetIntent：立即刷新桌面小工具資料
// perform: 執行刷新動作
struct RefreshWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "手動刷新小工具"
    static var description = IntentDescription("立即刷新桌面小工具資料。")

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
