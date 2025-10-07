    // DesignSystem/LightTheme.swift
import SwiftUI

enum LightTheme {
    static let bg        = Color.white
    static let text      = Color.black
    static let subtext   = Color.black.opacity(0.45)
    static let track     = Color.black.opacity(0.08)
    
    enum Run {
        static let solid  : Color = .blue
        static let gradTop: Color = .blue.opacity(0.90)
        static let gradBot: Color = .blue.opacity(0.70)
    }
    enum Focus {
        static let solid  : Color = .green
        static let gradTop: Color = .green.opacity(0.90)
        static let gradBot: Color = .green.opacity(0.70)
    }
    enum Game {
            // 主色（橘）
        static let solid  : Color = .orange
        static let gradTop: Color = .orange.opacity(0.90)
        static let gradBot: Color = .orange.opacity(0.70)
        
            // 棋盤與空格底色
        static let board = Color(.systemGray6)
        static let empty = Color(.systemGray5)
        
            // 依數字大小調整飽和度（越大越深）
        static func tile(_ v: Int) -> Color {
            switch v {
            case 0:    return empty
            case 2:    return solid.opacity(0.20)
            case 4:    return solid.opacity(0.30)
            case 8:    return solid.opacity(0.40)
            case 16:   return solid.opacity(0.50)
            case 32:   return solid.opacity(0.60)
            case 64:   return solid.opacity(0.70)
            case 128:  return solid.opacity(0.80)
            case 256:  return solid.opacity(0.88)
            case 512:  return solid.opacity(0.92)
            case 1024: return solid.opacity(0.96)
            default:   return solid
            }
        }
        
        static func text(_ v: Int) -> Color {
            v <= 4 ? LightTheme.text : .white
        }
    }
    
        // 固定卡片與膠囊的底色（避免 Material 造成亮度浮動）
    static let cardBG     = Color.white.opacity(0.92)   // 卡片底
    static let chipBG     = Color.black.opacity(0.06)   // 膠囊底（等於你原本的 pillBG）
    
        // 也可以把既有別名對齊
    static let pillBG     = chipBG
    static let cardStroke = Color.black.opacity(0.08)
    
    static let softShadow = ShadowStyle(color: .black.opacity(0.08), radius: 12, y: 6)
}

struct ShadowStyle { let color: Color; let radius: CGFloat; let x: CGFloat = 0; let y: CGFloat }

extension View {
    func softShadow(_ s: ShadowStyle = LightTheme.softShadow) -> some View {
        shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self = Color(red: r, green: g, blue: b, opacity: alpha)
    }
}

    // 讓既有程式可用 Theme.*
typealias Theme = LightTheme
