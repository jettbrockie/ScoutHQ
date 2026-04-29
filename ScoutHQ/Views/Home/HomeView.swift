import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var selectedPlayer: Player?
    @State private var showPlayerProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.scoutBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.trendingPlayers.isEmpty {
                    LoadingView(message: "Loading feed...")
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Header
                            headerView
                                .padding(.bottom, ScoutSpacing.xl)

                            // Sport Filter Pills
                            sportFilterRow
                                .padding(.bottom, ScoutSpacing.xl)

                            // Trending Section
                            trendingSection
                                .padding(.bottom, ScoutSpacing.xxxl)

                            // Rising / Falling
                            movementSection
                                .padding(.bottom, ScoutSpacing.xxxl)

                            // Featured Reports
                            featuredReportsSection
                                .padding(.bottom, ScoutSpacing.xxxl)

                            // Top Scouts Leaderboard
                            topScoutsSection
                                .padding(.bottom, 100) // tab bar space
                        }
                    }
                    .refreshable {
                        await viewModel.loadFeed()
                    }
                }
            }
            .navigationDestination(isPresented: $showPlayerProfile) {
                if let player = selectedPlayer {
                    PlayerProfileView(playerId: player.id ?? "", playerName: player.name)
                }
            }
        }
        .task {
            await viewModel.loadFeed()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(timeOfDayGreeting),")
                    .font(ScoutFont.subheadline)
                    .foregroundColor(.secondary)
                Text(authService.currentUser?.username ?? "Scout")
                    .font(ScoutFont.title)
                    .fontWeight(.black)
            }
            Spacer()
            // Notification bell
            Button {} label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 1, y: -1)
                }
            }
        }
        .padding(.horizontal, ScoutSpacing.lg)
        .padding(.top, ScoutSpacing.lg)
    }

    // MARK: - Sport Filter
    private var sportFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ScoutSpacing.sm) {
                ForEach(Sport.allCases) { sport in
                    Button {
                        withAnimation(.scoutSpring) {
                            viewModel.selectedSport = sport
                        }
                        HapticFeedback.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: sport.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(sport.rawValue)
                                .font(ScoutFont.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(viewModel.selectedSport == sport ? .white : .secondary)
                        .padding(.horizontal, ScoutSpacing.md)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedSport == sport
                            ? sportColor(for: sport)
                            : Color.white.opacity(0.07)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ScoutSpacing.lg)
        }
    }

    // MARK: - Trending
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.lg) {
            SectionHeader(
                title: "🔥 Trending Now",
                subtitle: "Most active in last 24h"
            )

            if viewModel.trendingBySelectedSport.isEmpty {
                Text("No trending players for \(viewModel.selectedSport.rawValue)")
                    .font(ScoutFont.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, ScoutSpacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ScoutSpacing.md) {
                        ForEach(viewModel.trendingBySelectedSport.prefix(6)) { player in
                            TrendingPlayerCard(player: player)
                                .onTapGesture {
                                    navigateToPlayer(id: player.playerId, name: player.name, sport: player.sport)
                                }
                        }
                    }
                    .padding(.horizontal, ScoutSpacing.lg)
                }
            }
        }
    }

    // MARK: - Movement Section
    private var movementSection: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.lg) {
            SectionHeader(title: "📈 Movers")

            HStack(alignment: .top, spacing: ScoutSpacing.md) {
                // Rising
                VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
                    Label("Rising", systemImage: "arrow.up.right")
                        .font(ScoutFont.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.leading, ScoutSpacing.lg)

                    ForEach(viewModel.risingPlayers.prefix(3)) { player in
                        MovementRow(player: player, isRising: true)
                            .onTapGesture {
                                navigateToPlayer(id: player.playerId, name: player.name, sport: player.sport)
                            }
                    }
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)

                // Falling
                VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
                    Label("Falling", systemImage: "arrow.down.right")
                        .font(ScoutFont.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.leading, ScoutSpacing.sm)

                    ForEach(viewModel.fallingPlayers.prefix(3)) { player in
                        MovementRow(player: player, isRising: false)
                            .onTapGesture {
                                navigateToPlayer(id: player.playerId, name: player.name, sport: player.sport)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, ScoutSpacing.lg)
        }
    }

    // MARK: - Featured Reports
    private var featuredReportsSection: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.lg) {
            SectionHeader(title: "⭐ Featured Reports")

            VStack(spacing: ScoutSpacing.md) {
                ForEach(viewModel.featuredReports.prefix(3)) { report in
                    ReportCard(report: report, compact: true)
                        .padding(.horizontal, ScoutSpacing.lg)
                }
            }
        }
    }

    // MARK: - Top Scouts
    private var topScoutsSection: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.lg) {
            SectionHeader(title: "🏆 Top Scouts")

            VStack(spacing: 0) {
                ForEach(viewModel.topScouts.prefix(5)) { scout in
                    TopScoutRow(scout: scout)
                    if scout.rank < 5 {
                        ScoutDivider()
                            .padding(.leading, ScoutSpacing.lg + 40)
                    }
                }
            }
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.lg)
            .padding(.horizontal, ScoutSpacing.lg)
        }
    }

    // MARK: - Helpers
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }

    private func navigateToPlayer(id: String, name: String, sport: Sport) {
        let players = MockDataService.shared.mockPlayers()
        selectedPlayer = players.first(where: { $0.id == id })
        if selectedPlayer == nil {
            selectedPlayer = Player(
                id: id, name: name, sport: sport, position: "", team: "",
                age: 0, league: .nfl, stats: [:], consensusRating: 0,
                overallRank: 0, positionRank: 0, previousOverallRank: 0,
                isProspect: false, isTrending: false, reportCount: 0, createdAt: Date()
            )
        }
        showPlayerProfile = true
    }
}

