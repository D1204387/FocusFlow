// Components/TimeCluster.swift
import SwiftUI

/// 中央時間群（大時間 + 剩餘 + 百分比）
/// - 可選標題（例如「專注中 / 短休中 / 長休中」）
/// - `elapsed`、`targetSeconds` 都以「秒」為單位
// MARK: - 中央時間群組元件
// TimeCluster: 顯示已過時間、剩餘時間、百分比等資訊
// elapsed: 已過秒數
// targetSeconds: 目標總秒數
// remain: 剩餘秒數
// percent: 進度百分比
// hms: 將秒數轉為 00:00 或 1:23:45 格式
struct TimeCluster: View {
    let elapsed: Int
    let targetSeconds: Int
    var title: String? = nil
    let accent: Color
    
    private var remain: Int { max(0, targetSeconds - elapsed) }
    private var percent: Int {
        guard targetSeconds > 0 else { return 0 }
        return Int(round(Double(elapsed) / Double(targetSeconds) * 100))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if let title {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            Text(hms(elapsed))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(accent)
            
            HStack(spacing: 12) {
                Label("剩餘 \(hms(remain))", systemImage: "hourglass.bottomhalf.filled")
                Label("\(percent)%", systemImage: "clock")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    // 00:00 或 1:23:45
    private func hms(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec)
        : String(format: "%02d:%02d", m, sec)
    }
}
