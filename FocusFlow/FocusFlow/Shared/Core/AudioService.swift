// Services/AudioService.swift
import Foundation
import AVFoundation
import UIKit


// MARK: - 音樂與節拍服務
// AudioService: 控制背景音樂、節拍器、音效的單例服務
// bgmPlayer: 背景音樂播放器
// clickPlayer: 節拍音效播放器
// chimePlayer: 完成提示音播放器
// startRunSession: 進入跑步模式時啟動音樂/節拍
// stopRunSession: 結束跑步時關閉音樂/節拍
final class AudioService {
    static let shared = AudioService()
    private init() {}
    
   
        // Players
    private var bgmPlayer: AVAudioPlayer?
    private var clickPlayer: AVAudioPlayer?
    private var chimePlayer: AVAudioPlayer?
    
        // Metronome
    private var metroTimer: Timer?
    private(set) var bpm: Int = 180
    
    
        // MARK: - Session helpers
    private func configureSession() {
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, options: [.mixWithOthers])
        try? s.setActive(true)
    }
    
    private func deactivateSession() {
        try? AVAudioSession.sharedInstance()
            .setActive(false)
    }
    
        // MARK: - Public API（與 RunningView 對齊）
        /// 進入跑步：依設定開啟音訊
    func startRunSession(enableMusic: Bool, enableMetronome: Bool, bpm: Int) {
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
            
            let candidates = ["relaxing_piano", "nature_ambient", "light_music"]
            let shuffled  = candidates.shuffled()
            bgmPlayer = loadPlayer(names: shuffled, ext: "mp3")
        
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.volume = 0.5
            bgmPlayer?.prepareToPlay()   // ✅ 先預熱
    }
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
    
        // ---- Completion Chime ✅ ----
        /// 播放完成提示音（不影響 BGM 狀態，會自動啟用 Session）
        // 只負責把完成音播出來（不動其他聲音、不關 session）
    func playChime() {
        configureSession()
        if chimePlayer == nil {
            chimePlayer = loadPlayer(names: ["completion_chime"], ext: "m4a")
            chimePlayer?.prepareToPlay()
        }
        chimePlayer?.currentTime = 0
        chimePlayer?.volume = 1.0
        chimePlayer?.play()
    }
    
        // 完成流程用：先停 BGM/節拍器，播完「完成音」再關閉 session
    func playCompletionAndTearDown() {
        stopMetronome()
        stopBGM()
        playChime()
        let delay = chimePlayer?.duration ?? 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.chimePlayer?.stop()
            self.chimePlayer = nil
            self.deactivateSession()
        }
    }
    
    
        // MARK: - Internals
    private func scheduleMetronome() {
        metroTimer?.invalidate()
        let interval = 60.0 / Double(max(30, min(300, bpm)))   // 核心：每拍間隔
        metroTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.clickPlayer?.currentTime = 0
            self.clickPlayer?.play()
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
