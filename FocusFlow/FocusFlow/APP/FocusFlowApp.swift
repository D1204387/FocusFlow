    // APP/FocusFlowApp.swift
import SwiftUI
import SwiftData

@main
struct FocusFlowApp: App {
    // MARK: - 全域狀態物件
    
    /// 模組協調器，負責管理應用程式的流程和狀態
    @State private var coordinator = ModuleCoordinator()
    /// 應用程式設定，共享單例
    @State private var settings = AppSettings.shared
    
    // SwiftData ModelContainer
    /// 資料模型容器，包含應用程式的資料模型
    private let container: ModelContainer = {
        try! ModelContainer(for: RunningRecord.self,
                            PomodoroRecord.self,
                            GameRecord.self)
    }()
    
    var body: some Scene {
        WindowGroup {
            FocusFlowRootView()
                .environment(coordinator)
                .environment(settings)
                // Data Model
                .modelContainer(container)
                // 強制淺色模式
                .preferredColorScheme(.light)
        }
    }
}
