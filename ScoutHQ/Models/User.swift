import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var username: String
    var email: String
    var profileImageURL: String?
    var favoriteTeams: [String]
    var reputationScore: Double
    var followersCount: Int
    var followingCount: Int
    var reportsCount: Int
    var createdAt: Date
    var bio: String?
    var isPremium: Bool
    var accuracyScore: Double
    var totalVotesReceived: Int

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case profileImageURL = "profile_image_url"
        case favoriteTeams = "favorite_teams"
        case reputationScore = "reputation_score"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case reportsCount = "reports_count"
        case createdAt = "created_at"
        case bio
        case isPremium = "is_premium"
        case accuracyScore = "accuracy_score"
        case totalVotesReceived = "total_votes_received"
    }

    static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        lhs.id == rhs.id
    }

    var reputationTier: ReputationTier {
        switch reputationScore {
        case 0..<100: return .rookie
        case 100..<500: return .scout
        case 500..<1500: return .analyst
        case 1500..<5000: return .expert
        default: return .elite
        }
    }
}

enum ReputationTier: String, CaseIterable {
    case rookie = "Rookie Scout"
    case scout = "Scout"
    case analyst = "Analyst"
    case expert = "Expert"
    case elite = "Elite Scout"

    var color: String {
        switch self {
        case .rookie: return "gray"
        case .scout: return "blue"
        case .analyst: return "green"
        case .expert: return "purple"
        case .elite: return "gold"
        }
    }

    var icon: String {
        switch self {
        case .rookie: return "person.fill"
        case .scout: return "binoculars.fill"
        case .analyst: return "chart.bar.fill"
        case .expert: return "star.fill"
        case .elite: return "crown.fill"
        }
    }
}

struct TopScout: Identifiable {
    let id: String
    let username: String
    let reputationScore: Double
    let reportsCount: Int
    let accuracyScore: Double
    let tier: ReputationTier
    let profileImageURL: String?
    let rank: Int
}
