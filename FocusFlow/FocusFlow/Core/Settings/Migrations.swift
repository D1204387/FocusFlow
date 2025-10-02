    // Core/Settings/Migrations.swift
import Foundation

private enum LegacyKey {
    static let targetMinutes   = "targetMinutes"     // 舊：跑步目標
    static let enableMusic     = "enableMusic"
    static let enableMetronome = "enableMetronome"
    static let enableHaptics   = "enableHaptics"
        // metronomeBPM 舊新同名，可同時支援
}

func migrateUserDefaultsIfNeeded() {
    let d = UserDefaults.standard
    
        // 只在新值不存在時，從舊值複製
    if d.object(forKey: FFKey.runTargetMinutes) == nil,
       let v = d.object(forKey: LegacyKey.targetMinutes) as? Int {
        d.set(v, forKey: FFKey.runTargetMinutes)
    }
    if d.object(forKey: FFKey.bgmOn) == nil,
       let v = d.object(forKey: LegacyKey.enableMusic) as? Bool {
        d.set(v, forKey: FFKey.bgmOn)
    }
    if d.object(forKey: FFKey.metronomeOn) == nil,
       let v = d.object(forKey: LegacyKey.enableMetronome) as? Bool {
        d.set(v, forKey: FFKey.metronomeOn)
    }
    if d.object(forKey: FFKey.hapticsOn) == nil,
       let v = d.object(forKey: LegacyKey.enableHaptics) as? Bool {
        d.set(v, forKey: FFKey.hapticsOn)
    }
        // BPM 若舊新同名 metronomeBPM，無需特別處理
}


