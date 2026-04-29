import SwiftUI

struct RankingsView: View {
    @StateObject private var viewModel = RankingsViewModel()
    @State private var showFilterSheet = false
    @State private var selectedRankingId: String?
    @State private var showPlayerProfile = false
    @State private var selectedPlayerId: String?
    @State private var selectedPlayerName: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.scoutBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView

                    // Sport Tabs
                    sportTabBar
                        .padding(.bottom, 4)

                    // League Filter
                    leagueFilterBar
                        .padding(.bottom, ScoutSpacing.sm)

                    // Position Filter
                    positionFilterBar
                        .padding(.bottom, ScoutSpacing.sm)

                    // Search
                    ScoutSearchBar(text: $viewModel.searchText)
                        .padding(.horizontal, ScoutSpacing.lg)
                        .padding(.bottom, ScoutSpacing.sm)

                    ScoutDivider()

                    // Rankings List
                    rankingsList
                }
            }
            .navigationDestination(isPresented: $showPlayerProfile) {
                if let id = selectedPlayerId, let name = selectedPlayerName {
                    PlayerProfileView(playerId: id, playerName: name)
                }
            }
        }
        .task {
            await viewModel.loadRankings()
        }
        .sheet(isPresented: $showFilterSheet) {
            RankingsFilterSheet(filter: $viewModel.filter) {
                Task { await viewModel.loadRankings() }
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rankings")
                    .font(ScoutFont.title)
                    .fontWeight(.black)
                Text("\(viewModel.filter.league.rawValue) • \(viewModel.displayRankings.count) players")
                    .font(ScoutFont.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                showFilterSheet = true
                HapticFeedback.impact(.light)
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, ScoutSpacing.lg)
        .padding(.vertical, ScoutSpacing.md)
    }

    // MARK: - Sport Tabs
    private var sportTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Sport.allCases) { sport in
                Button {
                    viewModel.selectSport(sport)
                    HapticFeedback.selection()
                } label: {
                    VStack(spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: sport.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(sport.rawValue)
                                .font(ScoutFont.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(viewModel.filter.sport == sport ? .primary : .secondary)

                        Rectangle()
                            .fill(viewModel.filter.sport == sport ? sportColor(for: sport) : .clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, ScoutSpacing.lg)
    }

    // MARK: - League Filter
    private var leagueFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ScoutSpacing.sm) {
                ForEach(viewModel.filter.sport.leagues) { league in
                    Button {
                        viewModel.selectLeague(league)
                        HapticFeedback.selection()
                    } label: {
                        Text(league.rawValue)
                            .font(ScoutFont.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(PillButtonStyle(
                        isSelected: viewModel.filter.league == league,
                        color: sportColor(for: viewModel.filter.sport)
                    ))
                }
            }
            .padding(.horizontal, ScoutSpacing.lg)
        }
    }

    // MARK: - Position Filter
    private var positionFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ScoutSpacing.sm) {
                ForEach(viewModel.filter.availablePositions, id: \.self) { position in
                    Button {
                        viewModel.selectPosition(position)
                        HapticFeedback.selection()
                    } label: {
                        Text(position)
                            .font(ScoutFont.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(PillButtonStyle(
                        isSelected: viewModel.filter.position == position,
                        color: .scoutAccent
                    ))
                }
            }
            .padding(.horizontal, ScoutSpacing.lg)
        }
    }

    // MARK: - Rankings List
    private var rankingsList: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading rankings...")
            } else if viewModel.displayRankings.isEmpty {
                EmptyStateView(
                    icon: "list.number",
                    title: "No Rankings Found",
                    message: "No players match your current filters."
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.displayRankings.enumerated()), id: \.element.id) { index, ranking in
                            RankingRowView(ranking: ranking) {
                                selectedPlayerId = ranking.playerId
                                selectedPlayerName = ranking.playerName
                                showPlayerProfile = true
                            }

                            if index < viewModel.displayRankings.count - 1 {
                                ScoutDivider()
                                    .padding(.leading, ScoutSpacing.lg + 44 + ScoutSpacing.md)
                            }
                        }

                        Spacer().frame(height: 100)
                    }
                }
                .refreshable {
                    await viewModel.loadRankings()
                }
            }
        }
    }
}

// MARK: - Rankings Filter Sheet
struct RankingsFilterSheet: View {
    @Binding var filter: RankingsFilter
    @Environment(\.dismiss) var dismiss
    var onApply: () -> Void

    @State private var localFilter: RankingsFilter

    init(filter: Binding<RankingsFilter>, onApply: @escaping () -> Void) {
        self._filter = filter
        self.onApply = onApply
        self._localFilter = State(initialValue: filter.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.scoutBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: ScoutSpacing.xxl) {
                        // Sport
                        filterSection(title: "Sport") {
                            HStack(spacing: ScoutSpacing.sm) {
                                ForEach(Sport.allCases) { sport in
                                    Button {
                                        localFilter.sport = sport
                                        localFilter.league = sport.proLeague
                                        localFilter.position = "All"
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: sport.icon)
                                            Text(sport.rawValue)
                                                .font(ScoutFont.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .buttonStyle(PillButtonStyle(
                                        isSelected: localFilter.sport == sport,
                                        color: sportColor(for: sport)
                                    ))
                                }
                            }
                        }

                        // League
                        filterSection(title: "League") {
                            FlowLayout(spacing: ScoutSpacing.sm) {
                                ForEach(localFilter.sport.leagues) { league in
                                    Button(league.rawValue) {
                                        localFilter.league = league
                                        localFilter.position = "All"
                                    }
                                    .buttonStyle(PillButtonStyle(
                                        isSelected: localFilter.league == league,
                                        color: .scoutAccent
                                    ))
                                }
                            }
                        }

                        // Position
                        filterSection(title: "Position") {
                            FlowLayout(spacing: ScoutSpacing.sm) {
                                ForEach(localFilter.availablePositions, id: \.self) { position in
                                    Button(position) {
                                        localFilter.position = position
                                    }
                                    .buttonStyle(PillButtonStyle(
                                        isSelected: localFilter.position == position,
                                        color: .scoutAccent
                                    ))
                                }
                            }
                        }
                    }
                    .padding(ScoutSpacing.lg)
                }
            }
            .navigationTitle("Filter Rankings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        localFilter = RankingsFilter()
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        filter = localFilter
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.scoutAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            Text(title)
                .font(ScoutFont.headline)
                .fontWeight(.bold)
            content()
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let result = layout(sizes: sizes, proposal: ProposedViewSize(bounds.size))
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (positions: [CGPoint], size: CGSize) {
        let width = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for size in sizes {
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxY = max(maxY, y + size.height)
        }

        return (positions, CGSize(width: width, height: maxY))
    }
}
