import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var trendingPlayers: [TrendingPlayer] = []
    @Published var topScouts: [TopScout] = []
    @Published var featuredReports: [ScoutingReport] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedSport: Sport = .football

    private let playerService = PlayerService.shared
    private let reportService = ReportService.shared
    private let mock = MockDataService.shared

    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }

        async let trending = playerService.fetchTrendingPlayers()
        async let scouts = loadTopScouts()
        async let reports = loadFeaturedReports()

        do {
            (trendingPlayers, topScouts, featuredReports) = try await (trending, scouts, reports)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadTopScouts() async throws -> [TopScout] {
        return mock.mockTopScouts()
    }

    private func loadFeaturedReports() async throws -> [ScoutingReport] {
        let players = mock.mockPlayers()
        let playerId = players.first?.id ?? "player_1"
        let reports = mock.mockReports(for: playerId)
        return Array(reports.sorted { $0.score > $1.score }.prefix(3))
    }

    var trendingBySelectedSport: [TrendingPlayer] {
        trendingPlayers.filter { $0.sport == selectedSport }
    }

    var risingPlayers: [TrendingPlayer] {
        trendingPlayers.filter { $0.rankChange > 0 }.sorted { $0.rankChange > $1.rankChange }
    }

    var fallingPlayers: [TrendingPlayer] {
        trendingPlayers.filter { $0.rankChange < 0 }.sorted { $0.rankChange < $1.rankChange }
    }
}
