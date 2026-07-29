//
//  CounterControlButton.swift
//  CounterTestApp
//
//  Created by Дмитро on 29.07.2026.
//

import Combine
import Foundation

@MainActor
final class CounterViewModel: ObservableObject {
    @Published private(set) var count = 0
    @Published private(set) var bestScore: Int
    @Published private(set) var recordRevision = 0
    @Published private(set) var chipBurstRevision = 0

    private enum StorageKey {
        static let bestScore = "counter.bestScore"
    }

    private let storage: StorageService
    private let analyticsService: AnalyticsServiceProtocol

    init(storage: StorageService, analyticsService: AnalyticsServiceProtocol) {
        self.storage = storage
        self.analyticsService = analyticsService

        self.bestScore = storage.value(forKey: StorageKey.bestScore) ?? 0
    }

    func startGame() {
        analyticsService.track(event: "counter_game_started")
    }

    func increment() {
        count += 1
        chipBurstRevision += 1
        analyticsService.track(
            event: "counter_incremented",
            parameters: ["count": String(count)]
        )
        guard count > bestScore else { return }

        bestScore = count
        recordRevision += 1
        storage.save(bestScore, forKey: StorageKey.bestScore)
        analyticsService.track(
            event: "counter_new_best_score",
            parameters: ["score": String(bestScore)]
        )
    }

    func decrement() {
        count = max(0, count - 1)
        analyticsService.track(
            event: "counter_decremented",
            parameters: ["count": String(count)]
        )
    }

    func reset() {
        count = 0
        analyticsService.track(
            event: "counter_reset",
            parameters: ["best_score": String(bestScore)]
        )
    }

}
