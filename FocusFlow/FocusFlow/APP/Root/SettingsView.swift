import SwiftUI

/// 統一設定頁（淺色系）
/// - 跑步：藍 / 專注：綠
/// - 右上角顯示可用點數（toolbarEnergy）
struct SettingsView: View {
        // MARK: - Properties
    @Environment(AppSettings.self) private var settings
    
    var body: some View {
        @Bindable var settings = settings
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard(title: "音場 & 節拍器") {
                        ToggleRow(title: "背景音樂", isOn: $settings.bgmOn, symbol: "music.note.list")
                        Divider()
                        ToggleRow(title: "節拍器", isOn: $settings.metronomeOn, symbol: "metronome")
                        if settings.metronomeOn {
                            HStack(spacing: 12) {
                                Label("BPM", systemImage: "waveform.path.ecg")
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(Theme.text)
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(settings.metronomeBPM)
                                        },
                                        set: { newValue in
                                            let step = 5.0
                                            let roundedValue = (newValue / step).rounded() * step
                                            settings.metronomeBPM = Int(
                                                roundedValue
                                            ) }
                                    ),
                                    in: 60...220,
                                    step: 5
                                )
                                    
                                        .tint(Theme.Run.solid)
                                    
                                    Text("\(settings.metronomeBPM)")
                                        .font(.title3.monospacedDigit())
                                        .foregroundStyle(Theme.text)
                                        .frame(width: 56, alignment: .trailing)
                                }
                                .accessibilityLabel("節拍器 BPM \(settings.metronomeBPM)")
                            }
                        }
                        
                            // MARK: 跑步
                        SectionCard(title: "慢跑") {
                            HStack {
                                Label("目標時間", systemImage: "figure.run")
                                    .foregroundStyle(Theme.text)
                                Spacer()
                                Stepper("", value: $settings.runTargetMinutes, in: 1...120, step: 1)
                                    .labelsHidden()
                                Text("\(settings.runTargetMinutes) 分鐘")
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(Theme.Run.solid)
                            }
                            Divider()
                            ToggleRow(title: "震動回饋", isOn: $settings.hapticsOn, symbol: "iphone.radiowaves.left.and.right")
                        }
                        
                            // MARK: 番茄（工作 / 休息 / 循環）
                        SectionCard(title: "專注番茄") {
                            timeRow(title: "工作時間",
                                    value: $settings.focusMinutes,
                                    tint: Theme.Focus.solid,
                                    range: 5...120,
                                    step: 5)                    // ✅ 5 分鐘一格
                            Divider()
                            timeRow(title: "短休息",
                                    value: $settings.shortBreakMinutes,
                                    tint: Theme.Focus.solid,
                                    range: 1...30)
                            Divider()
                            timeRow(title: "長休息",
                                    value: $settings.longBreakMinutes,
                                    tint: Theme.Focus.solid,
                                    range: 5...60)
                            Divider()
                            HStack {
                                Label("每幾顆後長休", systemImage: "record.circle")
                                    .foregroundStyle(Theme.text)
                                Spacer()
                                Stepper("", value: $settings.roundsBeforeLongBreak, in: 2...8, step: 1)
                                    .labelsHidden()
                                Text("\(settings.roundsBeforeLongBreak) 顆")
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(Theme.Focus.solid)
                            }
                            Divider()
                            ToggleRow(title: "自動續播下一段", isOn: $settings.autoContinue, symbol: "arrow.triangle.2.circlepath")
                        }
                        
                            // MARK: 恢復預設
                        SectionCard(title: "其他") {
                            Button("全部恢復預設") {
                                settings.reset()
                            }
                            .buttonStyle(PrimaryButtonStyle(.secondary(.gray)))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                .background(Theme.bg)
                .navigationTitle("設定")
                .toolbarEnergy(title: "設定", tint: .gray)
            }
        }
                // MARK: - Helpers
        
        @ViewBuilder
        private func timeRow(title: String,
                             value: Binding<Int>,
                             tint: Color,
                             range: ClosedRange<Int>,
                             step: Int = 1) -> some View {       // ✅
            HStack {
                Label(title, systemImage: "timer")
                    .foregroundStyle(Theme.text)
                Spacer()
                Stepper("", value: value, in: range, step: step)
                    .labelsHidden()
                Text("\(value.wrappedValue) 分鐘")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(tint)
            }
        }
    }
    
        // MARK: - 小元件（卡片與切換列）
    private struct SectionCard<Content: View>: View {
        let title: String
        @ViewBuilder var content: Content
        
        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                content
            }
            .padding(16)
            .background(Theme.bg)
            .overlay{RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.cardStroke, lineWidth: 1)
                    .allowsHitTesting(false)  // 卡片本身不響應點擊
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // 讓內部元件可點擊
        }
    }
    
    private struct ToggleRow: View {
        let title: String
        @Binding var isOn: Bool
        let symbol: String
        
        var body: some View {
            HStack {
                Label(title, systemImage: symbol)
                    .foregroundStyle(Theme.text)
                Spacer()
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.accentColor)
            }
        }
    }

#Preview("設定（預覽）") {
        // 用同一份設定物件做預覽
    let s = AppSettings.shared
        // 示範值（可改）
    s.bgmOn = true
    s.metronomeOn = true
    s.metronomeBPM = 180
    s.runTargetMinutes = 20
    s.hapticsOn = true
    
    s.focusMinutes = 25
    s.shortBreakMinutes = 5
    s.longBreakMinutes = 15
    s.roundsBeforeLongBreak = 4
    s.autoContinue = true
    
    return NavigationStack {
        SettingsView()
    }
    .environment(s)                    // 提供 AppSettings
    .environment(ModuleCoordinator())  // 提供能量列需要的 coordinator
    .preferredColorScheme(.light)
}


