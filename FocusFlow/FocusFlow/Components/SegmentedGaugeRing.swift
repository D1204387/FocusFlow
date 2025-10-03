import SwiftUI

    /// 12 點起點、順時針的分段式進度環（預設 60 刻度）
    /// - progress: 0...1（自動夾值）
    /// - tickCount: 刻度數（預設 60）
    /// - gapDegrees: 刻度間隙角度（預設 2°）
    /// - majorEvery: 每幾格做一個大刻度（預設 5；給 .max 代表不要加大刻度）
    /// - active/inactive: 已填/未填樣式（顏色或漸層）
    /// - content: 中心自訂內容
public struct SegmentedGaugeRing<Center: View>: View {
        // Inputs
    private let progress: Double
    private let size: CGFloat
    private let tickCount: Int
    private let tickSize: CGSize
    private let innerPadding: CGFloat
    private let startAngle: Angle
    private let gapDegrees: Double
    private let majorEvery: Int
    private let majorScale: CGFloat
    private let activeStyle: AnyShapeStyle
    private let inactiveStyle: AnyShapeStyle
    @ViewBuilder private let centerContent: Center
    
    public init(
        progress: Double,
        size: CGFloat = 300,
        tickCount: Int = 60,
        tickSize: CGSize = .init(width: 7, height: 30),
        innerPadding: CGFloat = 16,
        startAngle: Angle = .degrees(-90),     // 12 點
        gapDegrees: Double = 2.0,              // ⬅️ 刻度間隙
        majorEvery: Int = 5,
        majorScale: CGFloat = 1.35,
        active: some ShapeStyle,
        inactive: some ShapeStyle,
        @ViewBuilder content: () -> Center
    ) {
        self.progress = progress < 0 ? 0 : (progress > 1 ? 1 : progress)
        self.size = size
        self.tickCount = max(1, tickCount)
        self.tickSize = tickSize
        self.innerPadding = innerPadding
        self.startAngle = startAngle
        self.gapDegrees = max(0, gapDegrees)
        self.majorEvery = majorEvery < 1 ? .max : majorEvery
        self.majorScale = max(1, majorScale)
        self.activeStyle = AnyShapeStyle(active)
        self.inactiveStyle = AnyShapeStyle(inactive)
        self.centerContent = content()
    }
    
    public var body: some View {
        ZStack {
                // 背景軌道（柔和一圈，讓未填區更自然）
            Circle()
                .stroke(Color(.systemGray5), lineWidth: tickSize.height * 0.65)
                .frame(width: size - (tickSize.height + innerPadding) * 2)
            
                // 刻度
            ForEach(0..<tickCount, id: \.self) { i in
                tick(at: i)
            }
            
                // 中心
            centerLayer
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .animation(.snappy(duration: 0.30), value: progress)
    }
    
        // MARK: - Layers
    
    private var centerLayer: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: innerDiameter)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            centerContent
        }
    }
    
    private func tick(at index: Int) -> some View {
        let anglePerTick = 360.0 / Double(tickCount)
        let angle = startAngle + .degrees(Double(index) * anglePerTick)
        
            // 以 floor 取得「已通過的完整刻度數」
        let filledCount = Int((progress * Double(tickCount)).rounded(.down))
        let isFilled = index < max(0, min(filledCount, tickCount))
        
            // 大刻度：每 majorEvery 個放大高度
        let isMajor = majorEvery != .max && (index % majorEvery == 0)
        let h = isMajor ? tickSize.height * majorScale : tickSize.height
        
            // 刻度中心到圓心的半徑
        let r = size / 2 - innerPadding - h / 2
        
        return Capsule(style: .continuous)
            .fill(isFilled ? activeStyle : inactiveStyle) // 用 fill 比 foregroundStyle 穩
            .frame(width: tickSize.width, height: h)
            .offset(y: -r)
            .rotationEffect(angle)
            .drawingGroup() // 抗鋸齒
    }
    
        // MARK: - Derived
    
    private var innerDiameter: CGFloat {
            // 讓刻度至少露出 65% 高度（避免中心白圓把刻度吃光）
        size - (tickSize.height * majorScale * 0.65 + innerPadding) * 2
    }
}

    /// 簡單的扇形（用於切縫）
private struct Sector: Shape {
    let angle: Double
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.addArc(center: center,
                 radius: radius,
                 startAngle: .degrees(-angle/2),
                 endAngle: .degrees(angle/2),
                 clockwise: false)
        return p
    }
}

