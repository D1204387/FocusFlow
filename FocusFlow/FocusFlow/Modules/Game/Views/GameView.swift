    // Modules/Game/Views/GameView.swift
import SwiftUI

    // 小主題：橘色系 + 棋盤/空格色
private enum GameTheme {
    static let accent = Color.orange
    static let board  = Color(.systemGray6)
    static let empty  = Color(.systemGray5)
    
        // 數值越大顏色越飽和
    static func tile(_ v: Int) -> Color {
        switch v {
        case 0:    return empty
        case 2:    return accent.opacity(0.20)
        case 4:    return accent.opacity(0.30)
        case 8:    return accent.opacity(0.40)
        case 16:   return accent.opacity(0.50)
        case 32:   return accent.opacity(0.60)
        case 64:   return accent.opacity(0.70)
        case 128:  return accent.opacity(0.80)
        case 256:  return accent.opacity(0.88)
        case 512:  return accent.opacity(0.92)
        case 1024: return accent.opacity(0.96)
        default:   return accent
        }
    }
    static func text(_ v: Int) -> Color { v <= 4 ? .black : .white }
}

struct GameView: View {
    @State private var game = GameModel()
    @State private var showLeaderboard = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                    // 標題 + 得分膠囊
                VStack(spacing: 6) {
                    Text("2048")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(GameTheme.accent)
                    
                    Text("得分：\(game.score)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6)
                
                    // 棋盤（依容器自適應尺寸）
                GeometryReader { g in
                    let side = min(g.size.width - 40, 360)           // 棋盤邊長
                    let spacing: CGFloat = 10
                    let grid = 4
                    let tile = (side - spacing * CGFloat(grid - 1)) / CGFloat(grid)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(GameTheme.board)
                            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                        
                        GridView(game: game, tileSize: tile, spacing: spacing)
                            .padding(14)
                    }
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(height: 380)
                
                    // 狀態提示
                Group {
                    if game.isGameOver {
                        Label("遊戲結束", systemImage: "xmark.octagon.fill")
                            .foregroundStyle(.red)
                    } else if game.hasWon {
                        Label("你贏了！", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                }
                .font(.title3.weight(.semibold))
                .padding(.top, -6)
                
                    // 控制列（與跑步/專注一致的按鈕樣式）
                HStack(spacing: 12) {
                    Button("上一步") { game.undo() }
                        .buttonStyle(PrimaryButtonStyle(.secondary(GameTheme.accent)))
                        .disabled(!game.canUndo)
                    
                    Button("排行榜") { showLeaderboard = true }
                        .buttonStyle(PrimaryButtonStyle(.secondary(GameTheme.accent)))
                        .sheet(isPresented: $showLeaderboard) {
                            LeaderboardView(leaderboard: game.leaderboard)
                        }
                    
                    Button("重新開始") { game.restart() }
                        .buttonStyle(PrimaryButtonStyle(.primary(GameTheme.accent)))
                        .disabled(!(game.isGameOver || game.hasWon))
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .background(Theme.bg) // 你專案的背景
            .toolbarEnergy(title: "遊戲", tint: GameTheme.accent)
        }
    }
}

    // MARK: - Grid / Tile

struct GridView: View {
    @Bindable var game: GameModel
    let tileSize: CGFloat
    let spacing: CGFloat
    private let gridSize = 4
    
    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<gridSize, id: \.self) { r in
                HStack(spacing: spacing) {
                    ForEach(0..<gridSize, id: \.self) { c in
                        TileView(value: game.grid[r][c], size: tileSize)
                    }
                }
            }
        }
            // 讓數字變動時有一點動態
        .animation(.snappy(duration: 0.12), value: game.grid)
        .animation(.snappy(duration: 0.12), value: game.score)
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { v in
                guard !game.isGameOver, !game.hasWon else { return }
                if abs(v.translation.width) > abs(v.translation.height) {
                    v.translation.width > 0 ? game.moveTiles(direction: .right)
                    : game.moveTiles(direction: .left)
                } else {
                    v.translation.height > 0 ? game.moveTiles(direction: .down)
                    : game.moveTiles(direction: .up)
                }
            }
        )
    }
}

struct TileView: View {
    let value: Int
    let size: CGFloat
    
    var body: some View {
        ZStack {
                // 背板
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GameTheme.tile(value))
                .overlay(
                    // 微弱描邊讓對比更清楚（深色格不顯色）
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(value == 0 ? 0 : 0.12), lineWidth: 1)
                )
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(value == 0 ? 0 : 0.06), radius: 4, y: 2)
            
                // 數字
            if value > 0 {
                Text("\(value)")
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(GameTheme.text(value))
                    .minimumScaleFactor(0.5)
                    .padding(4)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
    }
}

    // MARK: - Leaderboard

struct LeaderboardView: View {
    @Bindable private var leaderboard: LeaderboardManager
    @Environment(\.dismiss) var dismiss
    
    init(leaderboard: LeaderboardManager) {
        self.leaderboard = leaderboard
    }
    
    var body: some View {
        NavigationStack {
            List(leaderboard.leaderboard.indices, id: \.self) { i in
                let entry = leaderboard.leaderboard[i]
                HStack {
                    Text("\(i + 1). \(entry.name)")
                    Spacer()
                    Text("\(entry.score)")
                        .monospacedDigit()
                }
            }
            .navigationTitle("排行榜")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("返回") { dismiss() }
                }
            }
        }
    }
}
