//
//  TimerService.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/1.
//
import Foundation
import Combine
import Observation

    /// 通用計時器：支援「正計時」與「倒數」
    /// - 正計時：跑步等
    /// - 倒數：番茄等（以 endDate 計算，背景/喚醒不漂移）
@Observable
final class TimerService {
    enum Mode { case countUp, countdown }
    private(set) var mode: Mode = .countUp
    
        // 共同狀態
    private var ticker: AnyCancellable?
    private var startDate: Date?
    private var pausedAccum: TimeInterval = 0
    var isRunning: Bool = false
    var isPaused: Bool = false
    
        // 正計時
    var elapsed: TimeInterval = 0
    
        // 倒數
    private var endDate: Date?
    var remaining: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    
        // MARK: - Count Up
    func startCountUp() {
        reset()
        mode = .countUp
        startDate = .now
        isRunning = true
        startTicker()
    }
    
        // MARK: - Countdown
    func startCountdown(seconds: TimeInterval) {
        reset()
        mode = .countdown
        totalDuration = seconds
        endDate = Date().addingTimeInterval(seconds)
        isRunning = true
        startTicker()
    }
    
        /// 也可用「截止時間」啟動倒數
    func startCountdown(until endDate: Date) {
        reset()
        mode = .countdown
        totalDuration = max(0, endDate.timeIntervalSinceNow)
        self.endDate = endDate
        isRunning = true
        startTicker()
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        pausedAccum = accumulated() // 記住目前進度
    }
    
    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
            // 重新基準時間
        switch mode {
        case .countUp:
            startDate = .now
        case .countdown:
                // endDate 固定，無需改
            break
        }
    }
    
        /// 停止並回傳「本次實際秒數」
    @discardableResult
    func stop() -> TimeInterval {
        ticker?.cancel(); ticker = nil
        let result = (mode == .countUp) ? accumulated() : (totalDuration - remaining)
        reset()
        return max(0, result)
    }
    
    func reset() {
        isRunning = false
        isPaused = false
        startDate = nil
        endDate = nil
        elapsed = 0
        remaining = 0
        totalDuration = 0
        pausedAccum = 0
        ticker?.cancel(); ticker = nil
    }
    
        // MARK: - Private
    private func startTicker() {
        ticker = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }
    
    private func tick() {
        guard isRunning else { return }
        if isPaused { return }
        
        switch mode {
        case .countUp:
            elapsed = accumulated()
        case .countdown:
            guard let end = endDate else { return }
            remaining = max(0, end.timeIntervalSinceNow)
            if remaining == 0 {
                    // 倒數結束
                _ = stop()
            }
        }
    }
    
    private func accumulated() -> TimeInterval {
            // 已經累計 + 目前段落
        switch mode {
        case .countUp:
            guard let s = startDate else { return pausedAccum }
            return pausedAccum + Date().timeIntervalSince(s)
        case .countdown:
                // 將 totalDuration 當作總秒數，回傳已用時間
            guard let end = endDate else { return pausedAccum }
            let used = max(0, totalDuration - max(0, end.timeIntervalSinceNow))
            return pausedAccum + used
        }
    }
    
        // 便利字串（00:00）
    var mmss: String {
        let sec: Int
        switch mode {
        case .countUp:    sec = Int(elapsed.rounded())
        case .countdown:  sec = Int(remaining.rounded())
        }
        let m = sec / 60, s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }
}

