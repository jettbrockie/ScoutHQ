import Foundation

// MARK: - AI Scouting Report Generator using Claude API
final class AIService {
    static let shared = AIService()
    private init() {}

    private let session = URLSession.shared
    private let mock = MockDataService.shared

    // MARK: - Generate AI Scouting Report
    func generateScoutingReport(for player: Player, reports: [ScoutingReport]) async throws -> AIScoutReport {
        // Use mock if no API key or no reports
        guard !Constants.API.anthropicAPIKey.isEmpty, !reports.isEmpty else {
            return mock.mockAIReport(for: player)
        }

        let prompt = buildScoutingPrompt(player: player, reports: reports)
        let response = try await callClaudeAPI(prompt: prompt)
        return parseAIResponse(response, player: player, reports: reports)
    }

    // MARK: - Prompt Builder
    private func buildScoutingPrompt(player: Player, reports: [ScoutingReport]) -> String {
        let avgRating = reports.map(\.rating).reduce(0, +) / Double(reports.count)
        let allStrengths = reports.map(\.strengths).joined(separator: "\n")
        let allWeaknesses = reports.map(\.weaknesses).joined(separator: "\n")
        let comparisons = reports.compactMap { $0.comparison.isEmpty ? nil : $0.comparison }
        let mostCommonComparison = mostFrequent(comparisons) ?? "No comparison available"

        return """
        You are an expert sports analyst for ScoutHQ. Generate a concise, professional scouting report for the following player based on aggregated fan scouting data.

        PLAYER INFO:
        Name: \(player.name)
        Sport: \(player.sport.rawValue)
        Position: \(player.position)
        Team: \(player.team)
        Age: \(player.age)

        AGGREGATED USER SCOUTING DATA (\(reports.count) reports):

        STRENGTHS MENTIONED:
        \(allStrengths)

        WEAKNESSES MENTIONED:
        \(allWeaknesses)

        AVERAGE USER RATING: \(String(format: "%.1f", avgRating))/100
        MOST COMMON COMPARISON: \(mostCommonComparison)

        Generate a structured scouting report in the following JSON format:
        {
          "strengths": ["strength 1", "strength 2", "strength 3", "strength 4", "strength 5"],
          "weaknesses": ["weakness 1", "weakness 2", "weakness 3"],
          "comparison": "Player Name",
          "playstyle_summary": "2-3 sentence summary of playstyle",
          "key_attributes": {
            "attribute1": score,
            "attribute2": score
          }
        }

        Keep strengths and weaknesses as concise bullet points (max 10 words each).
        The playstyle_summary should be engaging and informative (2-3 sentences).
        Key attributes should be 5 relevant stats/traits rated 1-100.
        The comparison should be a single well-known current or historical \(player.sport.rawValue) player.

        Return ONLY the JSON object, no other text.
        """
    }

    // MARK: - Claude API Call
    private func callClaudeAPI(prompt: String) async throws -> String {
        guard let url = URL(string: Constants.API.anthropicBaseURL) else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Constants.API.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": Constants.API.claudeModel,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.apiError
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIError.parseError
        }

        return text
    }

    // MARK: - Response Parser
    private func parseAIResponse(_ response: String, player: Player, reports: [ScoutingReport]) -> AIScoutReport {
        let avgRating = reports.map(\.rating).reduce(0, +) / Double(reports.count)

        // Extract JSON from response
        guard let jsonData = extractJSON(from: response),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return mock.mockAIReport(for: player)
        }

        let strengths = (json["strengths"] as? [String]) ?? []
        let weaknesses = (json["weaknesses"] as? [String]) ?? []
        let comparison = (json["comparison"] as? String) ?? ""
        let playstyle = (json["playstyle_summary"] as? String) ?? ""
        let attributes = (json["key_attributes"] as? [String: Double]) ?? [:]

        return AIScoutReport(
            playerId: player.id ?? "",
            playerName: player.name,
            overallRating: avgRating,
            strengths: strengths,
            weaknesses: weaknesses,
            comparison: comparison,
            playstyleSummary: playstyle,
            keyAttributes: attributes,
            generatedAt: Date(),
            reportCount: reports.count
        )
    }

    private func extractJSON(from text: String) -> Data? {
        let pattern = #"\{[\s\S]*\}"#
        guard let range = text.range(of: pattern, options: .regularExpression),
              let data = String(text[range]).data(using: .utf8) else {
            return nil
        }
        return data
    }

    private func mostFrequent<T: Hashable>(_ array: [T]) -> T? {
        let counts = array.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Cache AI Report
    func cacheReport(_ report: AIScoutReport) async throws {
        let firestore = FirestoreService.shared
        try await firestore.create(report, in: Constants.Firestore.aiReportsCollection,
                                   id: report.playerId)
    }

    func fetchCachedReport(playerId: String) async -> AIScoutReport? {
        return try? await FirestoreService.shared.document(
            Constants.Firestore.aiReportsCollection,
            id: playerId
        )
    }
}

// MARK: - AI Errors
enum AIError: LocalizedError {
    case invalidURL
    case apiError
    case parseError
    case noReports

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .apiError: return "Failed to connect to AI service"
        case .parseError: return "Failed to parse AI response"
        case .noReports: return "No reports available to generate AI analysis"
        }
    }
}
