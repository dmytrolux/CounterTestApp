//
//  CounterControlButton.swift
//  CounterTestApp
//
//  Created by Дмитро on 29.07.2026.
//

import SwiftUI

struct CounterModuleView: View {
    @StateObject private var viewModel: CounterViewModel

    init(viewModel: CounterViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                CasinoBackground()

                VStack(spacing: 30) {
                    Spacer()
                    logo
                    jackpotCard
                    startButton
                    Spacer()

                    Text("PLAY RESPONSIBLY • 18+")
                        .font(.caption2.weight(.semibold))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    private var logo: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(CounterTheme.gold.opacity(0.35), lineWidth: 8)
                    .frame(width: 98, height: 98)
                Circle()
                    .stroke(CounterTheme.gold, style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
                    .frame(width: 84, height: 84)
                Image(systemName: "crown.fill")
                    .font(.system(size: 38))
                    .foregroundColor(CounterTheme.gold)
            }
            .shadow(color: CounterTheme.gold.opacity(0.55), radius: 18)

            Text("LUCKY COUNT")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundColor(.white)

            Text("MAKE EVERY TAP COUNT")
                .font(.caption.weight(.bold))
                .tracking(3)
                .foregroundColor(CounterTheme.mint)
        }
        .accessibilityElement(children: .combine)
    }

    private var jackpotCard: some View {
        VStack(spacing: 8) {
            Label("PERSONAL JACKPOT", systemImage: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundColor(CounterTheme.gold)

            Text("\(viewModel.bestScore)")
                .font(.system(size: 66, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .shadow(color: CounterTheme.hotPink, radius: 12)

            Text("BEST SCORE")
                .font(.caption2.weight(.bold))
                .tracking(2.5)
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .casinoGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Best score: \(viewModel.bestScore)")
    }

    private var startButton: some View {
        NavigationLink {
            CounterGameView(viewModel: viewModel)
                .onAppear(perform: viewModel.startGame)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                Text("START GAME")
                    .font(.headline.weight(.black))
                    .tracking(1.5)
            }
            .foregroundColor(CounterTheme.midnight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [CounterTheme.gold, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: CounterTheme.gold.opacity(0.5), radius: 18, y: 8)
        }
        .accessibilityIdentifier("counter.start")
    }
}