// MARK: - Movement Row
struct MovementRow: View {
    let player: TrendingPlayer
    let isRising: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(String(player.name.prefix(2)).uppercased())
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(isRising ? .green : .red)
                .frame(width: 28, height: 28)
                .background(isRising ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(player.name)
                    .font(ScoutFont.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(player.position)
                    .font(ScoutFont.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 2) {
                Image(systemName: isRising ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))
                Text("\(abs(player.rankChange))")
                    .font(ScoutFont.caption2)
                    .fontWeight(.bold)
            }
            .foregroundColor(isRising ? .green : .red)
        }
        .padding(.horizontal, isRising ? ScoutSpacing.lg : ScoutSpacing.sm)
        .contentShape(Rectangle())
    }
}

// MARK: - Top Scout Row
struct TopScoutRow: View {
    let scout: TopScout

    var body: some View {
        HStack(spacing: ScoutSpacing.md) {
            // Rank
            Text("#\(scout.rank)")
                .font(ScoutFont.rankNumber)
                .fontWeight(.black)
                .foregroundColor(rankColor)
                .frame(width: 32)

            // Avatar
            ZStack {
                Circle()
                    .fill(Color.scoutAccent.opacity(0.15))
                Text(String(scout.username.prefix(1)).uppercased())
                    .font(ScoutFont.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.scoutAccent)
            }
            .frame(width: 40, height: 40)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(scout.username)
                    .font(ScoutFont.subheadline)
                    .fontWeight(.semibold)
                ReputationBadge(tier: scout.tier, score: scout.reputationScore)
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f", scout.reputationScore))
                    .font(ScoutFont.headline)
                    .fontWeight(.black)
                    .foregroundColor(.scoutGold)
                Text("REP")
                    .font(ScoutFont.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, ScoutSpacing.lg)
        .padding(.vertical, ScoutSpacing.md)
        .contentShape(Rectangle())
    }

    private var rankColor: Color {
        switch scout.rank {
        case 1: return .scoutGold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .secondary
        }
    }
}
