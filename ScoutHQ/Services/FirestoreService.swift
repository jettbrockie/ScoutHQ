import Foundation
import FirebaseFirestore
import Combine

// MARK: - Base Firestore Service
final class FirestoreService {
    static let shared = FirestoreService()
    let db = Firestore.firestore()

    private init() {}

    func document<T: Codable>(_ collection: String, id: String) async throws -> T {
        let doc = try await db.collection(collection).document(id).getDocument()
        return try doc.data(as: T.self)
    }

    func collection<T: Codable>(_ collection: String, query: ((Query) -> Query)? = nil) async throws -> [T] {
        var ref: Query = db.collection(collection)
        if let query = query {
            ref = query(ref)
        }
        let snapshot = try await ref.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: T.self) }
    }

    func create<T: Codable>(_ value: T, in collection: String, id: String? = nil) async throws -> String {
        if let id = id {
            try db.collection(collection).document(id).setData(from: value)
            return id
        } else {
            let ref = try db.collection(collection).addDocument(from: value)
            return ref.documentID
        }
    }

    func update<T: Codable>(_ value: T, in collection: String, id: String) async throws {
        try db.collection(collection).document(id).setData(from: value, merge: true)
    }

    func delete(from collection: String, id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }

    func incrementField(_ field: String, by amount: Int, in collection: String, id: String) async throws {
        try await db.collection(collection).document(id).updateData([
            field: FieldValue.increment(Int64(amount))
        ])
    }

    func listen<T: Codable>(
        collection: String,
        query: ((Query) -> Query)? = nil,
        onChange: @escaping ([T]) -> Void
    ) -> ListenerRegistration {
        var ref: Query = db.collection(collection)
        if let query = query {
            ref = query(ref)
        }
        return ref.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot else { return }
            let items = snapshot.documents.compactMap { try? $0.data(as: T.self) }
            onChange(items)
        }
    }
}

// MARK: - Player Service
final class PlayerService {
    static let shared = PlayerService()
    private let firestore = FirestoreService.shared
    private let mock = MockDataService.shared

    private init() {}

    func fetchPlayers(sport: Sport? = nil, league: League? = nil) async throws -> [Player] {
        // Return mock data for now — replace with real Firestore when seeded
        var players = mock.mockPlayers()
        if let sport = sport { players = players.filter { $0.sport == sport } }
        if let league = league { players = players.filter { $0.league == league } }
        return players
    }

    func fetchPlayer(id: String) async throws -> Player {
        let players = mock.mockPlayers()
        if let player = players.first(where: { $0.id == id }) {
            return player
        }
        return try await firestore.document(Constants.Firestore.playersCollection, id: id)
    }

    func searchPlayers(query: String) async throws -> [Player] {
        let players = mock.mockPlayers()
        if query.isEmpty { return players }
        return players.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.team.localizedCaseInsensitiveContains(query) ||
            $0.position.localizedCaseInsensitiveContains(query)
        }
    }

    func fetchTrendingPlayers() async throws -> [TrendingPlayer] {
        return mock.mockTrendingPlayers()
    }

    func seedPlayersIfNeeded() async throws {
        let snapshot = try await FirestoreService.shared.db
            .collection(Constants.Firestore.playersCollection)
            .limit(to: 1)
            .getDocuments()

        guard snapshot.documents.isEmpty else { return }

        let players = mock.mockPlayers()
        let batch = FirestoreService.shared.db.batch()

        for player in players {
            let ref = FirestoreService.shared.db
                .collection(Constants.Firestore.playersCollection)
                .document(player.id ?? UUID().uuidString)
            if let data = try? Firestore.Encoder().encode(player) {
                batch.setData(data, forDocument: ref)
            }
        }

        try await batch.commit()
    }
}

// MARK: - Ranking Service
final class RankingService {
    static let shared = RankingService()
    private let firestore = FirestoreService.shared
    private let mock = MockDataService.shared

    private init() {}

    func fetchRankings(filter: RankingsFilter) async throws -> [Ranking] {
        return mock.mockRankings(filter: filter)
    }

    func updateConsensusRankings(for playerId: String) async throws {
        let reports: [ScoutingReport] = try await firestore.collection(
            Constants.Firestore.reportsCollection
        ) { query in
            query.whereField("player_id", isEqualTo: playerId)
        }

        guard !reports.isEmpty else { return }

        let weightedRating = calculateWeightedRating(reports: reports)

        try await firestore.update(
            ["consensus_score": weightedRating, "report_count": reports.count],
            in: Constants.Firestore.rankingsCollection,
            id: "ranking_\(playerId)"
        )
    }

