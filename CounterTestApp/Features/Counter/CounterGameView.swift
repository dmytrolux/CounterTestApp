//
//  CounterControlButton.swift
//  CounterTestApp
//
//  Created by Дмитро on 29.07.2026.
//

import Foundation
import SwiftUI

struct CounterGameView: View {
    @ObservedObject var viewModel: CounterViewModel
    @State private var isCounterPulsing = false

    var body: some View {
        ZStack {
            CasinoBackground()

            VStack(spacing: 26) {
                scoreHeader
                counterDisplay
                controls
                resetButton
                Spacer(minLength: 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
//        .navigationTitle("Lucky Count")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var scoreHeader: some View {
        HStack {
            Label("BEST", systemImage: "crown.fill")
                .foregroundColor(CounterTheme.gold)
            Spacer()
            Text("\(viewModel.bestScore)")
                .font(.title2.bold().monospacedDigit())
                .foregroundColor(.white)
        }
        .font(.subheadline.weight(.bold))
        .padding(18)
        .casinoGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Best score: \(viewModel.bestScore)")
    }

    private var counterDisplay: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 22)
                .frame(width: 250, height: 250)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [CounterTheme.gold, CounterTheme.hotPink, CounterTheme.mint, CounterTheme.gold],
                        center: .center
                    ),
                    lineWidth: 10
                )
                .frame(width: 250, height: 250)
                .shadow(color: CounterTheme.hotPink.opacity(0.5), radius: 15) 

            VStack(spacing: 4) {
                Text("CURRENT WIN")
                    .font(.caption2.weight(.bold))
                    .tracking(2.5)
                    .foregroundColor(.white.opacity(0.55))

                Text("\(viewModel.count)")
                    .font(.system(size: 88, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .scaleEffect(isCounterPulsing ? 1.12 : 1)
                    .shadow(color: CounterTheme.mint.opacity(0.7), radius: 14)
                    .accessibilityIdentifier("counter.value")
            }

            ChipBurstView(trigger: viewModel.chipBurstRevision)
        }
        .frame(height: 250)
        .onChange(of: viewModel.count) { _ in
            isCounterPulsing = true
            withAnimation(.spring(response: 0.26, dampingFraction: 0.45)) {
                isCounterPulsing = false
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 22) {
            CounterControlButton(
                title: "BET DOWN",
                systemImage: "minus",
                colors: [.purple, CounterTheme.hotPink],
                accessibilityIdentifier: "counter.decrement",
                action: viewModel.decrement
            )

            CounterControlButton(
                title: "BET UP",
                systemImage: "plus",
                colors: [CounterTheme.mint, .cyan],
                accessibilityIdentifier: "counter.increment",
                action: viewModel.increment
            )
        }
    }

    private var resetButton: some View {
        Button(action: viewModel.reset) {
            Label("RESET ROUND", systemImage: "arrow.counterclockwise")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white.opacity(0.72))
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
        }
        .accessibilityIdentifier("counter.reset")
    }
}



private struct ChipBurstView: View {
    let trigger: Int
    @State private var progress: CGFloat = 1

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                let angle = Double(index) / 12 * 2 * Double.pi
                let distance = CGFloat(72 + (index % 4) * 14)

                Image(systemName: index.isMultiple(of: 3) ? "star.fill" : "circle.fill")
                    .font(.system(size: index.isMultiple(of: 3) ? 13 : 9))
                    .foregroundColor(index.isMultiple(of: 2) ? CounterTheme.gold : CounterTheme.hotPink)
                    .scaleEffect(1 - progress * 0.35)
                    .offset(
                        x: CGFloat(cos(angle)) * distance * progress,
                        y: CGFloat(sin(angle)) * distance * progress
                    )
                    .rotationEffect(.degrees(Double(index) * 30 + Double(progress) * 120))
                    .opacity(1 - progress)
            }
        }
        .frame(width: 250, height: 250)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { newValue in
            guard newValue > 0 else { return }

            var resetTransaction = Transaction()
            resetTransaction.disablesAnimations = true
            withTransaction(resetTransaction) {
                progress = 0
            }

            withAnimation(.easeOut(duration: 0.75)) {
                progress = 1
            }
        }
    }
}
