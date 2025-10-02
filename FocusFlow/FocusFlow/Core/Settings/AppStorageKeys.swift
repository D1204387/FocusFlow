    // Core/AppStorageKeys.swift
import Foundation

enum FFKey {
        // Running
    static let runTargetMinutes = "runTargetMinutes"   // 🟦 跑步目標（分鐘）
    static let bgmOn           = "bgmOn"
    static let metronomeOn     = "metronomeOn"
    static let metronomeBPM    = "metronomeBPM"
    static let hapticsOn       = "hapticsOn"
    
        // Focus (Pomodoro)
    static let focusMinutes          = "focusMinutes"
    static let shortBreakMinutes     = "shortBreakMinutes"
    static let longBreakMinutes      = "longBreakMinutes"
    static let roundsBeforeLongBreak = "roundsBeforeLongBreak"
    static let autoContinue          = "autoContinue"
}
