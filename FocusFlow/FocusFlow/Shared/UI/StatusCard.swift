import SwiftUI

    // 小膠囊（統一風格）
struct InfoChip: View {
    let icon: String?     // SFSymbol 名稱；用 emoji 就把 icon 傳 nil，文字自己帶 emoji
    let text: String
    let tint: Color
    
    init(_ text: String, icon: String? = nil, tint: Color = Theme.text) {
        self.text = text
        self.icon = icon
        self.tint = tint
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .imageScale(.small)
                    .foregroundStyle(tint)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.pillBG)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.cardStroke, lineWidth: 1))
    }
}

    // 統一摘要卡：傳入多行 row
struct StatusSummaryCard<Row: View>: View {
    @ViewBuilder var rows: Row
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            rows
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .softShadow()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
    }
}


