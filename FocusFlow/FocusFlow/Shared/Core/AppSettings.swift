    //
    //  AppSettings.swift
    //  FocusFlow
    //
import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()
    private let d = UserDefaults.standard
        // MARK: - Keys
    private enum Key {
            // Running
        static let runTargetMinutes   = "settings.runTargetMinutes"
        static let bgmOn             = "settings.bgmOn"
        static let metronomeOn       = "settings.metronomeOn"
        static let metronomeBPM      = "settings.metronomeBPM"
        
            // Focus(Pomodoro)
        static let focusMinutes      = "settings.focusMinutes"
        static let shortBreakMinutes = "settings.shortBreakMinutes"
        static let longBreakMinutes  = "settings.longBreakMinutes"
        static let roundsBeforeLongBreak = "settings.roundsBeforeLongBreak"
        static let autoContinue    = "settings.autoContinue"
        
            // Display
        static let keepScreenOn      = "settings.keepScreenOn"
    }
        // Running
    var runTargetMinutes: Int {
        didSet { d.set(runTargetMinutes, forKey: Key.runTargetMinutes) }
    }
    var bgmOn: Bool {
        didSet { d.set(bgmOn, forKey: Key.bgmOn) }
    }
    var metronomeOn: Bool {
        didSet { d.set(metronomeOn, forKey: Key.metronomeOn) }
    }
    var metronomeBPM: Int {
        didSet { d.set(metronomeBPM, forKey: Key.metronomeBPM) }
    }
    
        // Focus
    var focusMinutes: Int {
        didSet { d.set(focusMinutes, forKey: Key.focusMinutes) }
    }
    var shortBreakMinutes: Int {
        didSet { d.set(shortBreakMinutes, forKey: Key.shortBreakMinutes) }
    }
    var longBreakMinutes: Int {
        didSet { d.set(longBreakMinutes, forKey: Key.longBreakMinutes) }
    }
    var roundsBeforeLongBreak: Int {
        didSet { d.set(roundsBeforeLongBreak, forKey: Key.roundsBeforeLongBreak) }
    }
    var autoContinue: Bool {
        didSet { d.set(autoContinue, forKey: Key.autoContinue) }
    }
        // Display
    var keepScreenOn: Bool {
        didSet { d.set(keepScreenOn, forKey: Key.keepScreenOn) }
    }
    var pomodoroTargetPerDay: Int {
        didSet { d.set(pomodoroTargetPerDay, forKey: "settings.pomodoroTargetPerDay") }
    }
    
    private init() {
            // default values
        runTargetMinutes   = d
            .object(forKey: Key.runTargetMinutes) as? Int ?? 20
        bgmOn             = d.object(
            forKey: Key.bgmOn) as? Bool ?? true
        metronomeOn       = d.object(
            forKey: Key.metronomeOn) as? Bool ?? false
        metronomeBPM      = d.object(
            forKey: Key.metronomeBPM) as? Int ?? 180
        focusMinutes      = d.object(
            forKey: Key.focusMinutes) as? Int ?? 25
        shortBreakMinutes = d.object(
            forKey: Key.shortBreakMinutes) as? Int ?? 5
        longBreakMinutes  = d.object(
            forKey: Key.longBreakMinutes) as? Int ?? 15
        roundsBeforeLongBreak = d.object(
            forKey: Key.roundsBeforeLongBreak) as? Int ?? 4
        autoContinue    = d.object(
            forKey: Key.autoContinue) as? Bool ?? true
        keepScreenOn      = d.object(
            forKey: Key.keepScreenOn) as? Bool ?? true
        pomodoroTargetPerDay = d.object(forKey: "settings.pomodoroTargetPerDay") as? Int ?? 1
    }
        // MARK: - Utilities
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

