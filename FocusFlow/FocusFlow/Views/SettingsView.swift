import SwiftUI

    /// 統一設定頁（淺色系）
    /// - 跑步：藍 / 專注：綠
    /// - 右上角顯示可用點數（toolbarEnergy）
struct SettingsView: View {
        // MARK: AppStorage（與全專案對齊的 key）
        // 音訊
    @AppStorage("bgmOn")            private var bgmOn: Bool = true
    @AppStorage("metronomeOn")      private var metronomeOn: Bool = true
    @AppStorage("metronomeBPM")     private var metronomeBPM: Int = 180
    
        // 跑步
    @AppStorage(FFKey.runTargetMinutes) private var runTargetMinutes: Int = 20
    @AppStorage("hapticsOn")        private var hapticsOn: Bool = true
    
        // 番茄
    @AppStorage("focusMinutes")           private var focusMinutes: Int = 25
    @AppStorage("shortBreakMinutes")      private var shortBreakMinutes: Int = 5
    @AppStorage("longBreakMinutes")       private var longBreakMinutes: Int = 15
    @AppStorage("roundsBeforeLongBreak")  private var roundsBeforeLongBreak: Int = 4
    @AppStorage("autoContinue")           private var autoContinue: Bool = true
    
        // 音訊服務
    @State private var audio = AudioService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                        // MARK: 音場 & 節拍器
                    SectionCard(title: "音場 & 節拍器") {
                        ToggleRow(title: "背景音樂", isOn: $bgmOn, symbol: "music.note.list")
                        Divider()
                        ToggleRow(title: "節拍器", isOn: $metronomeOn, symbol: "metronome")
                        if metronomeOn {
                            HStack(spacing: 12) {
                                Label("BPM", systemImage: "waveform.path.ecg")
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(Theme.text)
                                Slider(value: Binding(
                                    get: { Double(metronomeBPM) },
                                    set: { metronomeBPM = Int($0.rounded()) }
                                ), in: 60...220, step: 1)
                                .tint(Theme.Run.solid)
                                
                                Text("\(metronomeBPM)")
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(Theme.text)
                                    .frame(width: 56, alignment: .trailing)
                            }
                            .accessibilityLabel("節拍器 BPM \(metronomeBPM)")
                        }
                    }
                    
                        // MARK: 跑步
                    SectionCard(title: "慢跑") {
                        HStack {
                            Label("目標時間", systemImage: "figure.run")
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Stepper("", value: $runTargetMinutes, in: 10...120, step: 5)
                                .labelsHidden()
                            Text("\(runTargetMinutes) 分鐘")
                                .font(.title3.monospacedDigit())
                                .foregroundStyle(Theme.Run.solid)
                        }
                        Divider()
                        ToggleRow(title: "震動回饋", isOn: $hapticsOn, symbol: "iphone.radiowaves.left.and.right")
                    }
                    
                        // MARK: 番茄（工作 / 休息 / 循環）
                    SectionCard(title: "專注番茄") {
                        timeRow(title: "工作時間",
                                value: $focusMinutes,
                                tint: Theme.Focus.solid,
                                range: 5...120,
                                step: 5)                    // ✅ 5 分鐘一格
                        Divider()
                        timeRow(title: "短休息",
                                value: $shortBreakMinutes,
                                tint: Theme.Focus.solid.opacity(0.9),
                                range: 1...30)
                        Divider()
                        timeRow(title: "長休息",
                                value: $longBreakMinutes,
                                tint: Theme.Focus.solid.opacity(0.9),
                                range: 5...60)
                        Divider()
                        HStack {
                            Label("每幾顆後長休", systemImage: "record.circle")
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Stepper("", value: $roundsBeforeLongBreak, in: 2...8, step: 1)
                                .labelsHidden()
                            Text("\(roundsBeforeLongBreak) 顆")
                                .font(.title3.monospacedDigit())
                                .foregroundStyle(Theme.Focus.solid)
                        }
                        Divider()
                        ToggleRow(title: "自動續播下一段", isOn: $autoContinue, symbol: "arrow.triangle.2.circlepath")
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
            // 讓設定變更即時作用到音訊
//        .onChange(of: bgmOn) { _, on in on ? audio.startBGM() : audio.stopBGM() }
//        .onChange(of: metronomeOn) { _, on in on ? audio.startMetronome(bpm: metronomeBPM) : audio.stopMetronome() }
//        .onChange(of: metronomeBPM) { _, v in audio.setBPM(v) }
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
        bgmOn = true
        metronomeOn = true
        metronomeBPM = 180
        
        runTargetMinutes = 20
        hapticsOn = true
        
        focusMinutes = 25
        shortBreakMinutes = 5
        longBreakMinutes = 15
        roundsBeforeLongBreak = 4
        autoContinue = true
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

