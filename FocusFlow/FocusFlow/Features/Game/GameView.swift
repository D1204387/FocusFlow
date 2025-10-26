// Modules/Game/Views/GameView.swift
import SwiftUI
import Observation
import SwiftData

struct GameView: View {
    @Environment(ModuleCoordinator.self) private var co
    @Environment(\.modelContext) private var modelContext
    @State private var game = GameModel()
    @State private var showLeaderboard = false
    @State private var energyDeducted = false
    @State private var didReportThisRound = false
    
    private var canPlay: Bool { energyDeducted || co.canEnterGame() }
    
    // 棋盤手勢：第一次滑動前若未扣點 → 先扣；扣不到就不動棋盤
    private var boardDrag: some Gesture {
        DragGesture(minimumDistance: 30).onEnded { v in
            guard !game.isGameOver, !game.hasWon else { return }
            
            if !energyDeducted {
                guard co.spendForGameEntry() else { return }
                energyDeducted = true
            }
            
            if abs(v.translation.width) > abs(v.translation.height) {
                game.moveTiles(direction: v.translation.width > 0 ? .right : .left)
            } else {
                game.moveTiles(direction: v.translation.height > 0 ? .down : .up)
            }
        }
    }
//    private let costToPlay = 1            // 與 RewardRules/ModuleCoordinator 對齊
//    private var unlocked: Bool { co.energy >= costToPlay }
      
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 18) {
                        // 標題 + 得分
                    VStack(spacing: 6) {
                        Text("2048")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Game.solid)
                        Text("得分：\(game.score)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 6)
                    
                        // 棋盤（自適應）
                    GeometryReader { g in
                        let side = min(g.size.width - 40, 360)
                        let spacing: CGFloat = 10
                        let grid = 4
                        let tile = (side - spacing * CGFloat(grid - 1)) / CGFloat(grid)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Theme.Game.board)
                                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                            
                            GridView( grid: game.grid, score: game.score,
                                     isGameOver: game.isGameOver,
                                         hasWon: game.hasWon, tileSize: tile, spacing: spacing)
                                .padding(14)
                                .allowsHitTesting(canPlay)
                                .blur(radius: canPlay ? 0 : 2)
                                .opacity(canPlay ? 1 : 0.6)
                        }
                        .frame(width: side, height: side)
                        .contentShape(Rectangle())          //  命中區含外圍 padding
                        .highPriorityGesture(boardDrag, including: .all)     //  手勢掛在外層
                        .simultaneousGesture(DragGesture(minimumDistance: 0))
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
                    
                        // 控制列（與跑步/專注一致）
                    HStack(spacing: 12) {
                        Button("上一步") { game.undo() }
                            .buttonStyle(PrimaryButtonStyle(.secondary(Theme.Game.solid)))
                            .disabled(!energyDeducted || !game.canUndo)
                        
                        Button("排行榜") { showLeaderboard = true }
                            .buttonStyle(PrimaryButtonStyle(.secondary(Theme.Game.solid)))
                            .sheet(isPresented: $showLeaderboard) {
                                LeaderboardView(leaderboard: game.leaderboard)
                            }
                        
                        Button("重新開始") {
                            guard co.spendForGameEntry() else { return }
                            energyDeducted = true
                            didReportThisRound = false
                            game.restart()

                        }
                            .buttonStyle(PrimaryButtonStyle(.primary(Theme.Game.solid)))
                            .disabled(!co.canEnterGame() && !energyDeducted)
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                    // 🔒 能量不足時的遮罩
                if !canPlay {
                    LockedOverlay(required: RewardRules.gameEntryCost)
                }
            }
            .background(Theme.bg)
            .toolbarEnergy(title: "遊戲", tint: Theme.Game.solid)
            
            .onChange(of: game.hasWon) { _, won in
                if won { reportResultIfNeeded(reason: "won") }
            }
            .onChange(of: game.isGameOver) { _, over in
                if over { reportResultIfNeeded(reason: "gameOver") }
            }

            .onDisappear {
                    // 離開頁面時重置遊戲狀態
                energyDeducted = false
                didReportThisRound = false
            }
        }
    }
    
    private func reportResultIfNeeded(reason: String) {
        guard !didReportThisRound else { return }
        didReportThisRound = true
        
        let seconds = max(0, game.elapsedSeconds)
        let score   = game.score
        
            // 上報協調器（內部會存檔）
        co.apply(.gameFinished(score: score, seconds: seconds), modelContext: modelContext)
        
        let rec = GameRecord(date: Date(), score: score, seconds: seconds)
        modelContext.insert(rec)
        try? modelContext.save()
        
            // 同步 Widget 統計
        RecordsStore(context: modelContext).syncTodayStatsToAppGroup()
        
#if DEBUG
        print("📊 Saved GameRecord — score=\(score) seconds=\(seconds) reason=\(reason)")
#endif
    }
}

private struct GridView: View {
//    @Bindable var game: GameModel
    let grid: [[Int]]
    let score: Int
    let isGameOver: Bool
    let hasWon: Bool
    let tileSize: CGFloat
    let spacing: CGFloat

    private let gridSize = 4
    
    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<gridSize, id: \.self) { r in
                HStack(spacing: spacing) {
                    ForEach(0..<gridSize, id: \.self) { c in
                        TileView(value: grid[r][c], size: tileSize)
                    }
                }
            }
        }
        .animation(.snappy(duration: 0.12), value: grid)
        .animation(.snappy(duration: 0.12), value: score)
    }
}

private struct TileView: View {
    let value: Int
    let size: CGFloat
    
    var body: some View {
        ZStack {
                // 背板
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Game.tile(value))
                .overlay(
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
                    .foregroundStyle(value <= 4 ? Theme.text : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(4)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
    }
}

    // 🔒 鎖定層
private struct LockedOverlay: View {
    let required: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.Game.solid)
            Text("需要能量 \(required) 才能開始")
                .font(.headline)
            Text("去跑步或完成一顆番茄即可獲得能量。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct LeaderboardView: View {
    @Bindable private var leaderboard: LeaderboardManager
    @Environment(\.dismiss) private var dismiss
    
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
                    Text("\(entry.score)").monospacedDigit()
                }
            }
            .navigationTitle("排行榜")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }
}

#Preview("遊戲（解鎖：能量 1）") {
    let co = ModuleCoordinator(); co.energy = 1
    return GameView()
        .environment(co)
        .preferredColorScheme(.light)
        .background(Theme.bg)
}

#Preview("遊戲（鎖定：能量 0）") {
    let co = ModuleCoordinator(); co.energy = 0
    return GameView()
        .environment(co)
        .preferredColorScheme(.light)
        .background(Theme.bg)
}
