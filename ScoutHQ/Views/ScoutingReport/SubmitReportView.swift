import SwiftUI

struct SubmitReportView: View {
    @StateObject private var viewModel = ScoutingReportViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var showDiscardAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.scoutBackground.ignoresSafeArea()

                if viewModel.showSuccess {
                    SuccessView(report: viewModel.submittedReport) {
                        viewModel.resetDraft()
                    }
                } else {
                    VStack(spacing: 0) {
                        // Progress Steps
                        StepProgressBar(
                            steps: ScoutingReportViewModel.ReportStep.allCases.map(\.title),
                            currentStep: viewModel.currentStep.rawValue
                        )
                        .padding(.horizontal, ScoutSpacing.lg)
                        .padding(.vertical, ScoutSpacing.md)

                        ScoutDivider()

                        // Step Content
                        ScrollView(showsIndicators: false) {
                            stepContent
                                .padding(ScoutSpacing.lg)
                                .padding(.bottom, 120)
                        }
                    }

                    // Bottom Navigation
                    VStack {
                        Spacer()
                        bottomNavigation
                    }
                }
            }
            .navigationTitle("Submit Scout Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.currentStep != .selectPlayer {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            viewModel.previousStep()
                        }
                        .foregroundColor(.scoutAccent)
                    }
                }
                if viewModel.draft.playerId.isEmpty == false {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Discard") {
                            showDiscardAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Discard Report?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) {
                    viewModel.resetDraft()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Are you sure you want to discard your scouting report?")
            }
            .sheet(isPresented: $viewModel.showPlayerSearch) {
                PlayerSearchSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .selectPlayer:
            SelectPlayerStep(viewModel: viewModel)
        case .details:
            ReportDetailsStep(viewModel: viewModel)
        case .rating:
            RatingStep(viewModel: viewModel)
        case .review:
            ReviewStep(viewModel: viewModel)
        }
    }

    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        VStack(spacing: ScoutSpacing.sm) {
            if viewModel.currentStep == .review {
                // Submit button
                Button {
                    guard let user = authService.currentUser else { return }
                    Task { await viewModel.submitReport(user: user) }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        }
                        Text(viewModel.isLoading ? "Submitting..." : "Submit Report")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(isLoading: viewModel.isLoading))
                .disabled(viewModel.isLoading || !viewModel.draft.isValid)
                .padding(.horizontal, ScoutSpacing.lg)
            } else {
                Button {
                    viewModel.nextStep()
                } label: {
                    HStack(spacing: 6) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.canProceed)
                .padding(.horizontal, ScoutSpacing.lg)
            }
        }
        .padding(.vertical, ScoutSpacing.md)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(Color.scoutBackground.opacity(0.95))
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Step Progress Bar
struct StepProgressBar: View {
    let steps: [String]
    let currentStep: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                HStack(spacing: 0) {
                    // Step Circle
                    ZStack {
                        Circle()
                            .fill(stepColor(index: index))
                            .frame(width: 28, height: 28)
                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(ScoutFont.caption)
                                .fontWeight(.bold)
                                .foregroundColor(index == currentStep ? .white : .secondary)
                        }
                    }

                    // Connector line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.scoutAccent : Color.white.opacity(0.15))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }

                if index == steps.count - 1 {
                    // Labels below on mobile
                }
            }
        }
    }

    private func stepColor(index: Int) -> Color {
        if index < currentStep { return .scoutAccent }
        if index == currentStep { return .scoutAccent }
        return Color.white.opacity(0.12)
    }
}

