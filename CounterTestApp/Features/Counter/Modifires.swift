//
//  Modifires.swift
//  CounterTestApp
//
//  Created by Дмитро on 29.07.2026.
//

import SwiftUI

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(0.09))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.45), CounterTheme.gold.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: CounterTheme.hotPink.opacity(0.22), radius: 30, y: 14)
    }
}

extension View {
    func casinoGlassCard() -> some View {
        modifier(GlassCardModifier())
    }
}
