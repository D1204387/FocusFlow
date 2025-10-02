//
//  FocusFlowRootView.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/1.
//

import SwiftUI
import SwiftData

struct FocusFlowRootView: View {
    enum Tab { case running, focus, game, records, settings }
    @State private var tab: Tab = .running
    
    var body: some View {
        TabView(selection: $tab) {
            RunningView().tabItem { Label("跑步", systemImage: "figure.run") }
            FocusCycleView().tabItem { Label("專注", systemImage: "timer") }   // ← 這裡
            RecordsView().tabItem { Label("記錄", systemImage: "chart.bar") }
            GameModulePlaceholder().tabItem { Label("遊戲", systemImage: "gamecontroller") }
            SettingsView().tabItem { Label("設定", systemImage: "gear") }
        }
        .tint(.black)
        .background(Color.white.ignoresSafeArea())
    }
}
