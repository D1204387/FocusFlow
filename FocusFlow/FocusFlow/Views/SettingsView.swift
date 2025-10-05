import SwiftUI

/// 統一設定頁（淺色系）
/// - 跑步：藍 / 專注：綠
/// - 右上角顯示可用點數（toolbarEnergy）
struct SettingsView: View {
        // MARK: - Properties
    @Environment(AppSettings.self) private var settings

            var body: some View {
                @Bindable var settings = AppSettings.shared
                
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
                                        Slider(value: Binding(
                                            get: { Double(settings.metronomeBPM) },
                                            set: { settings.metronomeBPM = Int($0.rounded()) }
                                        ), in: 60...220, step: 5)
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
                                    Stepper("", value: $settings.runTargetMinutes, in: 10...120, step: 5)
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
                                        tint: Theme.Focus.solid.opacity(0.9),
                                        range: 1...30)
                                Divider()
                                timeRow(title: "長休息",
                                        value: $settings.longBreakMinutes,
                                        tint: Theme.Focus.solid.opacity(0.9),
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
                                    resetDefaults()
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
                         step: Int = 1) -> some View {       // ✅ 支援自訂 step
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
    
    private func resetDefaults() {
        settings.bgmOn = true
        settings.metronomeOn = true
        settings.metronomeBPM = 180
        
        settings.runTargetMinutes = 20
        settings.hapticsOn = true
        
        settings.focusMinutes = 25
        settings.shortBreakMinutes = 5
        settings.longBreakMinutes = 15
        settings.roundsBeforeLongBreak = 4
        settings.autoContinue = true
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
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardStroke))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

