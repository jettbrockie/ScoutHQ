import Foundation

// MARK: - Mock Data Service
// Provides realistic data for development and previews when Firebase is not configured.
final class MockDataService {
    static let shared = MockDataService()
    private init() {}

    // MARK: - Mock Players
    func mockPlayers() -> [Player] {
        Constants.mockPlayers.enumerated().map { index, data in
            Player(
                id: "player_\(index + 1)",
                name: data.name,
                sport: data.sport,
                position: data.position,
                team: data.team,
                school: nil,
                age: data.age,
                league: data.league,
                imageURL: nil,
                stats: mockStats(for: data.sport, position: data.position),
                consensusRating: data.rating,
                overallRank: index + 1,
                positionRank: (index % 5) + 1,
                previousOverallRank: max(1, index + 1 + Int.random(in: -3...5)),
                isProspect: data.league == .nflDraft || data.league == .nbaDraft || data.league == .mlbProspects,
                college: nil,
                hometown: nil,
                height: mockHeight(for: data.sport, position: data.position),
                weight: mockWeight(for: data.sport, position: data.position),
                draftYear: data.league == .nflDraft || data.league == .nbaDraft || data.league == .mlbProspects ? 2024 : nil,
                isTrending: index < 5,
                reportCount: Int.random(in: 10...200),
                createdAt: Date()
            )
        }
    }

    // MARK: - Mock Rankings
    func mockRankings(filter: RankingsFilter) -> [Ranking] {
        let players = mockPlayers()
            .filter { $0.sport == filter.sport }
            .filter { filter.position == "All" || $0.position == filter.position }

        return players.enumerated().map { index, player in
            Ranking(
                id: "ranking_\(player.id ?? "")",
                playerId: player.id ?? "",
                playerName: player.name,
                sport: player.sport,
                position: player.position,
                team: player.team,
                league: player.league,
                consensusScore: player.consensusRating,
                overallRank: index + 1,
                positionRank: (index % 5) + 1,
                previousRank: max(1, index + 1 + Int.random(in: -3...5)),
                playerImageURL: nil,
                reportCount: player.reportCount,
                trendingScore: Double.random(in: 10...100),
                age: player.age,
                height: player.height,
                weight: player.weight,
                updatedAt: Date()
            )
        }
    }

