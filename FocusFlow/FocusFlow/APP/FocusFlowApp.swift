    // APP/FocusFlowApp.swift
import SwiftUI
import SwiftData
import WidgetKit

@MainActor
@main
struct FocusFlowApp: App {
        // MARK: - 全域狀態物件
    
        /// 模組協調器，負責管理應用程式的流程和狀態
    @State private var coordinator = ModuleCoordinator()
        /// 應用程式設定，共享單例
    private let settings = AppSettings.shared
    
        // SwiftData ModelContainer
        /// 資料模型容器，包含應用程式的資料模型
    private let container: ModelContainer
    
    init() {
        guard let container = try? ModelContainer(
            for: RunningRecord.self,
            PomodoroRecord.self,
            GameRecord.self
        ) else {
            fatalError("Unable to initialize ModelContainer")
        }
        self.container = container
    }
      
        // 🔧 新增：計算今日跑步時間的輔助函式
    private func calculateTodayRunningMinutes(context: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let request = FetchDescriptor<RunningRecord>(
            predicate: #Predicate { record in
                record.date >= today && record.date < tomorrow
            }
        )
        
        do {
            let records = try context.fetch(request)
            return records.reduce(0) { (total: Int, record: RunningRecord) in
                total + Int(record.duration / 60) // 轉換為分鐘
            }
        } catch {
            print("計算今日跑步時間失敗: \(error)")
            return 0
        }
    }
    
        /// 完整同步所有資料到 Widget（啟動時、背景返回時使用）
    private func syncAllDataToWidgets() {
        let context = container.mainContext
        let recordsStore = RecordsStore(context: context)
        
            // 同步所有統計資料
        recordsStore.syncTodayStatsToAppGroup()
        recordsStore.syncWeekStatsToAppGroup()
        
            // 同步當前跑步狀態
        let runStore = RunStore.load()
        let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow")
        
        if let phaseData = try? JSONEncoder().encode(runStore.phase) {
            userDefaults?.set(phaseData, forKey: "currentRunningPhase")
        }
       
        WidgetCenter.shared.reloadAllTimelines()
     
    }
        // 🔧 新增：即時同步跑步狀態到 Widget
    private func syncRunningStateToWidget(phase: RunningState.Phase) {
        let userDefaults = UserDefaults(suiteName: "group.com.buildwithharry.focusflow")
        
            // 同步狀態
        if let phaseData = try? JSONEncoder().encode(phase) {
            userDefaults?.set(phaseData, forKey: "currentRunningPhase")
        }
        
            // 如果是結束跑步，更新統計
        if phase == .idle {
            syncAllDataToWidgets()
        }
        
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 已同步跑步狀態到 Widget: \(phase)")
    }
       
    var body: some Scene {
        WindowGroup {
            FocusFlowRootView()
                .environment(coordinator)
                .environment(settings)
                // Data Model
                .modelContainer(container)
                // 強制淺色模式
                .preferredColorScheme(.light)
                .onAppear {
                        // 每次啟動 App 時同步資料到 Widget
                    syncAllDataToWidgets()
                }
                // 🔧 新增：監聽跑步狀態變化
                .onReceive(NotificationCenter.default.publisher(for: .runningPhaseChanged)) { notification in
                    if let phase = notification.object as? RunningState.Phase {
                        syncRunningStateToWidget(phase: phase)
                    }
                }
                .onChange(of: settings.focusMinutes) {  WidgetCenter.shared.reloadTimelines(ofKind: "FocusFlowPomodoroWidget")
                }
        }
    }
}

    // ✅ 新增：通知名稱擴展
extension Notification.Name {
    static let runningPhaseChanged = Notification.Name("runningPhaseChanged")
}
        


