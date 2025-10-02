//
//  EnergyHUD.swift
//  FocusFlow
//
//  Created by YiJou  on 2025/10/1.
//
import SwiftUI

struct EnergyHUDModifier: ViewModifier {
    @Environment(ModuleCoordinator.self) private var co
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            VStack(spacing: 8) {
                if co.showGainToast {
                    Text("獲得 +\(co.lastGain) 能量")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                        Text("\(co.energy)")
                            .font(.headline.weight(.bold))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            }
            .padding(.top, 8).padding(.horizontal, 16)
        }
        .animation(.snappy, value: co.showGainToast)
        .animation(.snappy, value: co.energy)
    }
}

extension View { func energyHUD() -> some View { modifier(EnergyHUDModifier()) } }

