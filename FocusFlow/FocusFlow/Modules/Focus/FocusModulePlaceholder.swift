import SwiftUI

struct FocusModulePlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                SegmentedGaugeRing(
                    progress: 0.35,
                    size: 220,
                    tickCount: 60,
                    tickSize: .init(width: 6, height: 24),
                    innerPadding: 16,
                    active: Theme.Focus.solid,
                    inactive: Color(.systemGray4)
                ) {
                    VStack(spacing: 6) {
                        Text("裝置中…").font(.headline)
                        Text("此模組由同學接入").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Theme.bg)
            .toolbarEnergy(title: "模組待接入", tint: Theme.Focus.solid)
        }
    }
}

