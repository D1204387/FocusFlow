//
//  GameModulePlaceholder.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/1.
//

import SwiftUI
import SwiftData

struct GameModulePlaceholder: View {
    @Environment(\.modelContext) private var ctx
    @Environment(ModuleCoordinator.self) private var co
    @State private var canStart = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("2048 獎勵").font(.title.bold())
                Text("開始一局需消耗 1 點能量。").foregroundStyle(.secondary)
                
                Button("開始遊戲（示範）") {
                    if co.spendEnergy(1) {
                            // 這裡嵌入同學 C 的 2048 View
                            // 遊戲結束後記錄：
                        ctx.insert(GameRecord(score: 512, seconds: 120))
                        co.apply(.gameFinished(score: 512, seconds: 120), modelContext: ctx)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("遊戲模組")
            .background(Theme.bg)
            .toolbarEnergy(title: "遊戲", tint: .orange)
        }

    }
}

