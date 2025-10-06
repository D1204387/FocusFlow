import SwiftUI

    /// App 統一按鈕樣式：
    /// - primary(填色)  : 實心主色白字
    /// - secondary(外框): 白底主色外框與字
    /// - tertiary(幽靈) : 淡灰膠囊底、主色字（次動作）
struct PrimaryButtonStyle: ButtonStyle {
    
    enum Kind {
        case primary(Color)    // 實心
        case secondary(Color)  // 外框
        case tertiary(Color)   // 幽靈/淡底
    }
    
    enum Size { case regular, large }
    
    var kind: Kind
    var size: Size = .regular
    
    init(_ kind: Kind, size: Size = .regular) {
        self.kind = kind
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let metrics = metricsForSize(size)
        let pressScale: CGFloat = configuration.isPressed ? 0.98 : 1.0
        let (bg, stroke, fg) = palette(for: kind)
        
        return configuration.label
            .font(metrics.font)
            .foregroundStyle(fg)
            .padding(.horizontal, metrics.hPadding)
            .padding(.vertical, metrics.vPadding)
            .background(bg)
            .overlay {
                if let stroke {
                    Capsule().stroke(stroke, lineWidth: 1)
                }
            }
            .clipShape(Capsule())
            .scaleEffect(pressScale)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
    
    private func palette(for kind: Kind) -> (bg: some ShapeStyle, stroke: Color?, fg: Color) {
        switch kind {
        case .primary(let tint):
            return (bg: tint, stroke: nil, fg: .white)
        case .secondary(let tint):
            return (bg: Color.white, stroke: tint, fg: tint)
        case .tertiary(let tint):
            return (bg: Theme.pillBG, stroke: Theme.cardStroke, fg: tint)
        }
    }
    
    private func metricsForSize(_ size: Size) -> (hPadding: CGFloat, vPadding: CGFloat, font: Font) {
        switch size {
        case .regular: return (16, 10, .callout.weight(.semibold))
        case .large:   return (20, 14, .headline.weight(.semibold))
        }
    }
}

