//
//  AppSettings.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/1.
//
import Foundation
import Observation

    /// App 輕量設定（使用 UserDefaults）
    /// - 不使用 @AppStorage，避免將 SwiftUI 依賴帶入 Core
@Observable
final class AppSettings {
    static let shared = AppSettings()
    
        // 跑步
    var targetMinutes: Int {
        didSet { UserDefaults.standard.set(targetMinutes, forKey: Keys.targetMinutes) }
    }
    var enableMetronome: Bool {
        didSet { UserDefaults.standard.set(enableMetronome, forKey: Keys.enableMetronome) }
    }
    var metronomeBPM: Int {
        didSet { UserDefaults.standard.set(metronomeBPM, forKey: Keys.metronomeBPM) }
    }
    
        // 顯示
    var keepScreenOn: Bool {
        didSet { UserDefaults.standard.set(keepScreenOn, forKey: Keys.keepScreenOn) }
    }
    
    private init() {
        let d = UserDefaults.standard
        targetMinutes   = d.object(forKey: Keys.targetMinutes)   as? Int  ?? 20
        enableMetronome = d.object(forKey: Keys.enableMetronome) as? Bool ?? true
        metronomeBPM    = d.object(forKey: Keys.metronomeBPM)    as? Int  ?? 180
        keepScreenOn    = d.object(forKey: Keys.keepScreenOn)    as? Bool ?? true
    }
    
    private enum Keys {
        static let targetMinutes   = "settings.targetMinutes"
        static let enableMetronome = "settings.enableMetronome"
        static let metronomeBPM    = "settings.metronomeBPM"
        static let keepScreenOn    = "settings.keepScreenOn"
    }
}

