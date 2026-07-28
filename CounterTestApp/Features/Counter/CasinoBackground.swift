//
//  CasinoBackground.swift
//  CounterTestApp
//
//  Created by Дмитро on 29.07.2026.
//

import SwiftUI

struct CasinoBackground: View {
    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let phase = context.date.timeIntervalSinceReferenceDate * .pi / 4
                let movement = CGFloat(sin(phase))

                ZStack {
                    LinearGradient(
                        colors: [CounterTheme.midnight, CounterTheme.violet, CounterTheme.midnight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Circle()
                        .fill(CounterTheme.hotPink.opacity(0.2))
                        .frame(width: 300, height: 300)
                        .blur(radius: 55)
                        .offset(x: 105 + movement * 25, y: -235 - movement * 25)

                    Circle()
                        .fill(CounterTheme.mint.opacity(0.16))
                        .frame(width: 260, height: 260)
                        .blur(radius: 60)
                        .offset(x: -115 - movement * 25, y: 250 + movement * 30)

                    casinoPattern
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var casinoPattern: some View {
        GeometryReader { proxy in
            ForEach(0..<18, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "diamond.fill" : "suit.club.fill")
                    .font(.system(size: CGFloat(9 + index % 4)))
                    .foregroundColor(.white.opacity(0.055))
                    .position(
                        x: CGFloat((index * 71) % max(Int(proxy.size.width), 1)),
                        y: CGFloat((index * 113) % max(Int(proxy.size.height), 1))
                    )
            }
        }
        .accessibilityHidden(true)
    }
}
