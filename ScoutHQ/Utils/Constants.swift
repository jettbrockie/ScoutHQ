import Foundation

enum Constants {
    enum Firestore {
        static let usersCollection = "users"
        static let playersCollection = "players"
        static let reportsCollection = "reports"
        static let rankingsCollection = "rankings"
        static let aiReportsCollection = "ai_reports"
        static let hotTakesCollection = "hot_takes"
        static let votesCollection = "votes"
        static let followsCollection = "follows"
    }

    enum API {
        // Replace with your actual Anthropic API key
        static let anthropicAPIKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
        static let anthropicBaseURL = "https://api.anthropic.com/v1/messages"
        static let claudeModel = "claude-opus-4-7"

        static let sportsDataAPIKey = ProcessInfo.processInfo.environment["SPORTS_DATA_API_KEY"] ?? ""
    }

    enum App {
        static let appName = "ScoutHQ"
        static let version = "1.0.0"
        static let buildNumber = "1"
        static let supportEmail = "support@scouthq.app"
        static let privacyURL = "https://scouthq.app/privacy"
        static let termsURL = "https://scouthq.app/terms"
    }

    enum Pagination {
        static let defaultPageSize = 20
        static let rankingsPageSize = 50
        static let reportsPageSize = 10
    }

    enum Reputation {
        static let reportSubmittedPoints: Double = 10
        static let reportUpvotedPoints: Double = 5
        static let reportDownvotedPoints: Double = -2
        static let accuratePredictionPoints: Double = 25
    }

    enum Animation {
        static let standard = 0.3
        static let fast = 0.15
        static let slow = 0.5
        static let spring = 0.4
    }

    enum Limits {
        static let maxReportLength = 1000
        static let maxBioLength = 160
        static let maxUsernameLength = 30
        static let minUsernameLength = 3
        static let maxHotTakeLength = 280
        static let minStrengthsLength = 20
        static let minWeaknessesLength = 20
    }

    enum UserDefaults {
        static let hasSeenOnboarding = "has_seen_onboarding"
        static let selectedSport = "selected_sport"
        static let darkModeEnabled = "dark_mode_enabled"
        static let notificationsEnabled = "notifications_enabled"
        static let isPremium = "is_premium"
    }

    enum Notifications {
        static let rankingChanged = "ranking_changed"
        static let newReport = "new_report"
        static let reportVoted = "report_voted"
        static let newFollower = "new_follower"
    }

    static let mockPlayers: [(name: String, sport: Sport, position: String, team: String, league: League, age: Int, rating: Double)] = [
        // Football - NFL
        ("Patrick Mahomes", .football, "QB", "Kansas City Chiefs", .nfl, 28, 98.5),
        ("Josh Allen", .football, "QB", "Buffalo Bills", .nfl, 27, 97.2),
        ("Jalen Hurts", .football, "QB", "Philadelphia Eagles", .nfl, 25, 94.8),
        ("Justin Jefferson", .football, "WR", "Minnesota Vikings", .nfl, 24, 96.1),
        ("Tyreek Hill", .football, "WR", "Miami Dolphins", .nfl, 29, 94.5),
        ("Travis Kelce", .football, "TE", "Kansas City Chiefs", .nfl, 34, 95.3),
        ("Micah Parsons", .football, "LB", "Dallas Cowboys", .nfl, 24, 97.8),
        ("Myles Garrett", .football, "DL", "Cleveland Browns", .nfl, 28, 96.5),
        ("Sauce Gardner", .football, "CB", "New York Jets", .nfl, 23, 94.2),
        ("Christian McCaffrey", .football, "RB", "San Francisco 49ers", .nfl, 27, 95.9),
        // Football - Draft Prospects
        ("Caleb Williams", .football, "QB", "USC", .nflDraft, 22, 92.0),
        ("Marvin Harrison Jr.", .football, "WR", "Ohio State", .nflDraft, 21, 91.5),
        ("Malik Nabers", .football, "WR", "LSU", .nflDraft, 21, 90.8),
        ("Joe Alt", .football, "OL", "Notre Dame", .nflDraft, 21, 90.2),
        ("Olu Fashanu", .football, "OL", "Penn State", .nflDraft, 22, 89.5),
        // Basketball - NBA
        ("Nikola Jokic", .basketball, "C", "Denver Nuggets", .nba, 28, 98.8),
        ("Luka Doncic", .basketball, "PG", "Dallas Mavericks", .nba, 24, 97.5),
        ("Giannis Antetokounmpo", .basketball, "PF", "Milwaukee Bucks", .nba, 29, 97.0),
        ("Jayson Tatum", .basketball, "SF", "Boston Celtics", .nba, 25, 94.5),
        ("Stephen Curry", .basketball, "PG", "Golden State Warriors", .nba, 35, 95.2),
        ("Joel Embiid", .basketball, "C", "Philadelphia 76ers", .nba, 29, 96.1),
        ("Shai Gilgeous-Alexander", .basketball, "SG", "OKC Thunder", .nba, 25, 95.8),
        ("Anthony Edwards", .basketball, "SG", "Minnesota Timberwolves", .nba, 22, 93.5),
        // Basketball - Draft Prospects
        ("Victor Wembanyama", .basketball, "C", "Spurs", .nbaDraft, 20, 97.5),
        ("Scoot Henderson", .basketball, "PG", "Blazers", .nbaDraft, 20, 89.5),
        ("Brandon Miller", .basketball, "SF", "Charlotte Hornets", .nbaDraft, 21, 88.0),
        // Baseball - MLB
        ("Shohei Ohtani", .baseball, "SP", "Los Angeles Angels", .mlb, 29, 99.0),
        ("Ronald Acuna Jr.", .baseball, "RF", "Atlanta Braves", .mlb, 25, 97.5),
        ("Mookie Betts", .baseball, "RF", "Los Angeles Dodgers", .mlb, 31, 96.0),
        ("Freddie Freeman", .baseball, "1B", "Los Angeles Dodgers", .mlb, 33, 94.5),
        ("Juan Soto", .baseball, "LF", "New York Yankees", .mlb, 25, 96.8),
        ("Gerrit Cole", .baseball, "SP", "New York Yankees", .mlb, 33, 93.5),
        // Baseball - Prospects
        ("Jackson Holliday", .baseball, "SS", "Baltimore Orioles", .mlbProspects, 20, 92.0),
        ("Paul Skenes", .baseball, "SP", "Pittsburgh Pirates", .mlbProspects, 21, 94.5),
        ("Dylan Crews", .baseball, "CF", "Washington Nationals", .mlbProspects, 22, 89.5),
    ]
}
