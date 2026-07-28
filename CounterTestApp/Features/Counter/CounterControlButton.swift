//
//  CounterControlButton.swift
//  CounterTestApp
//
//  Created by Дмитро on 29.07.2026.
//

import SwiftUI

struct CounterControlButton: View {
    let title: String
    let systemImage: String
    let colors: [Color]
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .black))
                Text(title)
                    .font(.caption2.weight(.black))
                    .tracking(1)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 104)
            .background(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: (colors.first ?? .clear).opacity(0.45), radius: 16, y: 8)
        }
        .buttonStyle(CasinoPressButtonStyle())
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct CasinoPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .brightness(configuration.isPressed ? 0.12 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.58), value: configuration.isPressed)
    }
}
