//
//  ImprovedSegmentedGaugeRing.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/3.
//
import SwiftUI
import UIKit 

    // MARK: - 改進版分段式進度環
public struct ImprovedSegmentedGaugeRing<Center: View>: View {
        // MARK: - Properties
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
    private let animationEnabled: Bool
    private let hapticEnabled: Bool
    @ViewBuilder private let centerContent: Center
    
        // 🔧 修正：儲存上次進度以觸發震動
    @State private var lastProgress: Double = 0
    
    public init(
        progress: Double,
        size: CGFloat = 300,
        tickCount: Int = 60,
        tickSize: CGSize = .init(width: 7, height: 30),
        innerPadding: CGFloat = 16,
        startAngle: Angle = .degrees(-90),
        gapDegrees: Double = 2.0,
        majorEvery: Int = 5,
        majorScale: CGFloat = 1.35,
        animationEnabled: Bool = true,  // 🆕 可控制動畫
        hapticEnabled: Bool = true,     // 🆕 可控制震動
        active: some ShapeStyle,
        inactive: some ShapeStyle,
        @ViewBuilder content: () -> Center
    ) {
        self.progress = min(1, max(0, progress))  // 🔧 更簡潔的夾值
        self.size = size
        self.tickCount = max(1, tickCount)
        self.tickSize = tickSize
        self.innerPadding = innerPadding
        self.startAngle = startAngle
        self.gapDegrees = max(0, gapDegrees)
        self.majorEvery = majorEvery < 1 ? .max : majorEvery
        self.majorScale = max(1, majorScale)
        self.animationEnabled = animationEnabled
        self.hapticEnabled = hapticEnabled
        self.activeStyle = AnyShapeStyle(active)
        self.inactiveStyle = AnyShapeStyle(inactive)
        self.centerContent = content()
    }
    
    public var body: some View {
        ZStack {
                // 背景軌道
            backgroundTrack
            
                // 刻度層
            ticksLayer
            
                // 中心內容
            centerLayer
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .animation(animationEnabled ? animation : nil, value: progress)
        .onChange(of: progress) { _, newValue in
            handleProgressChange(newValue)
        }
    }
    
        // MARK: - Subviews
    
    private var backgroundTrack: some View {
        Circle()
            .stroke(Color(.systemGray5), lineWidth: trackWidth)
            .frame(width: trackDiameter)
    }
    
    private var ticksLayer: some View {
            // 🔧 使用 Canvas 提升效能（iOS 15+）
#if swift(>=5.7)
        if #available(iOS 15.0, *) {
            return AnyView(
                Canvas { context, size in
                    drawTicks(in: context, size: size)
                }
                    .frame(width: self.size, height: self.size)
            )
        } else {
            return AnyView(
                ForEach(0..<tickCount, id: \.self) { i in
                    tick(at: i)
                }
            )
        }
#else
        return AnyView(
            ForEach(0..<tickCount, id: \.self) { i in
                tick(at: i)
            }
        )
#endif
    }
    
    private var centerLayer: some View {
        ZStack {
                // 🔧 漸層背景更有層次
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: innerDiameter, height: innerDiameter)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            
            centerContent
        }
    }
    
        // MARK: - Drawing Methods
    
    private func tick(at index: Int) -> some View {
        let angle = tickAngle(at: index)
        let isFilled = isTickFilled(at: index)
        let isMajor = isTickMajor(at: index)
        let h = isMajor ? tickSize.height * majorScale : tickSize.height
        let r = size / 2 - innerPadding - h / 2
        
        return Capsule(style: .continuous)
            .fill(isFilled ? activeStyle : inactiveStyle)
            .frame(width: tickSize.width, height: h)
            .offset(y: -r)
            .rotationEffect(angle)
            .drawingGroup()
            // 🆕 加入縮放動畫
            .scaleEffect(isFilled ? 1.0 : 0.95)
    }
    
    @available(iOS 15.0, *)
    private func drawTicks(in context: GraphicsContext, size: CGSize) {
        for i in 0..<tickCount {
            var ctx = context
            let angle = tickAngle(at: i)
            let isFilled = isTickFilled(at: i)
            let isMajor = isTickMajor(at: i)
            let h = isMajor ? tickSize.height * majorScale : tickSize.height
            let r = self.size / 2 - innerPadding - h / 2
            
            ctx.translateBy(x: size.width / 2, y: size.height / 2)
            ctx.rotate(by: angle)
            
            let rect = CGRect(
                x: -tickSize.width / 2,
                y: -r - h / 2,
                width: tickSize.width,
                height: h
            )
            
            let path = Capsule(style: .continuous).path(in: rect)
            ctx.fill(
                path,
                with: isFilled ? .style(activeStyle) : .style(inactiveStyle)
            )
        }
    }
    
        // MARK: - Helper Methods
    
    private func tickAngle(at index: Int) -> Angle {
        let anglePerTick = 360.0 / Double(tickCount)
        return startAngle + .degrees(Double(index) * anglePerTick)
    }
    
    private func isTickFilled(at index: Int) -> Bool {
        let filledCount = Int((progress * Double(tickCount)).rounded(.down))
        return index < max(0, min(filledCount, tickCount))
    }
    
    private func isTickMajor(at index: Int) -> Bool {
        return majorEvery != .max && (index % majorEvery == 0)
    }
    
    private func handleProgressChange(_ newProgress: Double) {
            // 🆕 震動回饋
        if hapticEnabled {
            let oldMilestone = Int(lastProgress * 10)
            let newMilestone = Int(newProgress * 10)
            
            if newMilestone > oldMilestone {
                    // 每 10% 震動
                HapticFeedback.impact(.light)
            }
            
            if newProgress >= 1.0 && lastProgress < 1.0 {
                    // 完成時強震動
                HapticFeedback.notification(.success)
            }
        }
        
        lastProgress = newProgress
    }
    
        // MARK: - Computed Properties
    
    private var innerDiameter: CGFloat {
        size - (tickSize.height * majorScale * 0.65 + innerPadding) * 2
    }
    
    private var trackDiameter: CGFloat {
        size - (tickSize.height + innerPadding) * 2
    }
    
    private var trackWidth: CGFloat {
        tickSize.height * 0.65
    }
    
    private var animation: Animation {
        .snappy(duration: 0.30)
    }
}

    // MARK: - 震動回饋輔助
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

    // MARK: - 預覽範例
