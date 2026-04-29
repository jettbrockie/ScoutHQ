import SwiftUI

// MARK: - Full Player Card
struct PlayerCard: View {
    let player: Player
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
            HapticFeedback.impact(.light)
        } label: {
            HStack(spacing: ScoutSpacing.md) {
                // Rank + Avatar
                VStack(spacing: 4) {
                    Text("#\(player.overallRank)")
                        .font(ScoutFont.rankNumber)
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                    RankChangeIndicator(change: player.rankChange)
                }
                .frame(width: 44)

                PlayerAvatar(player: player, size: 52)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(ScoutFont.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(player.position)
                            .font(ScoutFont.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(ScoutFont.caption)
                        Text(player.team)
                            .font(ScoutFont.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    SportBadge(sport: player.sport, showLabel: false)
                }

                Spacer()

                // Rating
                VStack(alignment: .trailing, spacing: 2) {
                    GradeBadge(grade: player.ratingGrade)
                    Text(player.consensusRating.ratingString)
                        .font(ScoutFont.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(ScoutSpacing.md)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Ranking Row
struct RankingRowView: View {
    let ranking: Ranking
    let onTap: () -> Void

    var body: some View {
        Button(action: { onTap(); HapticFeedback.impact(.light) }) {
            HStack(spacing: ScoutSpacing.md) {
                // Rank number
                Text("\(ranking.overallRank)")
                    .font(ScoutFont.rankNumber)
                    .fontWeight(.black)
                    .foregroundColor(rankColor)
                    .frame(width: 36)

                // Avatar placeholder
                ZStack {
                    Circle()
                        .fill(sportColor(for: ranking.sport).opacity(0.15))
                    Text(String(ranking.playerName.prefix(2)).uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(sportColor(for: ranking.sport))
                }
                .frame(width: 44, height: 44)

                // Player info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(ranking.playerName)
                            .font(ScoutFont.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        if ranking.isTrending {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        }
                    }
                    HStack(spacing: 6) {
                        Text(ranking.position)
                            .font(ScoutFont.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(ScoutFont.caption)
                            .foregroundColor(.secondary)
                        Text(ranking.team)
                            .font(ScoutFont.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Right side: grade + rank change
                VStack(alignment: .trailing, spacing: 4) {
                    GradeBadge(grade: ranking.gradeLabel)
                    RankChangeIndicator(change: ranking.rankChange)
                }
            }
            .padding(.horizontal, ScoutSpacing.lg)
            .padding(.vertical, ScoutSpacing.md)
        }
        .buttonStyle(.plain)
    }

    private var rankColor: Color {
        switch ranking.overallRank {
        case 1: return Color(red: 1.0, green: 0.82, blue: 0.2)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .primary
        }
    }
}

// MARK: - Trending Player Card
struct TrendingPlayerCard: View {
    let player: TrendingPlayer
    var width: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Avatar background
                ZStack {
                    RoundedRectangle(cornerRadius: ScoutRadius.md)
                        .fill(sportColor(for: player.sport).opacity(0.2))
                    Text(String(player.name.prefix(2)).uppercased())
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(sportColor(for: player.sport))
                }
                .frame(width: width, height: width * 0.75)

                // Rank change badge
                if player.rankChange != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: player.rankChange > 0 ? "triangle.fill" : "triangle.fill")
                            .font(.system(size: 8))
                            .rotationEffect(.degrees(player.rankChange > 0 ? 0 : 180))
                        Text("\(abs(player.rankChange))")
                            .font(ScoutFont.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(player.rankChange > 0 ? Color.green : Color.red)
                    .clipShape(Capsule())
                    .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(ScoutFont.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(player.position)
                        .font(ScoutFont.caption2)
                        .foregroundColor(.secondary)
                    Text("•")
                        .font(ScoutFont.caption2)
                        .foregroundColor(.secondary)
                    Text(player.team)
                        .font(ScoutFont.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.scoutAccent)
                    Text("\(player.recentReportCount) reports")
                        .font(ScoutFont.caption2)
                        .foregroundColor(.scoutAccent)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: width)
    }
}

// MARK: - Report Card
struct ReportCard: View {
    let report: ScoutingReport
    var currentUserId: String = ""
    var onVote: ((VoteType) -> Void)? = nil
    var compact = false

    var userVote: VoteType? {
        report.userVotes[currentUserId].flatMap { VoteType(rawValue: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            // Header
            HStack(spacing: ScoutSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.scoutAccent.opacity(0.15))
                    Text(String(report.username.prefix(1)).uppercased())
                        .font(ScoutFont.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.scoutAccent)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.username)
                        .font(ScoutFont.subheadline)
                        .fontWeight(.semibold)
                    ReputationBadge(tier: AppUser(
                        id: nil, username: report.username, email: "",
                        favoriteTeams: [], reputationScore: report.userReputation,
                        followersCount: 0, followingCount: 0, reportsCount: 0,
                        createdAt: Date(), isPremium: false,
                        accuracyScore: 0, totalVotesReceived: 0
                    ).reputationTier, score: report.userReputation)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    GradeBadge(grade: report.ratingGrade)
                    Text(report.formattedDate)
                        .font(ScoutFont.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if !compact {
                // Strengths
                VStack(alignment: .leading, spacing: 4) {
                    Label("Strengths", systemImage: "plus.circle.fill")
                        .font(ScoutFont.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text(report.strengths)
                        .font(ScoutFont.callout)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }

                // Weaknesses
                VStack(alignment: .leading, spacing: 4) {
                    Label("Weaknesses", systemImage: "minus.circle.fill")
                        .font(ScoutFont.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    Text(report.weaknesses)
                        .font(ScoutFont.callout)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }

                // Comparison
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Comp: ")
                        .font(ScoutFont.caption)
                        .foregroundColor(.secondary)
                    Text(report.comparison)
                        .font(ScoutFont.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.scoutAccent)
                }
            }

            // Footer: votes
            HStack(spacing: ScoutSpacing.lg) {
                // Upvote
                Button {
                    onVote?(.up)
                    HapticFeedback.impact(.light)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: userVote == .up ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 14))
                        Text("\(report.upvotes)")
                            .font(ScoutFont.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(userVote == .up ? .scoutAccent : .secondary)
                }
                .buttonStyle(.plain)

                // Downvote
                Button {
                    onVote?(.down)
                    HapticFeedback.impact(.light)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: userVote == .down ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 14))
                        Text("\(report.downvotes)")
                            .font(ScoutFont.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(userVote == .down ? .red : .secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.scoutGold)
                    Text(report.rating.ratingString)
                        .font(ScoutFont.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(ScoutSpacing.lg)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.lg)
    }
}
