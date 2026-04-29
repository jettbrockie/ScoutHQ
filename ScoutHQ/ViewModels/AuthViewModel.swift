import SwiftUI
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var username = ""
    @Published var isSignUpMode = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showPasswordReset = false
    @Published var resetEmailSent = false

    private let authService = AuthService.shared

    var currentUser: AppUser? { authService.currentUser }
    var isAuthenticated: Bool { authService.firebaseUser != nil }

    // MARK: - Validation
    var isEmailValid: Bool { email.isValidEmail }
    var isPasswordValid: Bool { password.count >= 8 }
    var isUsernameValid: Bool { username.isValidUsername }
    var isConfirmPasswordValid: Bool { password == confirmPassword }

    var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty && isEmailValid && !isLoading
    }

    var canSignUp: Bool {
        isEmailValid && isPasswordValid && isUsernameValid &&
        isConfirmPasswordValid && !isLoading
    }

    // MARK: - Actions
    func signIn() async {
        guard canSignIn else { return }
        isLoading = true
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            showError(message: parseAuthError(error))
        }
        isLoading = false
    }

    func signUp() async {
        guard canSignUp else { return }
        isLoading = true
        do {
            try await authService.signUp(email: email, password: password, username: username)
        } catch {
            showError(message: parseAuthError(error))
        }
        isLoading = false
    }

    func signInWithGoogle() async {
        isLoading = true
        do {
            try await authService.signInWithGoogle()
        } catch {
            showError(message: parseAuthError(error))
        }
        isLoading = false
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            isLoading = true
            do {
                try await authService.signInWithApple(authorization: auth)
            } catch {
                showError(message: parseAuthError(error))
            }
            isLoading = false
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                showError(message: parseAuthError(error))
            }
        }
    }

    func requestPasswordReset() async {
        guard isEmailValid else {
            showError(message: "Please enter a valid email address.")
            return
        }
        isLoading = true
        do {
            try await authService.resetPassword(email: email)
            resetEmailSent = true
        } catch {
            showError(message: parseAuthError(error))
        }
        isLoading = false
    }

    func signOut() {
        try? authService.signOut()
    }

    func toggleMode() {
        withAnimation(.scoutSpring) {
            isSignUpMode.toggle()
            clearFields()
        }
    }

    // MARK: - Helpers
    private func showError(message: String) {
        errorMessage = message
        showError = true
        HapticFeedback.notification(.error)
    }

    private func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        username = ""
        errorMessage = nil
    }

    private func parseAuthError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }

        let nsError = error as NSError
        switch nsError.code {
        case 17007: return "An account already exists with this email."
        case 17008: return "The email address is badly formatted."
        case 17009: return "Incorrect password. Please try again."
        case 17011: return "No account found with this email."
        case 17026: return "Password must be at least 6 characters."
        default: return error.localizedDescription
        }
    }

    // MARK: - Apple Sign In Request
    func makeAppleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = authService.startAppleSignIn()
        return request
    }
}
