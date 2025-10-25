//
    //  AppSettings.swift
    //  FocusFlow
    //
import Foundation
import Observation

// MARK: - App 設定管理
/// - @Observable 提供反應式更新
/// - 支援所有功能的設定（跑步、專注、顯示等）
/// - 屬性變動時自動保存

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()
    private let d = UserDefaults.standard
    
    // MARK: - Running Settings
    
    /// 跑步目標分鐘數: 20 分鐘
    var runTargetMinutes: Int {
        get { d.integer(forKey: "settings.runTargetMinutes") == 0 ? 20 : d.integer(forKey: "settings.runTargetMinutes") }
        set { d.set(newValue, forKey: "settings.runTargetMinutes") }
    }

    /// 背景音樂開關: 預設開啟
    var bgmOn: Bool {
        get { d.object(forKey: "settings.bgmOn") == nil ? true : d.bool(forKey: "settings.bgmOn") }
        set { d.set(newValue, forKey: "settings.bgmOn") }
    }

    /// 節拍器開關: 預設開啟
    var metronomeOn: Bool {
        get { d.object(forKey: "settings.metronomeOn") == nil ? true : d.bool(forKey: "settings.metronomeOn") }
        set { d.set(newValue, forKey: "settings.metronomeOn") }
    }
    
    /// 節拍器 BPM: 預設 180
    var metronomeBPM: Int {
        get { d.integer(forKey: "settings.metronomeBPM") == 0 ? 180 : d.integer(forKey: "settings.metronomeBPM") }
        set { d.set(newValue, forKey: "settings.metronomeBPM") }
    }

    // MARK: - Focus Settings
    
    /// 專注時間（分鐘）: 25  分鐘
    var focusMinutes: Int {
        get { d.integer(forKey: "settings.focusMinutes") == 0 ? 25 : d.integer(forKey: "settings.focusMinutes") }
        set { d.set(newValue, forKey: "settings.focusMinutes") }
    }
    
    /// 短休息時間（分鐘）: 5 分鐘
    var shortBreakMinutes: Int {
        get { d.integer(forKey: "settings.shortBreakMinutes") == 0 ? 5 : d.integer(forKey: "settings.shortBreakMinutes") }
        set { d.set(newValue, forKey: "settings.shortBreakMinutes") }
    }
       
    /// 長休息時間（分鐘）: 15 分鐘
    var longBreakMinutes: Int {
        get { d.integer(forKey: "settings.longBreakMinutes") == 0 ? 15 : d.integer(forKey: "settings.longBreakMinutes") }
        set { d.set(newValue, forKey: "settings.longBreakMinutes") }
    }
    
    /// 幾輪後進入長休息: 4 輪
    var roundsBeforeLongBreak: Int {
        get { d.integer(forKey: "settings.roundsBeforeLongBreak") == 0 ? 4 : d.integer(forKey: "settings.roundsBeforeLongBreak") }
        set { d.set(newValue, forKey: "settings.roundsBeforeLongBreak") }
    }
    
    /// 自動繼續下一輪: 預設開啟
    var autoContinue: Bool {
        get { d.object(forKey: "settings.autoContinue") == nil ? true : d.bool(forKey: "settings.autoContinue") }
        set { d.set(newValue, forKey: "settings.autoContinue") }
    }
    
    // MARK: - Display Settings
    
    /// 保持螢幕常亮: 預設開啟
    var keepScreenOn: Bool {
        get { d.object(forKey: "settings.keepScreenOn") == nil ? true : d.bool(forKey: "settings.keepScreenOn") }
        set { d.set(newValue, forKey: "settings.keepScreenOn") }
    }
    
    /// 每日番茄鐘目標數: 預設 1
    var pomodoroTargetPerDay: Int {
        get { d.integer(forKey: "settings.pomodoroTargetPerDay") == 0 ? 1 : d.integer(forKey: "settings.pomodoroTargetPerDay") }
        set { d.set(newValue, forKey: "settings.pomodoroTargetPerDay") }
    }

    private init() {}
  
        // MARK: - Reset to Defaults
    func reset() {
        runTargetMinutes = 20
        bgmOn = true
        metronomeOn = true
        metronomeBPM = 180
        
        focusMinutes = 25
        shortBreakMinutes = 5
        longBreakMinutes = 15
        roundsBeforeLongBreak = 4
        autoContinue = true
        
        keepScreenOn = true
        pomodoroTargetPerDay = 1
    }
}

