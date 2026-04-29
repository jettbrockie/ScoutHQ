import SwiftUI

// MARK: - Loading View
struct LoadingView: View {
    var message = "Loading..."

    var body: some View {
        VStack(spacing: ScoutSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .scoutAccent))
                .scaleEffect(1.2)
            Text(message)
                .font(ScoutFont.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retry: (() -> Void)?

    var body: some View {
        VStack(spacing: ScoutSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.scoutGold)
            Text("Something went wrong")
                .font(ScoutFont.headline)
                .foregroundColor(.primary)
            Text(message)
                .font(ScoutFont.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            if let retry = retry {
                Button("Try Again", action: retry)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(ScoutSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sport Badge
struct SportBadge: View {
    let sport: Sport
    var showLabel = false
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: sport.icon)
                .font(.system(size: size * 0.55, weight: .semibold))
            if showLabel {
                Text(sport.rawValue)
                    .font(ScoutFont.caption)
                    .fontWeight(.semibold)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, showLabel ? 10 : 8)
        .padding(.vertical, showLabel ? 5 : 6)
        .background(sportColor(for: sport))
        .clipShape(Capsule())
    }
}

// MARK: - Rank Change Indicator
struct RankChangeIndicator: View {
    let change: Int
    var compact = false

    var body: some View {
        HStack(spacing: 2) {
            if change > 0 {
                Image(systemName: "triangle.fill")
                    .font(.system(size: compact ? 8 : 10))
                    .foregroundColor(.rankUp)
                if !compact {
                    Text("\(change)")
                        .font(ScoutFont.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.rankUp)
                }
            } else if change < 0 {
                Image(systemName: "triangle.fill")
                    .font(.system(size: compact ? 8 : 10))
                    .rotationEffect(.degrees(180))
                    .foregroundColor(.rankDown)
                if !compact {
                    Text("\(abs(change))")
                        .font(ScoutFont.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.rankDown)
                }
            } else {
                Text("—")
                    .font(ScoutFont.caption2)
                    .foregroundColor(.rankFlat)
            }
        }
    }
}

// MARK: - Rating Circle
struct RatingCircle: View {
    let rating: Double
    var size: CGFloat = 60
    var lineWidth: CGFloat = 5

    private var color: Color {
        switch rating {
        case 90...100: return Color(red: 0.95, green: 0.75, blue: 0.1)
        case 80..<90: return .scoutAccent
        case 70..<80: return .green
        default: return .gray
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: rating / 100)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: rating)
            Text(rating.scoreString)
                .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Grade Badge
struct GradeBadge: View {
    let grade: String
    var large = false

    private var color: Color {
        switch grade {
        case "A+", "A": return Color(red: 1.0, green: 0.82, blue: 0.2)
        case "A-", "B+": return .scoutAccent
        case "B", "B-": return .green
        default: return .gray
        }
    }

    var body: some View {
        Text(grade)
            .font(large ? ScoutFont.title2 : ScoutFont.headline)
            .fontWeight(.black)
            .foregroundColor(color)
            .frame(width: large ? 52 : 36, height: large ? 52 : 36)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: large ? 10 : 8))
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: ScoutSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.5))
            Text(title)
                .font(ScoutFont.title3)
                .fontWeight(.bold)
            Text(message)
                .font(ScoutFont.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(ScoutSpacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel = "See All"

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ScoutFont.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ScoutFont.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(ScoutFont.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.scoutAccent)
                }
            }
        }
        .padding(.horizontal, ScoutSpacing.lg)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var isLoading = false
    var color: Color = .scoutAccent

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.85)
            }
            configuration.label
        }
        .font(ScoutFont.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color)
        .cornerRadius(ScoutRadius.md)
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .opacity(configuration.isPressed ? 0.9 : 1.0)
        .animation(.scoutSpring, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ScoutFont.headline)
            .foregroundColor(.scoutAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.scoutAccent.opacity(0.12))
            .cornerRadius(ScoutRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ScoutRadius.md)
                    .stroke(Color.scoutAccent.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.scoutSpring, value: configuration.isPressed)
    }
}

struct PillButtonStyle: ButtonStyle {
    var isSelected = false
    var color: Color = .scoutAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ScoutFont.caption)
            .fontWeight(.semibold)
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color.white.opacity(0.08))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.scoutSpring, value: configuration.isPressed)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let label: String
    let value: String
    var highlight = false

    var body: some View {
        HStack {
            Text(label)
                .font(ScoutFont.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(ScoutFont.subheadline)
                .fontWeight(highlight ? .bold : .semibold)
                .foregroundColor(highlight ? .scoutAccent : .primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Progress Bar
struct ScoutProgressBar: View {
    let value: Double // 0.0 to 1.0
    var color: Color = .scoutAccent
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: height)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geo.size.width * min(1, max(0, value)), height: height)
                    .animation(.easeOut(duration: 0.6), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Reputation Badge
struct ReputationBadge: View {
    let tier: ReputationTier
    let score: Double

    var color: Color {
        switch tier {
        case .rookie: return .gray
        case .scout: return .blue
        case .analyst: return .green
        case .expert: return .purple
        case .elite: return .scoutGold
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tier.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(tier.rawValue)
                .font(ScoutFont.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Search Bar
struct ScoutSearchBar: View {
    @Binding var text: String
    var placeholder = "Search players..."

    var body: some View {
        HStack(spacing: ScoutSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .font(ScoutFont.body)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                    HapticFeedback.impact(.light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, ScoutSpacing.md)
        .padding(.vertical, ScoutSpacing.md)
        .background(Color.white.opacity(0.08))
        .cornerRadius(ScoutRadius.md)
    }
}

// MARK: - Player Avatar
struct PlayerAvatar: View {
    let player: Player
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(sportColor(for: player.sport).opacity(0.2))
            if let _ = player.imageURL {
                // AsyncImage would go here with real URLs
                Text(String(player.name.prefix(2)).uppercased())
                    .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                    .foregroundColor(sportColor(for: player.sport))
            } else {
                Text(String(player.name.prefix(2)).uppercased())
                    .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                    .foregroundColor(sportColor(for: player.sport))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Divider
struct ScoutDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }
}
