import SwiftUI

    /// 右上角能量顯示（共用）
struct ToolbarEnergy: ToolbarContent {
    @Environment(ModuleCoordinator.self) private var co
    let tint: Color
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
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
            .accessibilityLabel("可用能量 \(co.energy)")
        }
    }
}

extension View {
        /// 方便呼叫
    func toolbarEnergy(title: String, tint: Color) -> some View {
        self.navigationTitle(title)
            .toolbar { ToolbarEnergy(tint: tint) }
    }
}


