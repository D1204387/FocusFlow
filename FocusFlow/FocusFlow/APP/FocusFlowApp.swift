    // APP/FocusFlowApp.swift
import SwiftUI
import SwiftData

@main
struct FocusFlowApp: App {
    @State private var coordinator = ModuleCoordinator()
    @State private var settings = AppSettings.shared
    
    // SwiftData ModelContainer
    private let container: ModelContainer = {
        let schema = Schema([RunningRecord.self, PomodoroRecord.self, GameRecord.self])
        return try! ModelContainer(for: schema)
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
