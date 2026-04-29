import SwiftUI
import Combine

@MainActor
final class RankingsViewModel: ObservableObject {
    @Published var rankings: [Ranking] = []
    @Published var filter = RankingsFilter()
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""
    @Published var showFilterSheet = false

    private let rankingService = RankingService.shared

    var filteredRankings: [Ranking] {
        if searchText.isEmpty { return rankings }
        return rankings.filter {
            $0.playerName.localizedCaseInsensitiveContains(searchText) ||
            $0.team.localizedCaseInsensitiveContains(searchText) ||
            $0.position.localizedCaseInsensitiveContains(searchText)
        }
    }

    var displayRankings: [Ranking] {
        filteredRankings
    }

    func loadRankings() async {
        isLoading = true
        defer { isLoading = false }
        do {
            rankings = try await rankingService.fetchRankings(filter: filter)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func applyFilter(_ newFilter: RankingsFilter) {
        filter = newFilter
        Task { await loadRankings() }
    }

    func selectSport(_ sport: Sport) {
        filter.sport = sport
        filter.league = sport.proLeague
        filter.position = "All"
        Task { await loadRankings() }
    }

    func selectLeague(_ league: League) {
        filter.league = league
        filter.position = "All"
        Task { await loadRankings() }
    }

    func selectPosition(_ position: String) {
        filter.position = position
        Task { await loadRankings() }
    }
}