    // MARK: - Mock Scouting Reports
    func mockReports(for playerId: String) -> [ScoutingReport] {
        let players = mockPlayers()
        let player = players.first(where: { $0.id == playerId }) ?? players[0]

        return (0..<8).map { index in
            ScoutingReport(
                id: "report_\(playerId)_\(index)",
                userId: "user_\(index)",
                playerId: playerId,
                playerName: player.name,
                playerPosition: player.position,
                playerTeam: player.team,
                sport: player.sport,
                strengths: mockStrengths(for: player.sport, position: player.position),
                weaknesses: mockWeaknesses(for: player.sport, position: player.position),
                comparison: mockComparison(for: player.sport, position: player.position),
                rating: Double.random(in: 75...98),
                positionRank: Int.random(in: 1...10),
                upvotes: Int.random(in: 5...150),
                downvotes: Int.random(in: 0...20),
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...2592000)),
                username: mockUsernames[index % mockUsernames.count],
                userReputation: Double.random(in: 50...2000),
                userVotes: [:]
            )
        }
    }

    // MARK: - Mock AI Scout Report
    func mockAIReport(for player: Player) -> AIScoutReport {
        AIScoutReport(
            playerId: player.id ?? "",
            playerName: player.name,
            overallRating: player.consensusRating,
            strengths: mockAIStrengths(for: player.sport, position: player.position),
            weaknesses: mockAIWeaknesses(for: player.sport, position: player.position),
            comparison: mockComparison(for: player.sport, position: player.position),
            playstyleSummary: mockPlaystyle(for: player),
            keyAttributes: mockKeyAttributes(for: player.sport, position: player.position),
            generatedAt: Date(),
            reportCount: player.reportCount
        )
    }

    // MARK: - Mock Users / Top Scouts
    func mockTopScouts() -> [TopScout] {
        return mockUsernames.enumerated().map { index, username in
            TopScout(
                id: "scout_\(index)",
                username: username,
                reputationScore: Double(2000 - index * 150),
                reportsCount: Int.random(in: 20...200),
                accuracyScore: Double.random(in: 65...95),
                tier: index == 0 ? .elite : index < 3 ? .expert : index < 6 ? .analyst : .scout,
                profileImageURL: nil,
                rank: index + 1
            )
        }
    }

    // MARK: - Mock Trending Players
    func mockTrendingPlayers() -> [TrendingPlayer] {
        let players = mockPlayers().prefix(8)
        return players.map { player in
            TrendingPlayer(
                id: player.id ?? UUID().uuidString,
                playerId: player.id ?? "",
                name: player.name,
                sport: player.sport,
                position: player.position,
                team: player.team,
                consensusRating: player.consensusRating,
                rankChange: Int.random(in: -5...10),
                imageURL: nil,
                recentReportCount: Int.random(in: 5...50)
            )
        }
    }

    // MARK: - Helper Content

    private let mockUsernames = [
        "ScoutKing_23", "DraftGuru", "ProAnalyst", "GridironGhost",
        "HoopsExpert", "BaseballMind", "TalentFinder", "FieldVision"
    ]

    private func mockStats(for sport: Sport, position: String) -> [String: String] {
        switch sport {
        case .football:
            switch position {
            case "QB":
                return ["TDs": "38", "INT": "11", "YDS": "4,847", "CMP%": "67.2", "RTG": "104.2", "Att": "570"]
            case "RB":
                return ["Rush YDS": "1,459", "TDs": "14", "Att": "272", "YPC": "5.4", "Rec": "67", "Rec YDS": "543"]
            case "WR":
                return ["Rec": "102", "YDS": "1,535", "TDs": "12", "Y/R": "15.0", "Tgt": "151", "Long": "73"]
            case "TE":
                return ["Rec": "93", "YDS": "984", "TDs": "5", "Y/R": "10.6", "Tgt": "121"]
            default:
                return ["Sacks": "16.5", "TFL": "21", "Pressures": "54", "Solo": "45", "Ast": "23"]
            }
        case .basketball:
            switch position {
            case "PG", "SG":
                return ["PPG": "29.2", "APG": "8.4", "RPG": "5.1", "SPG": "1.5", "FG%": "48.3", "3P%": "36.8"]
            case "SF", "PF":
                return ["PPG": "26.8", "APG": "4.7", "RPG": "8.9", "BPG": "0.8", "FG%": "46.5", "3P%": "34.2"]
            default:
                return ["PPG": "24.5", "APG": "3.2", "RPG": "12.4", "BPG": "2.1", "FG%": "56.7", "FT%": "72.3"]
            }
        case .baseball:
            if ["SP", "RP"].contains(position) {
                return ["ERA": "2.33", "W": "15", "L": "9", "K": "236", "IP": "188.1", "WHIP": "0.95", "K/9": "11.3"]
            } else {
                return ["AVG": ".315", "HR": "44", "RBI": "118", "OBP": ".418", "SLG": ".604", "OPS": "1.022", "H": "183"]
            }
        }
    }

    private func mockHeight(for sport: Sport, position: String) -> String {
        switch sport {
        case .football:
            return ["QB", "WR", "CB"].contains(position) ? "6'2\"" : "6'4\""
        case .basketball:
            return ["PG", "SG"].contains(position) ? "6'3\"" : "6'9\""
        case .baseball:
            return "6'2\""
        }
    }

    private func mockWeight(for sport: Sport, position: String) -> String {
        switch sport {
        case .football:
            return ["QB", "WR", "CB"].contains(position) ? "215 lbs" : "265 lbs"
        case .basketball:
            return ["PG", "SG"].contains(position) ? "195 lbs" : "235 lbs"
        case .baseball:
            return "210 lbs"
        }
    }

    private func mockStrengths(for sport: Sport, position: String) -> String {
        let strengths: [Sport: [String: String]] = [
            .football: [
                "QB": "Elite arm talent with the ability to make every throw on the field. Exceptional pocket presence and ability to extend plays. Outstanding football IQ and pre-snap reading ability. Deadly accuracy on deep routes and back-shoulder throws.",
                "WR": "Exceptional route running with crisp breaks at every stem. Elite speed and ability to separate at all three levels. Strong hands in traffic and great body control. Excellent YAC ability after the catch.",
                "default": "Exceptional athleticism and motor. Elite instincts and football IQ. Great technique and fundamentals at the position."
            ],
            .basketball: [
                "PG": "Elite playmaking ability and court vision. Outstanding three-point shooting creating gravity on every possession. Exceptional ball-handling and first-step quickness. Great feel for the game and leadership qualities.",
                "C": "Dominant interior presence on both ends. Elite rim protection and shot-blocking instincts. Outstanding rebounding and post footwork. Excellent passing ability for the position.",
                "default": "Elite scoring ability from multiple areas. Great athleticism and defensive versatility. Outstanding competitive drive."
            ],
            .baseball: [
                "SP": "Plus-plus fastball velocity with elite movement. Elite strikeout pitch in the breaking ball. Exceptional command and ability to work all four quadrants. Advanced pitching IQ and mound presence.",
                "default": "Plus raw power with above-average hit tool. Excellent plate discipline and walk rate. Strong defensive skills and athleticism. Great makeup and work ethic."
            ]
        ]

        return strengths[sport]?[position] ?? strengths[sport]?["default"] ?? "Elite athleticism and competitive drive. Outstanding fundamentals and technical skills."
    }

    private func mockWeaknesses(for sport: Sport, position: String) -> String {
        let weaknesses: [Sport: [String: String]] = [
            .football: [
                "QB": "Can occasionally hold the ball too long when primary reads are covered. Decision-making under pressure needs some refinement. Has a tendency to force throws into tight windows late in games.",
                "WR": "Run blocking needs continued development as a professional. Can struggle with press coverage from elite corners. Drops the ball occasionally in traffic when expecting a hit.",
                "default": "Occasional lapses in technique against elite competition. Needs to improve consistency against the run. Still developing as a complete professional."
            ],
            .basketball: [
                "PG": "Needs to improve efficiency from mid-range. Can struggle to finish at the rim against physical defenders. Foul trouble is a concern in high-leverage situations.",
                "default": "Three-point shooting efficiency needs refinement. Can get into foul trouble with aggressive style of play. Needs improvement as an off-ball defender."
            ],
            .baseball: [
                "SP": "Shows occasional command lapses in the middle innings. Second time through the order can be a challenge. High pitch counts limit deeper games.",
                "default": "Contact rate against breaking balls needs improvement. Can expand the zone with two strikes. Defense at the position needs refinement."
            ]
        ]

        return weaknesses[sport]?[position] ?? weaknesses[sport]?["default"] ?? "Needs to improve consistency at the highest level. Some technique refinements required."
    }

    private func mockComparison(for sport: Sport, position: String) -> String {
        let comparisons: [Sport: [String: String]] = [
            .football: [
                "QB": "Patrick Mahomes", "WR": "Justin Jefferson",
                "TE": "Travis Kelce", "RB": "Christian McCaffrey",
                "DL": "Myles Garrett", "LB": "Micah Parsons",
                "CB": "Jalen Ramsey", "S": "Derwin James"
            ],
            .basketball: [
                "PG": "Stephen Curry", "SG": "Klay Thompson",
                "SF": "Paul George", "PF": "Giannis Antetokounmpo",
                "C": "Nikola Jokic"
            ],
            .baseball: [
                "SP": "Max Scherzer", "RP": "Josh Hader",
                "C": "J.T. Realmuto", "1B": "Freddie Freeman",
                "2B": "Ozzie Albies", "SS": "Trea Turner",
                "3B": "Nolan Arenado", "CF": "Mike Trout",
                "RF": "Ronald Acuna Jr.", "LF": "Juan Soto"
            ]
        ]

        return comparisons[sport]?[position] ?? "Elite player at their position"
    }

    private func mockPlaystyle(for player: Player) -> String {
        switch player.sport {
        case .football:
            if player.position == "QB" {
                return "A dynamic dual-threat quarterback who excels at extending plays with his legs while maintaining elite accuracy as a passer. His ability to read defenses pre-snap and manipulate coverage with his eyes makes him one of the most dangerous offensive weapons in football. Thrives in up-tempo offense and excels at finding checkdowns when primary options aren't available."
            } else {
                return "A technically refined player who combines elite athleticism with exceptional football intelligence. Known for their ability to make an impact in critical moments, they exemplify the modern professional football player — versatile, physical, and mentally sharp."
            }
        case .basketball:
            return "A modern NBA player who seamlessly blends elite scoring with playmaking ability. Their ability to create off the dribble and knock down shots from the perimeter stretches defenses and creates opportunities for teammates. Strong motor and competitive instincts translate to both ends of the floor."
        case .baseball:
            if ["SP", "RP"].contains(player.position) {
                return "A power arm with the feel and command of a craftsman. Uses an arsenal of pitches to attack hitters at different stages of the at-bat, relying on elite strikeout stuff while maintaining enough contact management to go deep into games."
            } else {
                return "A complete hitter who combines raw power with plate discipline beyond their years. Their ability to work counts and punish mistakes throughout the zone makes them one of the more dangerous offensive presences in the lineup."
            }
        }
    }

    private func mockAIStrengths(for sport: Sport, position: String) -> [String] {
        switch sport {
        case .football:
            return [
                "Elite arm talent and throwing mechanics",
                "Outstanding football IQ and pre-snap reads",
                "Exceptional pocket presence under pressure",
                "Deep ball accuracy rated in top tier percentile",
                "Strong leadership and command of the huddle"
            ]
        case .basketball:
            return [
                "Elite scoring efficiency across all three zones",
                "Outstanding court vision and playmaking",
                "Above-average defensive versatility",
                "High basketball IQ in late-game situations",
                "Excellent free throw shooting under pressure"
            ]
        case .baseball:
            return [
                "Plus-plus velocity with elite movement profile",
                "Advanced command of secondary pitches",
                "Exceptional competitive makeup and mound presence",
                "Strong strikeout-to-walk ratio",
                "Elite athleticism enhancing fielding ability"
            ]
        }
    }

    private func mockAIWeaknesses(for sport: Sport, position: String) -> [String] {
        switch sport {
        case .football:
            return [
                "Decision-making under extreme pressure needs refinement",
                "Occasional tendency to hold the ball too long",
                "Screen game execution inconsistent"
            ]
        case .basketball:
            return [
                "Mid-range efficiency below league average",
                "Can struggle finishing at rim against physicality",
                "Foul trouble in high-leverage situations"
            ]
        case .baseball:
            return [
                "Second time through the order efficiency drops",
                "Command lapses in high-leverage innings",
                "High pitch count limits deeper outings"
            ]
        }
    }

    private func mockKeyAttributes(for sport: Sport, position: String) -> [String: Double] {
        switch sport {
        case .football:
            return [
                "Arm Strength": 95, "Accuracy": 92, "Mobility": 88,
                "Decision Making": 90, "Leadership": 94
            ]
        case .basketball:
            return [
                "Scoring": 94, "Playmaking": 90, "Defense": 82,
                "Athleticism": 91, "Shooting": 88
            ]
        case .baseball:
            return [
                "Velocity": 96, "Command": 88, "Strikeout Rate": 93,
                "Durability": 85, "Pitch Mix": 90
            ]
        }
    }
}
