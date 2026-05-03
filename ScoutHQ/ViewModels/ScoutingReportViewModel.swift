import SwiftUI
import Combine

@MainActor
final class ScoutingReportViewModel: ObservableObject {
    @Published var draft = ReportDraft()
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var searchResults: [Player] = []
    @Published var searchText = ""
    @Published var error: String?
    @Published var showSuccess = false
    @Published var submittedReport: ScoutingReport?
    @Published var currentStep: ReportStep = .selectPlayer
    @Published var showPlayerSearch = false

    private let reportService = ReportService.shared
    private let playerService = PlayerService.shared
    private var searchTask: Task<Void, Never>?

    enum ReportStep: Int, CaseIterable {
        case selectPlayer = 0
        case details = 1
        case rating = 2
        case review = 3

        var title: String {
            switch self {
            case .selectPlayer: return "Select Player"
            case .details: return "Scout Report"
            case .rating: return "Rating"
            case .review: return "Review"
            }
        }

        var icon: String {
            switch self {
            case .selectPlayer: return "person.crop.circle"
            case .details: return "doc.text"
            case .rating: return "star.fill"
            case .review: return "checkmark.circle"
            }
        }
    }

    var canProceed: Bool {
        switch currentStep {
        case .selectPlayer:
            return !draft.playerId.isEmpty
        case .details:
            return draft.strengths.count >= Constants.Limits.minStrengthsLength &&
                   draft.weaknesses.count >= Constants.Limits.minWeaknessesLength &&
                   !draft.comparison.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .rating:
            return true
        case .review:
            return draft.isValid
        }
    }

    func selectPlayer(_ player: Player) {
        draft.playerId = player.id ?? ""
        draft.playerName = player.name
        draft.playerPosition = player.position
        draft.playerTeam = player.team
        draft.sport = player.sport
        showPlayerSearch = false
        searchText = player.name
        HapticFeedback.impact(.light)
    }

    func nextStep() {
        guard canProceed, currentStep.rawValue < ReportStep.allCases.count - 1 else { return }
        withAnimation(.scoutSpring) {
            currentStep = ReportStep(rawValue: currentStep.rawValue + 1) ?? .review
        }
        HapticFeedback.selection()
    }

    func previousStep() {
        guard currentStep.rawValue > 0 else { return }
        withAnimation(.scoutSpring) {
            currentStep = ReportStep(rawValue: currentStep.rawValue - 1) ?? .selectPlayer
        }
    }

    func searchPlayers(_ query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }
            isSearching = true
            do {
                searchResults = try await playerService.searchPlayers(query: query)
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

    func submitReport(user: AppUser) async {
        guard draft.isValid else { return }
        isLoading = true
        do {
            let report = try await reportService.submitReport(draft, user: user)
            submittedReport = report
            showSuccess = true
            HapticFeedback.notification(.success)
        } catch {
            self.error = error.localizedDescription
            HapticFeedback.notification(.error)
        }
        isLoading = false
    }

    func resetDraft() {
        draft = ReportDraft()
        currentStep = .selectPlayer
        searchText = ""
        searchResults = []
        showSuccess = false
        submittedReport = nil
    }
}
