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
    
    @ObservationIgnored
    private let d = UserDefaults.standard
    
    private enum Keys {
        static let runTargetMinutes = "settings.runTargetMinutes"
        static let bgmOn = "settings.bgmOn"
        static let metronomeOn = "settings.metronomeOn"
        static let metronomeBPM = "settings.metronomeBPM"
        
        static let focusMinutes = "settings.focusMinutes"
        static let shortBreakMinutes = "settings.shortBreakMinutes"
        static let longBreakMinutes = "settings.longBreakMinutes"
        static let roundsBeforeLongBreak = "settings.roundsBeforeLongBreak"
        static let autoContinue = "settings.autoContinue"
        
        static let keepScreenOn = "settings.keepScreenOn"
        static let pomodoroTargetPerDay = "settings.pomodoroTargetPerDay"
    }
    
    var runTargetMinutes: Int {
        didSet { d.set(runTargetMinutes, forKey: Keys.runTargetMinutes )}}
    var bgmOn: Bool { didSet { d.set(bgmOn, forKey: Keys.bgmOn )}}
    var metronomeOn: Bool {
        didSet { d.set(metronomeOn, forKey: Keys.metronomeOn )}}
    var metronomeBPM: Int {
        didSet {
            d.set(metronomeBPM, forKey: Keys.metronomeBPM )}}

    var focusMinutes: Int {
        didSet { d.set(focusMinutes, forKey: Keys.focusMinutes)}}
    var shortBreakMinutes: Int {
        didSet { d.set(shortBreakMinutes, forKey: Keys.shortBreakMinutes)}}
    var longBreakMinutes: Int {
        didSet { d.set(longBreakMinutes, forKey: Keys.longBreakMinutes )}}
    var roundsBeforeLongBreak: Int {
        didSet { d.set(roundsBeforeLongBreak, forKey: Keys.roundsBeforeLongBreak)}}

    var autoContinue: Bool {
        didSet { d.set(autoContinue, forKey: Keys.autoContinue)}}
    var keepScreenOn: Bool {
        didSet { d.set(keepScreenOn, forKey: Keys.keepScreenOn)}}
    
    /// 每日番茄鐘目標數: 預設 1
    var pomodoroTargetPerDay: Int {
        didSet { d.set(pomodoroTargetPerDay, forKey: Keys.pomodoroTargetPerDay)}}

    private init() {
        runTargetMinutes = d.object(forKey: Keys.runTargetMinutes) == nil ? 20 :
        d.integer(forKey: Keys.runTargetMinutes)
        bgmOn = d.object(forKey: Keys.bgmOn) == nil ? true :
        d.bool(forKey: Keys.bgmOn)
        metronomeOn = d.object(forKey: Keys.metronomeOn) == nil ? true :
        d.bool(forKey: Keys.metronomeOn)
        let raw = (d.object(forKey: Keys.metronomeBPM) as? Int) ?? 180
        metronomeBPM = min(240, max(120, raw))
        
        focusMinutes = d.object(forKey: Keys.focusMinutes) == nil ? 25 :
        d.integer(forKey: Keys.focusMinutes)
        shortBreakMinutes = d.object(forKey: Keys.shortBreakMinutes) == nil ? 5 :
        d.integer(forKey: Keys.shortBreakMinutes)
        longBreakMinutes = d.object(forKey: Keys.longBreakMinutes) == nil ? 15 :
        d.integer(forKey: Keys.longBreakMinutes)
        roundsBeforeLongBreak = d.object(forKey: Keys.roundsBeforeLongBreak) ==
        nil ? 4 : d.integer(forKey: Keys.roundsBeforeLongBreak)
        autoContinue = d.object(forKey: Keys.autoContinue) == nil ? true :
        d.bool(forKey: Keys.autoContinue)
        keepScreenOn = d.object(forKey: Keys.keepScreenOn) == nil ? true :
        d.bool(forKey: Keys.keepScreenOn)
        pomodoroTargetPerDay = d.object(forKey: Keys.pomodoroTargetPerDay) == nil ? 1 :
        d.integer(forKey: Keys.pomodoroTargetPerDay)

    }
  
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

