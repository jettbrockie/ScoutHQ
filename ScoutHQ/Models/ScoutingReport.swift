import Foundation
import FirebaseFirestore

struct ScoutingReport: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var userId: String
    var playerId: String
    var playerName: String
    var playerPosition: String
    var playerTeam: String
    var sport: Sport
    var strengths: String
    var weaknesses: String
    var comparison: String
    var rating: Double
    var positionRank: Int
    var upvotes: Int
    var downvotes: Int
    var createdAt: Date
    var username: String
    var userReputation: Double
    var userVotes: [String: VoteType]

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case playerId = "player_id"
        case playerName = "player_name"
        case playerPosition = "player_position"
        case playerTeam = "player_team"
        case sport
        case strengths
        case weaknesses
        case comparison
        case rating
        case positionRank = "position_rank"
        case upvotes
        case downvotes
        case createdAt = "created_at"
        case username
        case userReputation = "user_reputation"
        case userVotes = "user_votes"
    }

    static func == (lhs: ScoutingReport, rhs: ScoutingReport) -> Bool {
        lhs.id == rhs.id
    }

    var score: Int { upvotes - downvotes }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var ratingGrade: String {
        switch rating {
        case 90...100: return "A+"
        case 85..<90: return "A"
        case 80..<85: return "A-"
        case 75..<80: return "B+"
        case 70..<75: return "B"
        case 65..<70: return "B-"
        case 60..<65: return "C+"
        default: return "C"
        }
    }
}

enum VoteType: String, Codable {
    case up = "up"
    case down = "down"
}

enum ReportSortOption: String, CaseIterable {
    case mostAccurate = "Most Accurate"
    case mostPopular = "Most Popular"
    case newest = "Newest"
    case highestRated = "Highest Rated"
}

struct AIScoutReport: Codable, Equatable {
    var playerId: String
    var playerName: String
    var overallRating: Double
    var strengths: [String]
    var weaknesses: [String]
    var comparison: String
    var playstyleSummary: String
    var keyAttributes: [String: Double]
    var generatedAt: Date
    var reportCount: Int

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case playerName = "player_name"
        case overallRating = "overall_rating"
        case strengths
        case weaknesses
        case comparison
        case playstyleSummary = "playstyle_summary"
        case keyAttributes = "key_attributes"
        case generatedAt = "generated_at"
        case reportCount = "report_count"
    }
}

struct ReportDraft {
    var playerId: String = ""
    var playerName: String = ""
    var playerPosition: String = ""
    var playerTeam: String = ""
    var sport: Sport = .football
    var strengths: String = ""
    var weaknesses: String = ""
    var comparison: String = ""
    var rating: Double = 70
    var positionRank: Int = 1

    var isValid: Bool {
        !playerId.isEmpty &&
        !strengths.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !weaknesses.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !comparison.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        strengths.count >= 20 &&
        weaknesses.count >= 20
    }
}
