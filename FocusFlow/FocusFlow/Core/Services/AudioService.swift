    // Services/AudioService.swift
import Foundation
import AVFoundation
import UIKit

    /// 單例：控制背景音樂與節拍器
final class AudioService {
    static let shared = AudioService()
    private init() {}
    
        // Players
    private var bgmPlayer: AVAudioPlayer?
    private var clickPlayer: AVAudioPlayer?
    
        // Metronome
    private var metroTimer: Timer?
    private(set) var bpm: Int = 180
    private var useHaptics = true
    private let impact = UIImpactFeedbackGenerator(style: .light)
    
        // MARK: - Session helpers
    private func configureSession() {
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, options: [.mixWithOthers])
        try? s.setActive(true)
    }
    
    private func deactivateSession() {
        try? AVAudioSession.sharedInstance()
            .setActive(false, options: .notifyOthersOnDeactivation)
    }
    
        // MARK: - Public API (與 RunningView 對齊)
        /// 進入跑步：依設定開啟音訊
    func startRunSession(enableMusic: Bool, enableMetronome: Bool, bpm: Int, haptics: Bool) {
        useHaptics = haptics
        configureSession()
        if enableMusic { startBGM() }
        if enableMetronome { startMetronome(bpm: bpm) }
    }
    
        /// 離開/結束跑步：完全關閉音訊
    func stopRunSession() {
        stopBGM()
        stopMetronome()
        deactivateSession()
    }
    
        // ---- BGM ----
    func startBGM() {
        configureSession()
        if bgmPlayer == nil {
                // 依序嘗試你資源包裡的檔名
            bgmPlayer = loadPlayer(names: ["city_lofi", "ambient_pulse", "nature_ambient", "light_music"], ext: "mp3")
        }
        bgmPlayer?.numberOfLoops = -1
        bgmPlayer?.volume = 0.5
        bgmPlayer?.play()
    }
    
    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }
    
        // ---- Metronome ----
    func startMetronome(bpm: Int) {
        self.bpm = bpm
        configureSession()
        if clickPlayer == nil {
            clickPlayer = loadPlayer(names: ["metronome_click"], ext: "wav")
            ?? loadPlayer(names: ["completion_chime"], ext: "m4a")
            clickPlayer?.prepareToPlay()
        }
        scheduleMetronome()
    }
    
    func pauseMetronome() {
        metroTimer?.invalidate()
        metroTimer = nil
    }
    
    func stopMetronome() {
        metroTimer?.invalidate()
        metroTimer = nil
        clickPlayer?.stop()
        clickPlayer = nil
    }
    
        /// 途中調整 BPM（若正在打拍會立即套用）
    func setBPM(_ value: Int) {
        bpm = max(30, min(300, value))
        if metroTimer != nil { scheduleMetronome() }
    }
    
        // MARK: - Internals
    private func scheduleMetronome() {
        metroTimer?.invalidate()
        let interval = 60.0 / Double(max(30, min(300, bpm)))   // 核心：每拍間隔
        metroTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.clickPlayer?.currentTime = 0
            self.clickPlayer?.play()
            if self.useHaptics { self.impact.impactOccurred() }
        }
        RunLoop.main.add(metroTimer!, forMode: .common)
    }
    
    private func loadPlayer(names: [String], ext: String) -> AVAudioPlayer? {
        for n in names {
            if let url = Bundle.main.url(forResource: n, withExtension: ext) {
                return try? AVAudioPlayer(contentsOf: url)
            }
        }
        return nil
    }
}
