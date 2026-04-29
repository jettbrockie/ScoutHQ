import Foundation
import FirebaseFirestore

enum Sport: String, Codable, CaseIterable, Identifiable {
    case football = "Football"
    case basketball = "Basketball"
    case baseball = "Baseball"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .football: return "football.fill"
        case .basketball: return "basketball.fill"
        case .baseball: return "baseball.fill"
        }
    }

    var accentColor: String {
        switch self {
        case .football: return "footballGreen"
        case .basketball: return "basketballOrange"
        case .baseball: return "baseballRed"
        }
    }

    var leagues: [League] {
        switch self {
        case .football: return [.nfl, .nflDraft, .college]
        case .basketball: return [.nba, .nbaDraft, .college]
        case .baseball: return [.mlb, .mlbProspects]
        }
    }

    var proLeague: League {
        switch self {
        case .football: return .nfl
        case .basketball: return .nba
        case .baseball: return .mlb
        }
    }
}

enum League: String, Codable, CaseIterable, Identifiable {
    case nfl = "NFL"
    case nba = "NBA"
    case mlb = "MLB"
    case nflDraft = "NFL Draft"
    case nbaDraft = "NBA Draft"
    case mlbProspects = "MLB Prospects"
    case college = "College"

    var id: String { rawValue }
}

enum FootballPosition: String, CaseIterable {
    case qb = "QB"
    case rb = "RB"
    case wr = "WR"
    case te = "TE"
    case ol = "OL"
    case dl = "DL"
    case lb = "LB"
    case cb = "CB"
    case s = "S"
    case k = "K"
    case p = "P"
}

enum BasketballPosition: String, CaseIterable {
    case pg = "PG"
    case sg = "SG"
    case sf = "SF"
    case pf = "PF"
    case c = "C"
}

enum BaseballPosition: String, CaseIterable {
    case sp = "SP"
    case rp = "RP"
    case c = "C"
    case firstBase = "1B"
    case secondBase = "2B"
    case thirdBase = "3B"
    case ss = "SS"
    case lf = "LF"
    case cf = "CF"
    case rf = "RF"
    case dh = "DH"
}

struct Player: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var name: String
    var sport: Sport
    var position: String
    var team: String
    var school: String?
    var age: Int
    var league: League
    var imageURL: String?
    var stats: [String: String]
    var consensusRating: Double
    var overallRank: Int
    var positionRank: Int
    var previousOverallRank: Int
    var isProspect: Bool
    var college: String?
    var hometown: String?
    var height: String?
    var weight: String?
    var draftYear: Int?
    var isTrending: Bool
    var reportCount: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sport
        case position
        case team
        case school
        case age
        case league
        case imageURL = "image_url"
        case stats
        case consensusRating = "consensus_rating"
        case overallRank = "overall_rank"
        case positionRank = "position_rank"
        case previousOverallRank = "previous_overall_rank"
        case isProspect = "is_prospect"
        case college
        case hometown
        case height
        case weight
        case draftYear = "draft_year"
        case isTrending = "is_trending"
        case reportCount = "report_count"
        case createdAt = "created_at"
    }

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }

    var rankChange: Int {
        previousOverallRank - overallRank
    }

    var rankChangeDisplay: String {
        let change = rankChange
        if change > 0 { return "+\(change)" }
        if change < 0 { return "\(change)" }
        return "—"
    }

    var ratingGrade: String {
        switch consensusRating {
        case 90...100: return "A+"
        case 85..<90: return "A"
        case 80..<85: return "A-"
        case 75..<80: return "B+"
        case 70..<75: return "B"
        case 65..<70: return "B-"
        case 60..<65: return "C+"
        case 55..<60: return "C"
        default: return "C-"
        }
    }
}

struct PlayerSearchResult: Identifiable {
    let id: String
    let name: String
    let sport: Sport
    let position: String
    let team: String
    let imageURL: String?
    let consensusRating: Double
}