    private func calculateWeightedRating(reports: [ScoutingReport]) -> Double {
        guard !reports.isEmpty else { return 0 }

        let totalWeight = reports.map { max(1.0, $0.userReputation / 100.0) }.reduce(0, +)
        let weightedSum = reports.map { report in
            let weight = max(1.0, report.userReputation / 100.0)
            return report.rating * weight
        }.reduce(0, +)

        return (weightedSum / totalWeight).rounded(to: 1)
    }
}

// MARK: - Report Service
final class ReportService {
    static let shared = ReportService()
    private let firestore = FirestoreService.shared
    private let mock = MockDataService.shared

    private init() {}

    func fetchReports(for playerId: String) async throws -> [ScoutingReport] {
        return mock.mockReports(for: playerId)
    }

    func fetchUserReports(userId: String) async throws -> [ScoutingReport] {
        return try await firestore.collection(Constants.Firestore.reportsCollection) { query in
            query.whereField("user_id", isEqualTo: userId)
                .order(by: "created_at", descending: true)
        }
    }

    func submitReport(_ draft: ReportDraft, user: AppUser) async throws -> ScoutingReport {
        let report = ScoutingReport(
            id: nil,
            userId: user.id ?? "",
            playerId: draft.playerId,
            playerName: draft.playerName,
            playerPosition: draft.playerPosition,
            playerTeam: draft.playerTeam,
            sport: draft.sport,
            strengths: draft.strengths,
            weaknesses: draft.weaknesses,
            comparison: draft.comparison,
            rating: draft.rating,
            positionRank: draft.positionRank,
            upvotes: 0,
            downvotes: 0,
            createdAt: Date(),
            username: user.username,
            userReputation: user.reputationScore,
            userVotes: [:]
        )

        let id = try await firestore.create(report, in: Constants.Firestore.reportsCollection)

        // Update user's report count and reputation
        try await firestore.incrementField("reports_count", by: 1,
            in: Constants.Firestore.usersCollection, id: user.id ?? "")
        try await firestore.incrementField("reputation_score", by: Int(Constants.Reputation.reportSubmittedPoints),
            in: Constants.Firestore.usersCollection, id: user.id ?? "")

        // Update consensus rankings
        try await RankingService.shared.updateConsensusRankings(for: draft.playerId)

        var submitted = report
        submitted.id = id
        return submitted
    }

    func voteOnReport(_ reportId: String, vote: VoteType, userId: String) async throws {
        let db = FirestoreService.shared.db
        let reportRef = db.collection(Constants.Firestore.reportsCollection).document(reportId)

        _ = try await db.runTransaction { transaction, errorPointer in
            let reportDoc: DocumentSnapshot
            do {
                reportDoc = try transaction.getDocument(reportRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard var votes = reportDoc.data()?["user_votes"] as? [String: String] else {
                return nil
            }

            let currentVote = votes[userId].flatMap { VoteType(rawValue: $0) }

            if currentVote == vote {
                // Remove vote
                votes.removeValue(forKey: userId)
                let field = vote == .up ? "upvotes" : "downvotes"
                transaction.updateData([
                    "user_votes": votes,
                    field: FieldValue.increment(Int64(-1))
                ], forDocument: reportRef)
            } else {
                // Add/change vote
                if let current = currentVote {
                    let removeField = current == .up ? "upvotes" : "downvotes"
                    let addField = vote == .up ? "upvotes" : "downvotes"
                    votes[userId] = vote.rawValue
                    transaction.updateData([
                        "user_votes": votes,
                        removeField: FieldValue.increment(Int64(-1)),
                        addField: FieldValue.increment(Int64(1))
                    ], forDocument: reportRef)
                } else {
                    let addField = vote == .up ? "upvotes" : "downvotes"
                    votes[userId] = vote.rawValue
                    transaction.updateData([
                        "user_votes": votes,
                        addField: FieldValue.increment(Int64(1))
                    ], forDocument: reportRef)
                }
            }

            return nil
        }
    }
}

// MARK: - Firestore Helper for Dictionary
extension FirestoreService {
    func update(_ data: [String: Any], in collection: String, id: String) async throws {
        try await db.collection(collection).document(id).updateData(data)
    }
}
