import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct ScoutHQApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else if authService.firebaseUser != nil {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                AuthContainerView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
        .animation(.scoutSpring, value: authService.firebaseUser != nil)
    }
}

// MARK: - Splash Screen
struct SplashView: View {
    @State private var animate = false
    @State private var scaleEffect: CGFloat = 0.6
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            ScoutGradients.darkBackground
                .ignoresSafeArea()

            VStack(spacing: ScoutSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(ScoutGradients.blueGradient)
                        .frame(width: 100, height: 100)
                        .scoutShadow()

                    Image(systemName: "binoculars.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(scaleEffect)

                VStack(spacing: 8) {
                    Text("ScoutHQ")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Fan-Powered Scouting")
                        .font(ScoutFont.subheadline)
                        .foregroundColor(.secondary)
                        .tracking(2)
                        .textCase(.uppercase)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scaleEffect = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                opacity = 1.0
            }
        }
    }
}
