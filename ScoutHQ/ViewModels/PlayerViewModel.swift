import SwiftUI
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var player: Player?
    @Published var reports: [ScoutingReport] = []
    @Published var aiReport: AIScoutReport?
    @Published var isLoadingPlayer = false
    @Published var isLoadingReports = false
    @Published var isLoadingAI = false
    @Published var error: String?
    @Published var sortOption: ReportSortOption = .mostPopular
    @Published var selectedReport: ScoutingReport?
    @Published var showReportDetail = false

    private let playerService = PlayerService.shared
    private let reportService = ReportService.shared
    private let aiService = AIService.shared
    private let mock = MockDataService.shared

    func loadPlayer(id: String) async {
        isLoadingPlayer = true
        defer { isLoadingPlayer = false }
        do {
            player = try await playerService.fetchPlayer(id: id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadReports(playerId: String) async {
        isLoadingReports = true
        defer { isLoadingReports = false }
        do {
            let fetched = try await reportService.fetchReports(for: playerId)
            reports = sortedReports(fetched)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadAIReport(playerId: String) async {
        guard let player = player else { return }
        isLoadingAI = true
        defer { isLoadingAI = false }

        // Check cache first
        if let cached = await aiService.fetchCachedReport(playerId: playerId) {
            let ageInHours = Date().timeIntervalSince(cached.generatedAt) / 3600
            if ageInHours < 24 {
                aiReport = cached
                return
            }
        }

        do {
            let generated = try await aiService.generateScoutingReport(for: player, reports: reports)
            aiReport = generated
            try? await aiService.cacheReport(generated)
        } catch {
            // Fall back to mock if AI fails
            aiReport = mock.mockAIReport(for: player)
        }
    }

    func loadAll(playerId: String) async {
        await loadPlayer(id: playerId)
        await loadReports(playerId: playerId)
        if !reports.isEmpty {
            await loadAIReport(playerId: playerId)
        } else if let player = player {
            aiReport = mock.mockAIReport(for: player)
        }
    }

    func voteOnReport(_ report: ScoutingReport, vote: VoteType, userId: String) async {
        guard let reportId = report.id else { return }
        do {
            try await reportService.voteOnReport(reportId, vote: vote, userId: userId)
            // Update local state optimistically
            if let index = reports.firstIndex(where: { $0.id == reportId }) {
                var updated = reports[index]
                let existingVote = updated.userVotes[userId]
                if existingVote == vote {
                    updated.userVotes.removeValue(forKey: userId)
                    if vote == .up { updated.upvotes -= 1 } else { updated.downvotes -= 1 }
                } else {
                    if let existing = existingVote {
                        if existing == .up { updated.upvotes -= 1 } else { updated.downvotes -= 1 }
                    }
                    updated.userVotes[userId] = vote
                    if vote == .up { updated.upvotes += 1 } else { updated.downvotes += 1 }
                }
                reports[index] = updated
                HapticFeedback.impact(.light)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func changeSortOption(_ option: ReportSortOption) {
        sortOption = option
        reports = sortedReports(reports)
    }

    private func sortedReports(_ reports: [ScoutingReport]) -> [ScoutingReport] {
        switch sortOption {
        case .mostPopular: return reports.sorted { $0.score > $1.score }
        case .mostAccurate: return reports.sorted { $0.userReputation > $1.userReputation }
        case .newest: return reports.sorted { $0.createdAt > $1.createdAt }
        case .highestRated: return reports.sorted { $0.rating > $1.rating }
        }
    }

    var averageRating: Double {
        guard !reports.isEmpty else { return player?.consensusRating ?? 0 }
        return reports.map(\.rating).reduce(0, +) / Double(reports.count)
    }

    var ratingDistribution: [Double] {
        guard !reports.isEmpty else { return Array(repeating: 0, count: 5) }
        let buckets: [ClosedRange<Double>] = [0...60, 61...70, 71...80, 81...90, 91...100]
        return buckets.map { range in
            Double(reports.filter { range.contains($0.rating) }.count) / Double(reports.count)
        }
    }
}