struct SegmentedGaugeRingExample: View {
    @State private var progress: Double = 0.65
    @State private var style: Int = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Text("分段式進度環測試")
                .font(.largeTitle)
                .fontWeight(.bold)
            
                // 樣式選擇
            Picker("樣式", selection: $style) {
                Text("漸層").tag(0)
                Text("單色").tag(1)
                Text("彩虹").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
                // 進度環展示
            Group {
                switch style {
                case 0:
                    gradientRing
                case 1:
                    solidRing
                case 2:
                    rainbowRing
                default:
                    gradientRing
                }
            }
            
                // 控制區
            VStack(spacing: 20) {
                    // 進度滑桿
                VStack(alignment: .leading, spacing: 8) {
                    Text("進度：\(Int(progress * 100))%")
                        .font(.headline)
                    
                    Slider(value: $progress, in: 0...1)
                        .accentColor(.blue)
                }
                
                    // 快速按鈕
                HStack(spacing: 12) {
                    ForEach([0, 25, 50, 75, 100], id: \.self) { value in
                        Button("\(value)%") {
                            withAnimation {
                                progress = Double(value) / 100
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                    // 動畫按鈕
                Button("動畫演示") {
                    animateProgress()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(15)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
    
        // MARK: - 不同樣式的進度環
    
    private var gradientRing: some View {
        ImprovedSegmentedGaugeRing(
            progress: progress,
            active: LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            inactive: Color(.systemGray5)
        ) {
            VStack(spacing: 8) {
                Text("\(Int(progress * 100))")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("完成度")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var solidRing: some View {
        ImprovedSegmentedGaugeRing(
            progress: progress,
            tickCount: 48,
            majorEvery: 6,
            active: Color.green,
            inactive: Color(.systemGray5)
        ) {
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                Text("\(Int(progress * 100))%")
                    .font(.title)
                    .fontWeight(.semibold)
            }
        }
    }
    
    private var rainbowRing: some View {
        ImprovedSegmentedGaugeRing(
            progress: progress,
            tickCount: 72,
            tickSize: CGSize(width: 5, height: 25),
            majorEvery: 12,
            active: AngularGradient(
                colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                center: .center
            ),
            inactive: Color(.systemGray6)
        ) {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
    }
    
        // MARK: - Helper
    
    private func animateProgress() {
        withAnimation(.linear(duration: 3)) {
            progress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeInOut) {
                progress = 0.0
            }
        }
    }
}

    // MARK: - 效能測試視圖
struct PerformanceTestView: View {
    @State private var rings: [Double] = Array(repeating: 0, count: 20)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(0..<rings.count, id: \.self) { index in
                    ImprovedSegmentedGaugeRing(
                        progress: rings[index],
                        size: 100,
                        tickCount: 30,
                        tickSize: CGSize(width: 3, height: 10),
                        innerPadding: 5,
                        majorEvery: 5,
                        animationEnabled: true,
                        hapticEnabled: false,
                        active: Color.blue,
                        inactive: Color.gray.opacity(0.3)
                    ) {
                        Text("\(Int(rings[index] * 100))")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .onTapGesture {
                        withAnimation {
                            rings[index] = Double.random(in: 0...1)
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
                // 隨機初始化
            for i in 0..<rings.count {
                rings[i] = Double.random(in: 0...1)
            }
        }
    }
}

#Preview("基本範例") {
    SegmentedGaugeRingExample()
}

#Preview("效能測試") {
    PerformanceTestView()
}
