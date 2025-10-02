import SwiftUI

    /// 由許多小刻度組成的圓形進度環（12 點鐘方向為起點）
    /// - 支援：顏色或漸層（ShapeStyle）、刻度數、尺寸、中心自訂內容
public struct SegmentedGaugeRing<Center: View>: View {
        // Inputs
    private let progress: Double      // 0...1
    private let size: CGFloat
    private let tickCount: Int
    private let tickSize: CGSize
    private let innerPadding: CGFloat
    private let startAngle: Angle
    private let activeStyle: AnyShapeStyle
    private let inactiveStyle: AnyShapeStyle
    @ViewBuilder private let centerContent: Center
    
    public init(
        progress: Double,
        size: CGFloat = 300,
        tickCount: Int = 60,
        tickSize: CGSize = .init(width: 6, height: 28),
        innerPadding: CGFloat = 16,
        startAngle: Angle = .degrees(-90),
        active: some ShapeStyle,
        inactive: some ShapeStyle,
        @ViewBuilder content: () -> Center
    ) {
            // 這裡直接手動夾值，不用 min/max 或 clamped 擴充，避免命名衝突
        self.progress = progress < 0 ? 0 : (progress > 1 ? 1 : progress)
        self.size = size
        self.tickCount = max(1, tickCount)
        self.tickSize = tickSize
        self.innerPadding = innerPadding
        self.startAngle = startAngle
        self.activeStyle = AnyShapeStyle(active)
        self.inactiveStyle = AnyShapeStyle(inactive)
        self.centerContent = content()
    }
    
    public var body: some View {
        ZStack {
            ForEach(0..<tickCount, id: \.self) { i in
                tick(at: i)
            }
            centerLayer
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .animation(.snappy(duration: 0.3), value: progress)
    }
    
        // MARK: - Layers
    private var centerLayer: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: size - (tickSize.height + innerPadding) * 2)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            
            centerContent
        }
    }
    
    private func tick(at index: Int) -> some View {
        let anglePerTick = 360.0 / Double(tickCount)
        let angle = startAngle + .degrees(Double(index) * anglePerTick)
        let raw = Int(round(progress * Double(tickCount)))
        let filled = raw < 0 ? 0 : (raw > tickCount ? tickCount : raw)
        
        return Capsule(style: .continuous)
            .foregroundStyle(index < filled ? activeStyle : inactiveStyle)
            .frame(width: tickSize.width, height: tickSize.height)
            .offset(y: -radius)
            .rotationEffect(angle)
            .drawingGroup()
    }
    
        // MARK: - Derived
    private var radius: CGFloat {
        size / 2 - innerPadding - tickSize.height / 2
    }
}

#Preview {
    VStack(spacing: 20) {
        SegmentedGaugeRing(
            progress: 0.42,
            size: 280,
            tickCount: 60,
            tickSize: .init(width: 7, height: 30),
            innerPadding: 18,
            active: LinearGradient(colors: [.green, .teal], startPoint: .top, endPoint: .bottom),
            inactive: Color(.systemGray4)
        ) {
            VStack(spacing: 6) {
                Text("01:23").font(.system(size: 36, weight: .bold, design: .rounded)).monospacedDigit()
                Text("剩餘 23:37 • 42%").font(.footnote).foregroundStyle(.secondary)
            }
        }
        SegmentedGaugeRing(
            progress: 0.75,
            size: 220,
            tickCount: 48,
            tickSize: .init(width: 6, height: 22),
            innerPadding: 14,
            active: Color.blue,
            inactive: Color(.systemGray4)
        ) { EmptyView() }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

