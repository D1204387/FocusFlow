    //
    //  ContentView.swift
    //  FocusFlow
    //
    //  Created by YiJou  on 2025/9/27.
    //

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        FocusFlowContentView()
    }
}
    
#Preview {
    ContentView()
        .modelContainer(for: [RunningRecord.self, PomodoroRecord.self,  GameRecord.self,
                              DailyStats.self],
                        inMemory: true)
}
