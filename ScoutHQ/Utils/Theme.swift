import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let background = Color("Background")
    static let surfacePrimary = Color("SurfacePrimary")
    static let surfaceSecondary = Color("SurfaceSecondary")
    static let surfaceTertiary = Color("SurfaceTertiary")

    // Accents
    static let accentBlue = Color("AccentBlue")
    static let accentGold = Color("AccentGold")
    static let accentGreen = Color("AccentGreen")
    static let accentRed = Color("AccentRed")
    static let accentOrange = Color("AccentOrange")

    // Sport Colors
    static let footballGreen = Color("FootballGreen")
    static let basketballOrange = Color("BasketballOrange")
    static let baseballRed = Color("BaseballRed")

    // Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")

    // Rank change colors
    static let rankUp = Color.green
    static let rankDown = Color.red
    static let rankFlat = Color.gray

    // Hardcoded fallbacks for previews
    static var scoutBackground: Color { Color(red: 0.07, green: 0.07, blue: 0.09) }
    static var scoutSurface: Color { Color(red: 0.11, green: 0.11, blue: 0.14) }
    static var scoutSurface2: Color { Color(red: 0.15, green: 0.15, blue: 0.18) }
    static var scoutAccent: Color { Color(red: 0.25, green: 0.55, blue: 1.0) }
    static var scoutGold: Color { Color(red: 1.0, green: 0.82, blue: 0.25) }
}

// MARK: - Typography
struct ScoutFont {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    static let statNumber = Font.system(size: 24, weight: .black, design: .rounded)
    static let rankNumber = Font.system(size: 20, weight: .black, design: .rounded)
    static let rating = Font.system(size: 32, weight: .black, design: .rounded)
}

// MARK: - Spacing
struct ScoutSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 48
}

// MARK: - Corner Radius
struct ScoutRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let pill: CGFloat = 100
}

// MARK: - Gradient Definitions
struct ScoutGradients {
    static let footballGradient = LinearGradient(
        colors: [Color(red: 0.13, green: 0.55, blue: 0.13), Color(red: 0.07, green: 0.35, blue: 0.07)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let basketballGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.45, blue: 0.1), Color(red: 0.75, green: 0.25, blue: 0.0)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let baseballGradient = LinearGradient(
        colors: [Color(red: 0.85, green: 0.15, blue: 0.15), Color(red: 0.65, green: 0.05, blue: 0.05)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let goldGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.95, green: 0.7, blue: 0.1)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let blueGradient = LinearGradient(
        colors: [Color(red: 0.25, green: 0.55, blue: 1.0), Color(red: 0.15, green: 0.35, blue: 0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let darkBackground = LinearGradient(
        colors: [Color(red: 0.07, green: 0.07, blue: 0.09), Color(red: 0.05, green: 0.05, blue: 0.07)],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Sport Gradient Helper
func sportGradient(for sport: Sport) -> LinearGradient {
    switch sport {
    case .football: return ScoutGradients.footballGradient
    case .basketball: return ScoutGradients.basketballGradient
    case .baseball: return ScoutGradients.baseballGradient
    }
}

func sportColor(for sport: Sport) -> Color {
    switch sport {
    case .football: return Color(red: 0.13, green: 0.55, blue: 0.13)
    case .basketball: return Color(red: 0.95, green: 0.45, blue: 0.1)
    case .baseball: return Color(red: 0.85, green: 0.15, blue: 0.15)
    }
}

// MARK: - View Modifiers
struct CardModifier: ViewModifier {
    var padding: CGFloat = ScoutSpacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.scoutSurface)
            .cornerRadius(ScoutRadius.lg)
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(ScoutRadius.lg)
    }
}

extension View {
    func cardStyle(padding: CGFloat = ScoutSpacing.lg) -> some View {
        modifier(CardModifier(padding: padding))
    }

    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }

    func scoutShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    func shimmer(active: Bool) -> some View {
        self.redacted(reason: active ? .placeholder : [])
            .shimmering(active: active)
    }
}

// MARK: - Shimmering Effect
struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if active {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.15),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: -geo.size.width + (geo.size.width * 2) * phase)
                    }
                    .clipped()
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func shimmering(active: Bool) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}
