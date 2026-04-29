import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @EnvironmentObject var authService: AuthService

    enum Tab: Int, CaseIterable {
        case home = 0
        case rankings = 1
        case submit = 2
        case profile = 3

        var title: String {
            switch self {
            case .home: return "Home"
            case .rankings: return "Rankings"
            case .submit: return "Scout"
            case .profile: return "Profile"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .rankings: return "list.number"
            case .submit: return "plus.circle.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)

                RankingsView()
                    .tag(Tab.rankings)

                SubmitReportView()
                    .tag(Tab.submit)

                ProfileView()
                    .tag(Tab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.scoutSpring) {
                        selectedTab = tab
                    }
                    HapticFeedback.selection()
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if tab == .submit {
                                // Highlighted submit button
                                Circle()
                                    .fill(ScoutGradients.blueGradient)
                                    .frame(width: 44, height: 44)
                                    .scoutShadow()
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20, weight: selectedTab == tab ? .bold : .regular))
                                    .foregroundColor(selectedTab == tab ? .scoutAccent : .secondary)
                                    .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                            }
                        }

                        if tab != .submit {
                            Text(tab.title)
                                .font(ScoutFont.caption2)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                .foregroundColor(selectedTab == tab ? .scoutAccent : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, tab == .submit ? 8 : 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ScoutSpacing.lg)
        .padding(.top, 8)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(Color.scoutSurface.opacity(0.95))
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1),
                    alignment: .top
                )
        )
        .animation(.scoutSpring, value: selectedTab)
    }
}
