import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var showEditProfile = false
    @State private var showSignOutAlert = false
    @State private var selectedSportFilter: Sport? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.scoutBackground.ignoresSafeArea()

                if viewModel.isLoading {
                    LoadingView(message: "Loading profile...")
                } else if let user = authService.currentUser {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            profileHeader(user: user)
                            statsBar(user: user)
                                .padding(.bottom, ScoutSpacing.xl)
                            reputationSection(user: user)
                                .padding(.horizontal, ScoutSpacing.lg)
                                .padding(.bottom, ScoutSpacing.xl)
                            activitySection(user: user)
                                .padding(.bottom, ScoutSpacing.xl)
                            favoritesSection(user: user)
                                .padding(.bottom, ScoutSpacing.xl)
                            settingsSection
                                .padding(.horizontal, ScoutSpacing.lg)
                                .padding(.bottom, 100)
                        }
                    }
                    .refreshable {
                        await viewModel.loadProfile()
                    }
                } else {
                    ErrorView(message: "Unable to load your profile.") {
                        Task { await viewModel.loadProfile() }
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.scoutAccent)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }

    // MARK: - Profile Header
    private func profileHeader(user: AppUser) -> some View {
        ZStack(alignment: .bottom) {
            // Background
            LinearGradient(
                colors: [Color.scoutAccent.opacity(0.5), Color.scoutBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)

            VStack(spacing: ScoutSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(ScoutGradients.blueGradient)
                        .frame(width: 86, height: 86)
                        .scoutShadow()
                    Text(String(user.username.prefix(2)).uppercased())
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                // Name & Tier
                VStack(spacing: 6) {
                    Text(user.username)
                        .font(ScoutFont.title2)
                        .fontWeight(.black)
                    ReputationBadge(tier: user.reputationTier, score: user.reputationScore)
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(ScoutFont.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
            }
            .padding(.bottom, ScoutSpacing.xl)
        }
    }

    // MARK: - Stats Bar
    private func statsBar(user: AppUser) -> some View {
        HStack(spacing: 0) {
            profileStat(value: "\(user.reportsCount)", label: "Reports")
            Divider().frame(height: 40).background(Color.white.opacity(0.15))
            profileStat(value: "\(user.followersCount)", label: "Followers")
            Divider().frame(height: 40).background(Color.white.opacity(0.15))
            profileStat(value: "\(user.followingCount)", label: "Following")
            Divider().frame(height: 40).background(Color.white.opacity(0.15))
            profileStat(value: String(format: "%.0f", user.reputationScore), label: "REP", color: .scoutGold)
        }
        .padding(.vertical, ScoutSpacing.md)
        .background(Color.scoutSurface)
    }

    private func profileStat(value: String, label: String, color: Color = .primary) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(ScoutFont.statNumber)
                .fontWeight(.black)
                .foregroundColor(color)
            Text(label)
                .font(ScoutFont.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reputation Section
    private func reputationSection(user: AppUser) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            SectionHeader(title: "Reputation")

            VStack(spacing: ScoutSpacing.md) {
                // Tier Progress
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.reputationTier.rawValue)
                            .font(ScoutFont.headline)
                            .fontWeight(.bold)
                        Text("\(Int(user.reputationScore)) / \(nextTierThreshold(for: user.reputationTier)) REP")
                            .font(ScoutFont.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: user.reputationTier.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.scoutGold)
                }

                ScoutProgressBar(
                    value: reputationProgress(for: user),
                    color: .scoutGold
                )

                if user.reputationTier != .elite {
                    Text("\(Int(Double(nextTierThreshold(for: user.reputationTier)) - user.reputationScore)) points to next tier")
                        .font(ScoutFont.caption)
                        .foregroundColor(.secondary)
                }

                // Accuracy Score
                if viewModel.userReports.count >= 3 {
                    HStack {
                        Label("Accuracy Score", systemImage: "target")
                            .font(ScoutFont.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", viewModel.averageRating))
                            .font(ScoutFont.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.scoutAccent)
                    }
                }
            }
            .padding(ScoutSpacing.lg)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.lg)
        }
    }

    // MARK: - Activity Section
    private func activitySection(user: AppUser) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            SectionHeader(
                title: "Recent Reports",
                subtitle: "\(viewModel.userReports.count) total"
            )

            if viewModel.userReports.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Reports Yet",
                    message: "Submit your first scouting report to start building your reputation."
                )
                .padding(.horizontal, ScoutSpacing.lg)
            } else {
                // Sport filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ScoutSpacing.sm) {
                        Button {
                            selectedSportFilter = nil
                        } label: {
                            Text("All")
                        }
                        .buttonStyle(PillButtonStyle(isSelected: selectedSportFilter == nil))

                        ForEach(Sport.allCases) { sport in
                            Button {
                                selectedSportFilter = selectedSportFilter == sport ? nil : sport
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: sport.icon)
                                    Text(sport.rawValue)
                                }
                            }
                            .buttonStyle(PillButtonStyle(
                                isSelected: selectedSportFilter == sport,
                                color: sportColor(for: sport)
                            ))
                        }
                    }
                    .padding(.horizontal, ScoutSpacing.lg)
                }

                VStack(spacing: ScoutSpacing.md) {
                    ForEach(filteredReports.prefix(5)) { report in
                        userReportCard(report: report)
                            .padding(.horizontal, ScoutSpacing.lg)
                    }
                }
            }
        }
    }

    private var filteredReports: [ScoutingReport] {
        if let sport = selectedSportFilter {
            return viewModel.recentReports.filter { $0.sport == sport }
        }
        return viewModel.recentReports
    }

    private func userReportCard(report: ScoutingReport) -> some View {
        HStack(spacing: ScoutSpacing.md) {
            ZStack {
                Circle()
                    .fill(sportColor(for: report.sport).opacity(0.15))
                    .frame(width: 42, height: 42)
                Text(String(report.playerName.prefix(2)).uppercased())
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(sportColor(for: report.sport))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(report.playerName)
                    .font(ScoutFont.subheadline)
                    .fontWeight(.semibold)
                Text("\(report.playerPosition) • \(report.playerTeam)")
                    .font(ScoutFont.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: ScoutSpacing.sm) {
                    HStack(spacing: 3) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                        Text("\(report.upvotes)")
                            .font(ScoutFont.caption2)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                        Text("\(report.downvotes)")
                            .font(ScoutFont.caption2)
                    }
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(report.formattedDate)
                        .font(ScoutFont.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            GradeBadge(grade: report.ratingGrade)
        }
        .padding(ScoutSpacing.md)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.md)
    }

    // MARK: - Favorites Section
    private func favoritesSection(user: AppUser) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            SectionHeader(title: "Favorite Teams")
                .padding(.bottom, -4)

            if user.favoriteTeams.isEmpty {
                Text("No favorite teams added yet. Edit your profile to add them.")
                    .font(ScoutFont.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, ScoutSpacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ScoutSpacing.sm) {
                        ForEach(user.favoriteTeams, id: \.self) { team in
                            Text(team)
                                .font(ScoutFont.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.scoutAccent.opacity(0.15))
                                .foregroundColor(.scoutAccent)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, ScoutSpacing.lg)
                }
            }
        }
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: ScoutSpacing.sm) {
            settingsRow(icon: "bell.fill", title: "Notifications", color: .scoutAccent) {}
            settingsRow(icon: "lock.fill", title: "Privacy", color: .purple) {}
            settingsRow(icon: "star.fill", title: "Go Premium", color: .scoutGold) {}
            settingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .green) {}
            settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: .red) {
                showSignOutAlert = true
            }
        }
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.lg)
    }

    private func settingsRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: ScoutSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
                    .frame(width: 28)
                Text(title)
                    .font(ScoutFont.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(ScoutSpacing.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reputation Helpers
    private func nextTierThreshold(for tier: ReputationTier) -> Int {
        switch tier {
        case .rookie: return 100
        case .scout: return 500
        case .analyst: return 1500
        case .expert: return 5000
        case .elite: return 5000
        }
    }

    private func reputationProgress(for user: AppUser) -> Double {
        let current = user.reputationScore
        switch user.reputationTier {
        case .rookie: return current / 100
        case .scout: return (current - 100) / 400
        case .analyst: return (current - 500) / 1000
        case .expert: return (current - 1500) / 3500
        case .elite: return 1.0
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showTeamPicker = false
    @State private var selectedSport: Sport = .football

    var body: some View {
        NavigationStack {
            ZStack {
                Color.scoutBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ScoutSpacing.xl) {
                        // Avatar
                        VStack(spacing: ScoutSpacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(ScoutGradients.blueGradient)
                                    .frame(width: 80, height: 80)
                                Text(String(viewModel.editUsername.prefix(2)).uppercased())
                                    .font(.system(size: 26, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Button("Change Photo") {}
                                .font(ScoutFont.caption)
                                .foregroundColor(.scoutAccent)
                        }

                        // Username
                        formField(title: "Username", placeholder: "Username", text: $viewModel.editUsername)

                        // Bio
                        VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
                            Text("Bio")
                                .font(ScoutFont.subheadline)
                                .fontWeight(.semibold)
                            ZStack(alignment: .topLeading) {
                                if viewModel.editBio.isEmpty {
                                    Text("Tell the community about yourself...")
                                        .font(ScoutFont.callout)
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .padding(.top, 12)
                                        .padding(.leading, 4)
                                }
                                TextEditor(text: $viewModel.editBio.max(Constants.Limits.maxBioLength))
                                    .font(ScoutFont.callout)
                                    .frame(minHeight: 80)
                                    .scrollContentBackground(.hidden)
                            }
                            .padding(ScoutSpacing.sm)
                            .background(Color.scoutSurface)
                            .cornerRadius(ScoutRadius.sm)
                            Text("\(viewModel.editBio.count)/\(Constants.Limits.maxBioLength)")
                                .font(ScoutFont.caption2)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        // Favorite Teams
                        VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
                            Text("Favorite Teams")
                                .font(ScoutFont.subheadline)
                                .fontWeight(.semibold)

                            // Sport selector
                            HStack(spacing: ScoutSpacing.sm) {
                                ForEach(Sport.allCases) { sport in
                                    Button {
                                        selectedSport = sport
                                    } label: {
                                        Text(sport.rawValue)
                                    }
                                    .buttonStyle(PillButtonStyle(isSelected: selectedSport == sport, color: sportColor(for: sport)))
                                }
                            }

                            // Selected teams
                            if !viewModel.editFavoriteTeams.isEmpty {
                                FlowLayout(spacing: ScoutSpacing.sm) {
                                    ForEach(viewModel.editFavoriteTeams, id: \.self) { team in
                                        HStack(spacing: 4) {
                                            Text(team)
                                                .font(ScoutFont.caption)
                                                .fontWeight(.semibold)
                                            Button {
                                                viewModel.editFavoriteTeams.removeAll { $0 == team }
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 9, weight: .bold))
                                            }
                                        }
                                        .foregroundColor(.scoutAccent)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.scoutAccent.opacity(0.15))
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            // Team picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: ScoutSpacing.sm) {
                                    ForEach(viewModel.allSportTeams(for: selectedSport), id: \.self) { team in
                                        let isSelected = viewModel.editFavoriteTeams.contains(team)
                                        Button {
                                            if isSelected {
                                                viewModel.editFavoriteTeams.removeAll { $0 == team }
                                            } else if viewModel.editFavoriteTeams.count < 5 {
                                                viewModel.editFavoriteTeams.append(team)
                                            }
                                        } label: {
                                            Text(team)
                                        }
                                        .buttonStyle(PillButtonStyle(isSelected: isSelected, color: sportColor(for: selectedSport)))
                                        .disabled(!isSelected && viewModel.editFavoriteTeams.count >= 5)
                                    }
                                }
                                .padding(.vertical, 2)
                            }

                            Text("Select up to 5 favorite teams")
                                .font(ScoutFont.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(ScoutSpacing.lg)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.saveProfile()
                            dismiss()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .scoutAccent))
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(.scoutAccent)
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.startEditing()
        }
    }

    @ViewBuilder
    private func formField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
            Text(title)
                .font(ScoutFont.subheadline)
                .fontWeight(.semibold)
            TextField(placeholder, text: text)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .padding(ScoutSpacing.md)
                .background(Color.scoutSurface)
                .cornerRadius(ScoutRadius.sm)
        }
    }
}
