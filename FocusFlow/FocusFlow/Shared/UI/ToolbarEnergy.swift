    // ToolbarEnergy.swift
import SwiftUI

    /// 右上角能量顯示（共用）+ 能量獲得提示
struct ToolbarEnergy: ToolbarContent {
    @Environment(ModuleCoordinator.self) private var co
    let tint: Color
    
    @State private var lastEnergy: Int = 0
    @State private var gain: Int = 0
    @State private var showGain: Bool = false
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            ZStack(alignment: .topTrailing) {
                pill
                    .scaleEffect(showGain ? 1.06 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: showGain)
                
                if showGain {
                    Text("+\(gain)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(tint)
                        .clipShape(Capsule())
                        .offset(y: -26)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .shadow(color: tint.opacity(0.25), radius: 6, x: 0, y: 3)
                }
            }
            .onAppear { lastEnergy = co.energy }
            .onChange(of: co.energy) { _, newValue in
                let delta = newValue - lastEnergy
                lastEnergy = newValue
                guard delta > 0 else { return }
                gain = delta
                withAnimation(.snappy) { showGain = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.snappy) { showGain = false }
                }
            }
            .accessibilityLabel("可用能量 \(co.energy)")
        }
    }
    
    private var pill: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill").foregroundStyle(tint)
            Text("能量 \(co.energy)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Theme.pillBG)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.cardStroke, lineWidth: 1))
    }
}

extension View {
        /// 方便呼叫
    func toolbarEnergy(title: String, tint: Color) -> some View {
        self.navigationTitle(title)
            .toolbar { ToolbarEnergy(tint: tint) }
    }
}
