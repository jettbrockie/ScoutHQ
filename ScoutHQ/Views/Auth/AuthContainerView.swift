import SwiftUI
import AuthenticationServices

struct AuthContainerView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: Constants.UserDefaults.hasSeenOnboarding)

    var body: some View {
        ZStack {
            // Dark gradient background
            ScoutGradients.darkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Logo + Header
                    headerSection
                        .padding(.top, 60)
                        .padding(.bottom, 40)

                    // Auth Card
                    authCard
                        .padding(.horizontal, ScoutSpacing.lg)

                    // Divider
                    orDivider
                        .padding(.vertical, ScoutSpacing.xl)
                        .padding(.horizontal, ScoutSpacing.lg)

                    // Social Auth
                    socialAuthSection
                        .padding(.horizontal, ScoutSpacing.lg)

                    // Toggle mode
                    toggleModeButton
                        .padding(.top, ScoutSpacing.xxl)
                        .padding(.bottom, 40)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .alert("Password Reset", isPresented: $viewModel.resetEmailSent) {
            Button("OK") {}
        } message: {
            Text("Password reset email sent to \(viewModel.email). Check your inbox.")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: ScoutSpacing.md) {
            // Logo
            ZStack {
                Circle()
                    .fill(ScoutGradients.blueGradient)
                    .frame(width: 80, height: 80)
                Image(systemName: "binoculars.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            .scoutShadow()

            Text("ScoutHQ")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundColor(.primary)

            Text(viewModel.isSignUpMode
                 ? "Join the scouting community"
                 : "Welcome back, Scout")
                .font(ScoutFont.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Auth Card
    private var authCard: some View {
        VStack(spacing: ScoutSpacing.lg) {
            if viewModel.isSignUpMode {
                // Username field (sign up only)
                AuthTextField(
                    text: $viewModel.username,
                    placeholder: "Username",
                    icon: "person.fill",
                    isValid: viewModel.username.isEmpty || viewModel.isUsernameValid,
                    errorMessage: "3-30 characters, letters, numbers, underscores only"
                )
            }

            // Email
            AuthTextField(
                text: $viewModel.email,
                placeholder: "Email",
                icon: "envelope.fill",
                isEmailField: true,
                isValid: viewModel.email.isEmpty || viewModel.isEmailValid,
                errorMessage: "Enter a valid email address"
            )

            // Password
            AuthSecureField(
                text: $viewModel.password,
                placeholder: "Password",
                isValid: viewModel.password.isEmpty || viewModel.isPasswordValid,
                errorMessage: "Password must be at least 8 characters"
            )

            if viewModel.isSignUpMode {
                // Confirm Password
                AuthSecureField(
                    text: $viewModel.confirmPassword,
                    placeholder: "Confirm Password",
                    isValid: viewModel.confirmPassword.isEmpty || viewModel.isConfirmPasswordValid,
                    errorMessage: "Passwords do not match"
                )
            }

            // Forgot password
            if !viewModel.isSignUpMode {
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        Task { await viewModel.requestPasswordReset() }
                    }
                    .font(ScoutFont.footnote)
                    .foregroundColor(.scoutAccent)
                }
            }

            // Submit button
            Button {
                Task {
                    if viewModel.isSignUpMode {
                        await viewModel.signUp()
                    } else {
                        await viewModel.signIn()
                    }
                }
            } label: {
                Text(viewModel.isSignUpMode ? "Create Account" : "Sign In")
            }
            .buttonStyle(PrimaryButtonStyle(isLoading: viewModel.isLoading))
            .disabled(!viewModel.canSignIn && !viewModel.isSignUpMode)
            .disabled(!viewModel.canSignUp && viewModel.isSignUpMode)
        }
        .padding(ScoutSpacing.xl)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.xl)
    }

    // MARK: - OR Divider
    private var orDivider: some View {
        HStack(spacing: ScoutSpacing.md) {
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
            Text("or continue with")
                .font(ScoutFont.caption)
                .foregroundColor(.secondary)
                .fixedSize()
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
        }
    }

    // MARK: - Social Auth
    private var socialAuthSection: some View {
        VStack(spacing: ScoutSpacing.md) {
            // Google Sign In
            Button {
                Task { await viewModel.signInWithGoogle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Continue with Google")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.white.opacity(0.08))
                .cornerRadius(ScoutRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: ScoutRadius.md)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .disabled(viewModel.isLoading)

            // Apple Sign In
            SignInWithAppleButton(.signIn) { request in
                let appleRequest = viewModel.makeAppleSignInRequest()
                request.requestedScopes = appleRequest.requestedScopes
                request.nonce = appleRequest.nonce
            } onCompletion: { result in
                Task { await viewModel.handleAppleSignIn(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .cornerRadius(ScoutRadius.md)
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Toggle Mode
    private var toggleModeButton: some View {
        Button(action: viewModel.toggleMode) {
            HStack(spacing: 4) {
                Text(viewModel.isSignUpMode ? "Already have an account?" : "Don't have an account?")
                    .foregroundColor(.secondary)
                Text(viewModel.isSignUpMode ? "Sign In" : "Create Account")
                    .foregroundColor(.scoutAccent)
                    .fontWeight(.semibold)
            }
            .font(ScoutFont.subheadline)
        }
    }
}

// MARK: - Auth Text Field
struct AuthTextField: View {
    @Binding var text: String
    var placeholder: String
    var icon: String
    var isEmailField: Bool = false
    var isValid = true
    var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: ScoutSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                TextField(placeholder, text: $text)
#if canImport(UIKit)
                    .keyboardType(isEmailField ? .emailAddress : .default)
#endif
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            .padding(ScoutSpacing.md)
            .background(Color.white.opacity(0.06))
            .cornerRadius(ScoutRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: ScoutRadius.sm)
                    .stroke(isValid ? Color.white.opacity(0.1) : Color.red.opacity(0.6), lineWidth: 1)
            )

            if !isValid && !text.isEmpty {
                Text(errorMessage)
                    .font(ScoutFont.caption2)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Auth Secure Field
struct AuthSecureField: View {
    @Binding var text: String
    var placeholder: String
    @State private var isRevealed = false
    var isValid = true
    var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: ScoutSpacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                if isRevealed {
                    TextField(placeholder, text: $text)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: $text)
                }

                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(ScoutSpacing.md)
            .background(Color.white.opacity(0.06))
            .cornerRadius(ScoutRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: ScoutRadius.sm)
                    .stroke(isValid ? Color.white.opacity(0.1) : Color.red.opacity(0.6), lineWidth: 1)
            )

            if !isValid && !text.isEmpty {
                Text(errorMessage)
                    .font(ScoutFont.caption2)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
}
