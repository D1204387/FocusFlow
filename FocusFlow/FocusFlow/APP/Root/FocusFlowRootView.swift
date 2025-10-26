//
//  FocusFlowRootView.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/1.
//

import SwiftUI
import SwiftData

struct FocusFlowRootView: View {
//    enum Tab { case running, focus, game, records, settings }
//    @State private var tab: Tab = .running
    @SceneStorage("ff.root.tabIndex") private var tabIndex : Int = 0
    
//    private var tabBinding: Binding<Tab> {
//        Binding(
//        get { Tab(rawValue: tabRaw) ?? .running }
//        set { tabRaw = $0.rawValue }
//        )
//    }
    
    var body: some View {
        TabView(selection: $tabIndex) {
            RunningView().tabItem { Label("跑步", systemImage: "figure.run") }
            FocusCycleView().tabItem { Label("專注", systemImage: "timer") } // 專注入口
 
            RecordsView().tabItem { Label("記錄", systemImage: "chart.bar") }
            GameView().tabItem { Label("遊戲", systemImage: "gamecontroller.fill") }

            
            SettingsView().tabItem { Label("設定", systemImage: "gear") }
        }
        .tint(.black)
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview("Root • Demo Data") {
        // 1) In-memory SwiftData
    let schema = Schema([RunningRecord.self, PomodoroRecord.self, GameRecord.self])
    let container = try! ModelContainer(
        for: schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext
    let cal = Calendar.current
    
        // 2) Seed some demo records (最近幾天)
    for i in 0..<7 {
        let day = cal.date(byAdding: .day, value: -i, to: .now)!
        if i % 2 == 0 {
            let r = RunningRecord(duration: Double([900, 1200, 1800].randomElement()!))
            r.date = day
            ctx.insert(r)
        }
        if i % 3 == 0 {
            let p = PomodoroRecord(focus: [20, 25, 30].randomElement()!, rest: 5)
            p.date = day
            ctx.insert(p)
        }
        if i % 4 == 0 {
            let g = GameRecord(score: [256, 512, 1024].randomElement()!, seconds: 90)
            g.date = day
            ctx.insert(g)
        }
    }
    
        // 3) Environments
    let co = ModuleCoordinator()
    co.energy = 3                                   // 一般情境：有能量
    let settings = AppSettings.shared    
    
    return FocusFlowRootView()
        .environment(co)
        .environment(settings)
        .modelContainer(container)
        .preferredColorScheme(.light)
}

#Preview("Root • Game Locked (energy = 0)") {
    let schema = Schema([RunningRecord.self, PomodoroRecord.self, GameRecord.self])
    let container = try! ModelContainer(
        for: schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let co = ModuleCoordinator()
    co.energy = 0                                   // 遊戲鎖定情境
    
    return FocusFlowRootView()
        .environment(co)
        .environment(AppSettings.shared)
        .modelContainer(container)
        .preferredColorScheme(.light)
}

