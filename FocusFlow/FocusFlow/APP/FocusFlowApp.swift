    // APP/FocusFlowApp.swift
import SwiftUI
import SwiftData

@main
struct FocusFlowApp: App {
    @State private var coordinator = ModuleCoordinator()
    
    private let container: ModelContainer = {
        let schema = Schema([RunningRecord.self, PomodoroRecord.self, GameRecord.self])
        return try! ModelContainer(for: schema)
    }()
    
    init() {
        migrateUserDefaultsIfNeeded()   // ← 加這行
    }
    
    var body: some Scene {
        WindowGroup {
            FocusFlowRootView()
                .environment(coordinator)
                .modelContainer(container)
                .preferredColorScheme(.light)
        }
    }
}
