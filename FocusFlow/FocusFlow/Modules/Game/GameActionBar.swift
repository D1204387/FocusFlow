import SwiftUI

struct GameActionBar: View {
    let onUndo: () -> Void
    let onLeaderboard: () -> Void
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("回上一動作", action: onUndo)
                    .buttonStyle(PrimaryButtonStyle(.primary(Theme.Focus.solid)))
                Button("排行榜", action: onLeaderboard)
                    .buttonStyle(PrimaryButtonStyle(.secondary(Theme.Focus.solid)))
            }
            Button("Restart", action: onRestart)
                .buttonStyle(PrimaryButtonStyle(.primary(Theme.Focus.solid)))
        }
    }
}


