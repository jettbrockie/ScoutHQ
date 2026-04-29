import Foundation
import FirebaseFirestore

struct Ranking: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var playerId: String
    var playerName: String
    var sport: Sport
    var position: String
    var team: String
    var league: League
    var consensusScore: Double
    var overallRank: Int
    var positionRank: Int
    var previousRank: Int
    var playerImageURL: String?
    var reportCount: Int
    var trendingScore: Double
    var age: Int
    var height: String?
    var weight: String?
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case playerId = "player_id"
        case playerName = "player_name"
        case sport
        case position
        case team
        case league
        case consensusScore = "consensus_score"
        case overallRank = "overall_rank"
        case positionRank = "position_rank"
        case previousRank = "previous_rank"
        case playerImageURL = "player_image_url"
        case reportCount = "report_count"
        case trendingScore = "trending_score"
        case age
        case height
        case weight
        case updatedAt = "updated_at"
    }

    static func == (lhs: Ranking, rhs: Ranking) -> Bool {
        lhs.id == rhs.id
    }

    var rankChange: Int {
        previousRank > 0 ? previousRank - overallRank : 0
    }

    var rankChangeDisplay: String {
        let change = rankChange
        if change > 0 { return "▲\(change)" }
        if change < 0 { return "▼\(abs(change))" }
        return "—"
    }

    var isTrending: Bool {
        trendingScore > 50
    }

    var gradeLabel: String {
        switch consensusScore {
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

struct RankingsFilter: Equatable {
    var sport: Sport = .football
    var league: League = .nfl
    var position: String = "All"

    var availablePositions: [String] {
        var positions = ["All"]
        switch sport {
        case .football:
            positions += FootballPosition.allCases.map(\.rawValue)
        case .basketball:
            positions += BasketballPosition.allCases.map(\.rawValue)
        case .baseball:
            positions += BaseballPosition.allCases.map(\.rawValue)
        }
        return positions
    }
}

struct TrendingPlayer: Identifiable {
    let id: String
    let playerId: String
    let name: String
    let sport: Sport
    let position: String
    let team: String
    let consensusRating: Double
    let rankChange: Int
    let imageURL: String?
    let recentReportCount: Int
}

struct HotTake: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var username: String
    var content: String
    var playerId: String?
    var playerName: String?
    var sport: Sport?
    var likes: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case content
        case playerId = "player_id"
        case playerName = "player_name"
        case sport
        case likes
        case createdAt = "created_at"
    }
}
