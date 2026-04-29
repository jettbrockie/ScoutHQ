import SwiftUI
import Combine
import PhotosUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var userReports: [ScoutingReport] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isEditing = false
    @Published var editUsername = ""
    @Published var editBio = ""
    @Published var editFavoriteTeams: [String] = []
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var profileImage: Image?
    @Published var isSaving = false
    @Published var showSaveSuccess = false
    @Published var showingUser: AppUser?

    private let authService = AuthService.shared
    private let reportService = ReportService.shared

    var currentUser: AppUser? { authService.currentUser }

    func loadProfile() async {
        guard let user = currentUser else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            userReports = try await reportService.fetchUserReports(userId: user.id ?? "")
        } catch {
            self.error = error.localizedDescription
        }
    }

    func startEditing() {
        guard let user = currentUser else { return }
        editUsername = user.username
        editBio = user.bio ?? ""
        editFavoriteTeams = user.favoriteTeams
        isEditing = true
    }

    func saveProfile() async {
        guard var user = currentUser else { return }
        isSaving = true
        defer { isSaving = false }

        user.username = editUsername
        user.bio = editBio.isEmpty ? nil : editBio
        user.favoriteTeams = editFavoriteTeams

        do {
            try await authService.updateUserProfile(user)
            showSaveSuccess = true
            isEditing = false
            HapticFeedback.notification(.success)
        } catch {
            self.error = error.localizedDescription
            HapticFeedback.notification(.error)
        }
    }

    func cancelEditing() {
        isEditing = false
        editUsername = ""
        editBio = ""
        editFavoriteTeams = []
    }

    func signOut() {
        try? authService.signOut()
    }

    var reportsByRating: [ScoutingReport] {
        userReports.sorted { $0.rating > $1.rating }
    }

    var recentReports: [ScoutingReport] {
        userReports.sorted { $0.createdAt > $1.createdAt }.prefix(5).map { $0 }
    }

    var reportsBySport: [Sport: [ScoutingReport]] {
        Dictionary(grouping: userReports, by: \.sport)
    }

    var totalVotesReceived: Int {
        currentUser?.totalVotesReceived ?? userReports.reduce(0) { $0 + $1.upvotes }
    }

    var averageRating: Double {
        guard !userReports.isEmpty else { return 0 }
        return userReports.map(\.rating).reduce(0, +) / Double(userReports.count)
    }

    func allSportTeams(for sport: Sport) -> [String] {
        switch sport {
        case .football:
            return ["Arizona Cardinals", "Atlanta Falcons", "Baltimore Ravens", "Buffalo Bills",
                    "Carolina Panthers", "Chicago Bears", "Cincinnati Bengals", "Cleveland Browns",
                    "Dallas Cowboys", "Denver Broncos", "Detroit Lions", "Green Bay Packers",
                    "Houston Texans", "Indianapolis Colts", "Jacksonville Jaguars", "Kansas City Chiefs",
                    "Las Vegas Raiders", "Los Angeles Chargers", "Los Angeles Rams", "Miami Dolphins",
                    "Minnesota Vikings", "New England Patriots", "New Orleans Saints", "New York Giants",
                    "New York Jets", "Philadelphia Eagles", "Pittsburgh Steelers", "San Francisco 49ers",
                    "Seattle Seahawks", "Tampa Bay Buccaneers", "Tennessee Titans", "Washington Commanders"]
        case .basketball:
            return ["Atlanta Hawks", "Boston Celtics", "Brooklyn Nets", "Charlotte Hornets",
                    "Chicago Bulls", "Cleveland Cavaliers", "Dallas Mavericks", "Denver Nuggets",
                    "Detroit Pistons", "Golden State Warriors", "Houston Rockets", "Indiana Pacers",
                    "Los Angeles Clippers", "Los Angeles Lakers", "Memphis Grizzlies", "Miami Heat",
                    "Milwaukee Bucks", "Minnesota Timberwolves", "New Orleans Pelicans", "New York Knicks",
                    "OKC Thunder", "Orlando Magic", "Philadelphia 76ers", "Phoenix Suns",
                    "Portland Trail Blazers", "Sacramento Kings", "San Antonio Spurs", "Toronto Raptors",
                    "Utah Jazz", "Washington Wizards"]
        case .baseball:
            return ["Arizona Diamondbacks", "Atlanta Braves", "Baltimore Orioles", "Boston Red Sox",
                    "Chicago Cubs", "Chicago White Sox", "Cincinnati Reds", "Cleveland Guardians",
                    "Colorado Rockies", "Detroit Tigers", "Houston Astros", "Kansas City Royals",
                    "Los Angeles Angels", "Los Angeles Dodgers", "Miami Marlins", "Milwaukee Brewers",
                    "Minnesota Twins", "New York Mets", "New York Yankees", "Oakland Athletics",
                    "Philadelphia Phillies", "Pittsburgh Pirates", "San Diego Padres", "San Francisco Giants",
                    "Seattle Mariners", "St. Louis Cardinals", "Tampa Bay Rays", "Texas Rangers",
                    "Toronto Blue Jays", "Washington Nationals"]
        }
    }
}
