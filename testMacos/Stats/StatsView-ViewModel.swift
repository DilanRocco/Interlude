//
//  StatsView-ViewModel.swift
//  testMacos
//

import Foundation
import Combine

extension StatsView {
    @MainActor class ViewModel: ObservableObject {
        @Published var completedToday: Int = 0
        @Published var skippedToday: Int = 0
        @Published var allTimeTotal: Int = 0

        private var refreshTimer: AnyCancellable?

        init() {
            refresh()
            refreshTimer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.refresh() }
        }

        func refresh() {
            completedToday = overlaysShown
            skippedToday = breaksSkipped
            allTimeTotal = UserDefaults.standard.integer(forKey: "totalBreaksAllTime")
        }
    }
}
