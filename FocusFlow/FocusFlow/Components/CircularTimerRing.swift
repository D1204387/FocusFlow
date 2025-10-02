import SwiftUI

    /// 可客製的分段式圓形計時環（支援中心自訂內容）
    /// - Parameters:
    ///   - progress: 0...1
    ///   - size: 直徑
    ///   - ringWidth: 刻度粗細
    ///   - tickCount: 刻度數量（預設 60）
    ///   - gapDegrees: 刻度與刻度間的角度間隙（度）
    ///   - active: 進度顏色
    ///   - inactive: 未完成顏色
    ///   - center: 中央自訂內容（如時間、剩餘、百分比等）
struct CircularTimerRing<Center: View>: View {
    let progress: Double
    let size: CGFloat
    let ringWidth: CGFloat
    let tickCount: Int
    let gapDegrees: Double
    let active: Color
    let inactive: Color
    let center: () -> Center
    
    init(
        progress: Double,
        size: CGFloat = 320,
        ringWidth: CGFloat = 12,
        tickCount: Int = 60,
        gapDegrees: Double = 3,
        active: Color,
        inactive: Color,
        @ViewBuilder center: @escaping () -> Center
    ) {
        self.progress = max(0, min(1, progress))
        self.size = size
        self.ringWidth = ringWidth
        self.tickCount = max(1, tickCount)
        self.gapDegrees = max(0, gapDegrees)
        self.active = active
        self.inactive = inactive
        self.center = center
    }
    
    var body: some View {
        ZStack {
                // 背景軌道（淡）
            Circle()
                .stroke(Theme.track, lineWidth: ringWidth)
            
                // 分段刻度
            ZStack {
                let filled = Int(round(progress * Double(tickCount)))
                ForEach(0..<tickCount, id: \.self) { i in
                    let angle = (Double(i) / Double(tickCount)) * 360.0
                    Capsule(style: .continuous)
                        .fill(i < filled ? active : inactive)
                        .frame(width: ringWidth, height: tickHeight)
                        .offset(y: -(size/2 - tickHeight/2 - ringWidth/2))
                        .rotationEffect(.degrees(angle))
                }
            }
            
                // 中央自訂內容
            center()
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.25), value: progress)
    }
    
        // 刻度長度：用 size 的比例算，外觀比較穩定
    private var tickHeight: CGFloat {
        max(20, size * 0.11)
    }
}
