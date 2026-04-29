import SwiftUI

struct PlayerProfileView: View {
    let playerId: String
    let playerName: String

    @StateObject private var viewModel = PlayerViewModel()
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: PlayerTab = .overview

    enum PlayerTab: String, CaseIterable {
        case overview = "Overview"
        case aiReport = "AI Scout"
        case reports = "Reports"

        var icon: String {
            switch self {
            case .overview: return "person.fill"
            case .aiReport: return "sparkles"
            case .reports: return "doc.text.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.scoutBackground.ignoresSafeArea()

            if viewModel.isLoadingPlayer {
                LoadingView(message: "Loading player...")
            } else if let player = viewModel.player {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Header
                        playerHeroHeader(player: player)

                        // Tab Picker
                        playerTabBar
                            .padding(.vertical, ScoutSpacing.md)

                        // Tab Content
                        tabContent(player: player)
                            .padding(.bottom, 100)
                    }
                }
            } else {
                ErrorView(message: "Failed to load player.") {
                    Task { await viewModel.loadAll(playerId: playerId) }
                }
            }
        }
        .navigationTitle(playerName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAll(playerId: playerId)
        }
    }

    // MARK: - Hero Header
    private func playerHeroHeader(player: Player) -> some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            sportGradient(for: player.sport)
                .frame(height: 220)

            VStack(spacing: 0) {
                Spacer()

                HStack(alignment: .bottom, spacing: ScoutSpacing.lg) {
                    // Large Avatar
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 88, height: 88)
                        Text(String(player.name.prefix(2)).uppercased())
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(ScoutFont.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        HStack(spacing: 8) {
                            Text(player.position)
                                .font(ScoutFont.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.85))
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Text(player.team)
                                .font(ScoutFont.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        HStack(spacing: 6) {
                            SportBadge(sport: player.sport, showLabel: true)
                            if player.isProspect {
                                Text("PROSPECT")
                                    .font(ScoutFont.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Spacer()

                    // Rating Circle
                    VStack(spacing: 2) {
                        RatingCircle(rating: viewModel.averageRating, size: 64, lineWidth: 5)
                        Text("#\(player.overallRank) Overall")
                            .font(ScoutFont.caption2)
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .padding(ScoutSpacing.lg)
                .padding(.top, 40)
            }
        }
    }

    // MARK: - Tab Bar
    private var playerTabBar: some View {
        HStack(spacing: 0) {
            ForEach(PlayerTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.scoutSpring) {
                        selectedTab = tab
                    }
                    HapticFeedback.selection()
                } label: {
                    VStack(spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(tab.rawValue)
                                .font(ScoutFont.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(selectedTab == tab ? .scoutAccent : .secondary)

                        Rectangle()
                            .fill(selectedTab == tab ? Color.scoutAccent : .clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, ScoutSpacing.lg)
        .overlay(ScoutDivider(), alignment: .bottom)
    }

    // MARK: - Tab Content
    @ViewBuilder
    private func tabContent(player: Player) -> some View {
        switch selectedTab {
        case .overview:
            PlayerOverviewTab(player: player, viewModel: viewModel)
        case .aiReport:
            AIScoutingReportView(viewModel: viewModel, player: player)
        case .reports:
            UserReportsListView(
                viewModel: viewModel,
                currentUserId: authService.currentUser?.id ?? ""
            )
        }
    }
}

// MARK: - Player Overview Tab
struct PlayerOverviewTab: View {
    let player: Player
    let viewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: ScoutSpacing.xl) {
            // Quick Stats
            quickStatsGrid(player: player)
                .padding(.horizontal, ScoutSpacing.lg)

            // Biographical Info
            if player.height != nil || player.age > 0 {
                bioSection(player: player)
                    .padding(.horizontal, ScoutSpacing.lg)
            }

            // Performance Stats
            performanceStats(player: player)
                .padding(.horizontal, ScoutSpacing.lg)

            // Consensus Summary
            consensusSummary
                .padding(.horizontal, ScoutSpacing.lg)

            // Rating Distribution
            if !viewModel.reports.isEmpty {
                VStack(alignment: .leading, spacing: ScoutSpacing.md) {
                    Text("Community Ratings")
                        .font(ScoutFont.headline)
                        .fontWeight(.bold)
                    RatingDistributionChart(distribution: viewModel.ratingDistribution)
                }
                .padding(ScoutSpacing.lg)
                .background(Color.scoutSurface)
                .cornerRadius(ScoutRadius.lg)
                .padding(.horizontal, ScoutSpacing.lg)
            }
        }
        .padding(.top, ScoutSpacing.lg)
    }

    private func quickStatsGrid(player: Player) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: ScoutSpacing.md) {
            StatCard(title: "Rank", value: "#\(player.overallRank)", icon: "list.number", color: .scoutGold)
            StatCard(title: "Pos Rank", value: "#\(player.positionRank)", icon: "person.fill", color: .scoutAccent)
            StatCard(title: "Reports", value: "\(player.reportCount)", icon: "doc.text.fill", color: .green)
        }
    }

    private func bioSection(player: Player) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            Text("Player Info")
                .font(ScoutFont.headline)
                .fontWeight(.bold)
            VStack(spacing: 0) {
                if player.age > 0 {
                    StatRow(label: "Age", value: "\(player.age)")
                    ScoutDivider()
                }
                if let height = player.height {
                    StatRow(label: "Height", value: height)
                    ScoutDivider()
                }
                if let weight = player.weight {
                    StatRow(label: "Weight", value: weight)
                    ScoutDivider()
                }
                StatRow(label: "League", value: player.league.rawValue)
                if let draftYear = player.draftYear {
                    ScoutDivider()
                    StatRow(label: "Draft Year", value: "\(draftYear)", highlight: true)
                }
            }
            .padding(ScoutSpacing.md)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.md)
        }
    }

    private func performanceStats(player: Player) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            Text("Performance Stats")
                .font(ScoutFont.headline)
                .fontWeight(.bold)
            VStack(spacing: 0) {
                ForEach(Array(player.stats.sorted(by: { $0.key < $1.key }).enumerated()), id: \.element.key) { index, stat in
                    StatRow(label: stat.key, value: stat.value)
                    if index < player.stats.count - 1 {
                        ScoutDivider()
                    }
                }
            }
            .padding(ScoutSpacing.md)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.md)
        }
    }

    private var consensusSummary: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            Text("Consensus Score")
                .font(ScoutFont.headline)
                .fontWeight(.bold)
            HStack(spacing: ScoutSpacing.xl) {
                RatingCircle(rating: player.consensusRating, size: 80)
                VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
                    HStack {
                        Text("Grade")
                            .font(ScoutFont.subheadline)
                            .foregroundColor(.secondary)
                        GradeBadge(grade: player.ratingGrade, large: true)
                    }
                    Label("\(player.reportCount) community reports", systemImage: "doc.text.fill")
                        .font(ScoutFont.caption)
                        .foregroundColor(.secondary)
                    if player.rankChange != 0 {
                        HStack(spacing: 4) {
                            RankChangeIndicator(change: player.rankChange)
                            Text("from last week")
                                .font(ScoutFont.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
            }
            .padding(ScoutSpacing.lg)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.md)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: ScoutSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(ScoutFont.statNumber)
                .fontWeight(.black)
                .foregroundColor(.primary)
            Text(title)
                .font(ScoutFont.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ScoutSpacing.md)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.md)
    }
}
