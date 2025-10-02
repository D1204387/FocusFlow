import SwiftUI

    /// 右上角能量 + 可選標題（標題可傳 nil）
struct AppTopBar: View {
    @Environment(ModuleCoordinator.self) private var co
    let title: String?
    let tint: Color   // 跑步傳 Theme.Run.solid；專注傳 Theme.Focus.solid
    
    var body: some View {
        HStack {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .imageScale(.medium)
                    .foregroundStyle(tint)
                Text("能量 \(co.energy)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.pillBG)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.cardStroke, lineWidth: 1))
        }
    }
}