// MARK: - Step 1: Select Player
struct SelectPlayerStep: View {
    @ObservedObject var viewModel: ScoutingReportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.xl) {
            VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
                Text("Select a Player")
                    .font(ScoutFont.title2)
                    .fontWeight(.black)
                Text("Search for the player you want to scout.")
                    .font(ScoutFont.subheadline)
                    .foregroundColor(.secondary)
            }

            // Search Bar
            Button {
                viewModel.showPlayerSearch = true
            } label: {
                HStack(spacing: ScoutSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    Text(viewModel.draft.playerName.isEmpty ? "Search players..." : viewModel.draft.playerName)
                        .foregroundColor(viewModel.draft.playerName.isEmpty ? .secondary : .primary)
                        .fontWeight(viewModel.draft.playerName.isEmpty ? .regular : .semibold)
                    Spacer()
                    if !viewModel.draft.playerId.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding(ScoutSpacing.md)
                .background(Color.scoutSurface)
                .cornerRadius(ScoutRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: ScoutRadius.md)
                        .stroke(viewModel.draft.playerId.isEmpty ? Color.white.opacity(0.1) : Color.green.opacity(0.5), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            // Selected Player Preview
            if !viewModel.draft.playerId.isEmpty {
                selectedPlayerPreview
            }

            // Quick Sport Shortcuts
            VStack(alignment: .leading, spacing: ScoutSpacing.md) {
                Text("Browse by Sport")
                    .font(ScoutFont.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                HStack(spacing: ScoutSpacing.md) {
                    ForEach(Sport.allCases) { sport in
                        Button {
                            viewModel.showPlayerSearch = true
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: sport.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(sportColor(for: sport))
                                Text(sport.rawValue)
                                    .font(ScoutFont.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ScoutSpacing.md)
                            .background(sportColor(for: sport).opacity(0.1))
                            .cornerRadius(ScoutRadius.md)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var selectedPlayerPreview: some View {
        HStack(spacing: ScoutSpacing.md) {
            ZStack {
                Circle()
                    .fill(sportColor(for: viewModel.draft.sport).opacity(0.15))
                    .frame(width: 48, height: 48)
                Text(String(viewModel.draft.playerName.prefix(2)).uppercased())
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(sportColor(for: viewModel.draft.sport))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.draft.playerName)
                    .font(ScoutFont.headline)
                    .fontWeight(.bold)
                HStack(spacing: 6) {
                    Text(viewModel.draft.playerPosition)
                        .font(ScoutFont.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(viewModel.draft.playerTeam)
                        .font(ScoutFont.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button {
                viewModel.draft = ReportDraft()
                viewModel.searchText = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(ScoutSpacing.md)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ScoutRadius.md)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Step 2: Report Details
struct ReportDetailsStep: View {
    @ObservedObject var viewModel: ScoutingReportViewModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case strengths, weaknesses, comparison }

    var body: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.xl) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scout Report")
                    .font(ScoutFont.title2)
                    .fontWeight(.black)
                Text("Share your evaluation of \(viewModel.draft.playerName)")
                    .font(ScoutFont.subheadline)
                    .foregroundColor(.secondary)
            }

            // Strengths
            formField(
                title: "Strengths",
                subtitle: "What does this player do well?",
                icon: "plus.circle.fill",
                iconColor: .green,
                text: $viewModel.draft.strengths,
                placeholder: "Describe the player's key strengths, skills, and standout attributes...",
                minLength: Constants.Limits.minStrengthsLength,
                focus: .strengths
            )

            // Weaknesses
            formField(
                title: "Weaknesses",
                subtitle: "What areas need improvement?",
                icon: "minus.circle.fill",
                iconColor: .red,
                text: $viewModel.draft.weaknesses,
                placeholder: "Describe areas where the player can improve or limitations in their game...",
                minLength: Constants.Limits.minWeaknessesLength,
                focus: .weaknesses
            )

            // Comparison
            VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.purple)
                    Text("Player Comparison")
                        .font(ScoutFont.headline)
                        .fontWeight(.bold)
                    Text("*")
                        .foregroundColor(.red)
                }
                Text("Which current or former player plays most similarly?")
                    .font(ScoutFont.caption)
                    .foregroundColor(.secondary)

                TextField("e.g. Patrick Mahomes, LeBron James...", text: $viewModel.draft.comparison)
                    .padding(ScoutSpacing.md)
                    .background(Color.scoutSurface)
                    .cornerRadius(ScoutRadius.sm)
                    .focused($focusedField, equals: .comparison)
            }
        }
        .focused($focusedField, equals: .strengths)
    }

    @ViewBuilder
    private func formField(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        text: Binding<String>,
        placeholder: String,
        minLength: Int,
        focus: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(ScoutFont.headline)
                    .fontWeight(.bold)
                Text("*")
                    .foregroundColor(.red)
                Spacer()
                Text("\(text.wrappedValue.count)/\(Constants.Limits.maxReportLength)")
                    .font(ScoutFont.caption2)
                    .foregroundColor(text.wrappedValue.count < minLength ? .orange : .secondary)
            }
            Text(subtitle)
                .font(ScoutFont.caption)
                .foregroundColor(.secondary)

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(ScoutFont.callout)
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.top, 12)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: text.max(Constants.Limits.maxReportLength))
                    .font(ScoutFont.callout)
                    .frame(minHeight: 120)
                    .focused($focusedField, equals: focus)
                    .scrollContentBackground(.hidden)
            }
            .padding(ScoutSpacing.sm)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: ScoutRadius.sm)
                    .stroke(
                        text.wrappedValue.count > 0 && text.wrappedValue.count < minLength
                        ? Color.orange.opacity(0.5) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )

            if text.wrappedValue.count > 0 && text.wrappedValue.count < minLength {
                Text("Minimum \(minLength) characters required (\(minLength - text.wrappedValue.count) more)")
                    .font(ScoutFont.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Step 3: Rating
struct RatingStep: View {
    @ObservedObject var viewModel: ScoutingReportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.xxl) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Rate the Player")
                    .font(ScoutFont.title2)
                    .fontWeight(.black)
                Text("Give your overall and position ratings")
                    .font(ScoutFont.subheadline)
                    .foregroundColor(.secondary)
            }

            // Overall Rating
            VStack(alignment: .leading, spacing: ScoutSpacing.md) {
                Text("Overall Rating")
                    .font(ScoutFont.headline)
                    .fontWeight(.bold)
                Text("Rate the player's overall ability and potential (1–100)")
                    .font(ScoutFont.caption)
                    .foregroundColor(.secondary)

                RatingSlider(value: $viewModel.draft.rating, label: "Overall")
                    .padding(ScoutSpacing.lg)
                    .background(Color.scoutSurface)
                    .cornerRadius(ScoutRadius.md)
            }

            // Position Rank
            VStack(alignment: .leading, spacing: ScoutSpacing.md) {
                Text("Position Rank")
                    .font(ScoutFont.headline)
                    .fontWeight(.bold)
                Text("Where does this player rank among all \(viewModel.draft.playerPosition)s?")
                    .font(ScoutFont.caption)
                    .foregroundColor(.secondary)

                VStack(spacing: ScoutSpacing.md) {
                    HStack {
                        Text("Rank")
                            .font(ScoutFont.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("#\(viewModel.draft.positionRank)")
                            .font(ScoutFont.statNumber)
                            .fontWeight(.black)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.draft.positionRank) },
                            set: { viewModel.draft.positionRank = Int($0) }
                        ),
                        in: 1...100,
                        step: 1
                    )
                    .tint(.scoutAccent)
                    HStack {
                        Text("#1 Best")
                            .font(ScoutFont.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("#100 Worst")
                            .font(ScoutFont.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(ScoutSpacing.lg)
                .background(Color.scoutSurface)
                .cornerRadius(ScoutRadius.md)
            }

            // Quick rating reference
            ratingReferenceCard
        }
    }

    private var ratingReferenceCard: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
            Text("Rating Guide")
                .font(ScoutFont.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            VStack(spacing: 6) {
                ForEach([("90-100", "Elite / Franchise Player", "A+"), ("80-89", "Pro Bowl / All-Star Level", "A"), ("70-79", "Solid Starter", "B"), ("60-69", "Backup / Role Player", "C")], id: \.0) { range, label, grade in
                    HStack(spacing: 8) {
                        Text(range)
                            .font(ScoutFont.caption2)
                            .fontWeight(.bold)
                            .frame(width: 55, alignment: .leading)
                        Text(label)
                            .font(ScoutFont.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        GradeBadge(grade: grade)
                    }
                }
            }
            .padding(ScoutSpacing.md)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.sm)
        }
    }
}

// MARK: - Step 4: Review
struct ReviewStep: View {
    @ObservedObject var viewModel: ScoutingReportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.xl) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Review & Submit")
                    .font(ScoutFont.title2)
                    .fontWeight(.black)
                Text("Review your scouting report before submitting")
                    .font(ScoutFont.subheadline)
                    .foregroundColor(.secondary)
            }

            // Player card
            HStack(spacing: ScoutSpacing.md) {
                ZStack {
                    Circle()
                        .fill(sportColor(for: viewModel.draft.sport).opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text(String(viewModel.draft.playerName.prefix(2)).uppercased())
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(sportColor(for: viewModel.draft.sport))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.draft.playerName)
                        .font(ScoutFont.headline)
                        .fontWeight(.bold)
                    Text("\(viewModel.draft.playerPosition) • \(viewModel.draft.playerTeam)")
                        .font(ScoutFont.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                GradeBadge(grade: ratingGrade, large: true)
            }
            .padding(ScoutSpacing.md)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.md)

            // Report Summary
            VStack(spacing: ScoutSpacing.md) {
                reviewRow(title: "Strengths", content: viewModel.draft.strengths, color: .green)
                ScoutDivider()
                reviewRow(title: "Weaknesses", content: viewModel.draft.weaknesses, color: .red)
                ScoutDivider()
                reviewRow(title: "Comparison", content: viewModel.draft.comparison, color: .purple)
            }
            .padding(ScoutSpacing.md)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.md)

            // Rating summary
            HStack(spacing: ScoutSpacing.xl) {
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", viewModel.draft.rating))
                        .font(ScoutFont.rating)
                        .fontWeight(.black)
                    Text("Overall Rating")
                        .font(ScoutFont.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 50)

                VStack(spacing: 4) {
                    Text("#\(viewModel.draft.positionRank)")
                        .font(ScoutFont.rating)
                        .fontWeight(.black)
                    Text("Position Rank")
                        .font(ScoutFont.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(ScoutSpacing.lg)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.md)

            // Disclaimer
            Text("By submitting, you confirm this is your honest evaluation. Reports with inappropriate content will be removed.")
                .font(ScoutFont.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var ratingGrade: String {
        switch viewModel.draft.rating {
        case 90...100: return "A+"
        case 85..<90: return "A"
        case 80..<85: return "A-"
        case 75..<80: return "B+"
        case 70..<75: return "B"
        default: return "B-"
        }
    }

    private func reviewRow(title: String, content: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ScoutFont.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(content)
                .font(ScoutFont.callout)
                .foregroundColor(.primary)
                .lineLimit(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Success View
struct SuccessView: View {
    let report: ScoutingReport?
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: ScoutSpacing.xxl) {
            Spacer()

            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, value: true)
            }

            VStack(spacing: ScoutSpacing.sm) {
                Text("Report Submitted!")
                    .font(ScoutFont.title2)
                    .fontWeight(.black)
                Text("Your scouting report has been submitted and will contribute to the consensus ranking.")
                    .font(ScoutFont.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let report = report {
                VStack(spacing: ScoutSpacing.sm) {
                    Text("+\(Int(Constants.Reputation.reportSubmittedPoints)) Reputation Points")
                        .font(ScoutFont.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.scoutGold)
                    Text("for \(report.playerName)")
                        .font(ScoutFont.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(ScoutSpacing.md)
                .background(Color.scoutGold.opacity(0.1))
                .cornerRadius(ScoutRadius.sm)
            }

            Spacer()

            Button("Submit Another Report", action: onDone)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, ScoutSpacing.lg)

            Button("Back to Home") { onDone() }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, ScoutSpacing.lg)
                .padding(.bottom, 40)
        }
        .padding(ScoutSpacing.lg)
    }
}

// MARK: - Player Search Sheet
struct PlayerSearchSheet: View {
    @ObservedObject var viewModel: ScoutingReportViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.scoutBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    ScoutSearchBar(text: $viewModel.searchText, placeholder: "Search players by name, team, position...")
                        .padding(ScoutSpacing.lg)
                        .onChange(of: viewModel.searchText) { _, query in
                            viewModel.searchPlayers(query)
                        }

                    ScoutDivider()

                    // Results
                    if viewModel.isSearching {
                        Spacer()
                        ProgressView("Searching...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .scoutAccent))
                        Spacer()
                    } else if viewModel.searchText.isEmpty {
                        // Show all players by default
                        playerList(viewModel.searchResults.isEmpty ? MockDataService.shared.mockPlayers() : viewModel.searchResults)
                    } else if viewModel.searchResults.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Players Found",
                            message: "Try searching by player name, team, or position."
                        )
                        Spacer()
                    } else {
                        playerList(viewModel.searchResults)
                    }
                }
            }
            .navigationTitle("Select Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
            .onAppear {
                viewModel.searchPlayers("")
                isSearchFocused = true
            }
        }
        .preferredColorScheme(.dark)
    }

    private func playerList(_ players: [Player]) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(players) { player in
                    Button {
                        viewModel.selectPlayer(player)
                        dismiss()
                    } label: {
                        HStack(spacing: ScoutSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(sportColor(for: player.sport).opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Text(String(player.name.prefix(2)).uppercased())
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(sportColor(for: player.sport))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(player.name)
                                    .font(ScoutFont.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                HStack(spacing: 6) {
                                    Text(player.position)
                                        .font(ScoutFont.caption)
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(player.team)
                                        .font(ScoutFont.caption)
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(player.league.rawValue)
                                        .font(ScoutFont.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            SportBadge(sport: player.sport)
                        }
                        .padding(.horizontal, ScoutSpacing.lg)
                        .padding(.vertical, ScoutSpacing.md)
                    }
                    .buttonStyle(.plain)

                    ScoutDivider()
                        .padding(.leading, ScoutSpacing.lg + 44 + ScoutSpacing.md)
                }
            }
        }
    }
}
