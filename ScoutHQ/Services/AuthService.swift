import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: AppUser?
    @Published var firebaseUser: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var error: AuthError?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    private init() {
        setupAuthListener()
    }

    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.firebaseUser = user
                if let user = user {
                    await self?.fetchUserProfile(uid: user.uid)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }

    // MARK: - Email/Password Auth

    func signUp(email: String, password: String, username: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard await isUsernameAvailable(username) else {
            throw AuthError.usernameTaken
        }

        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = AppUser(
            id: result.user.uid,
            username: username,
            email: email,
            profileImageURL: nil,
            favoriteTeams: [],
            reputationScore: 0,
            followersCount: 0,
            followingCount: 0,
            reportsCount: 0,
            createdAt: Date(),
            bio: nil,
            isPremium: false,
            accuracyScore: 0,
            totalVotesReceived: 0
        )
        try await createUserProfile(user: user)
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.unknown
        }

        isLoading = true
        defer { isLoading = false }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.googleSignInFailed
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)

        if currentUser == nil {
            let username = generateUsername(from: result.user.profile?.name ?? "user")
            let user = AppUser(
                id: authResult.user.uid,
                username: username,
                email: authResult.user.email ?? "",
                profileImageURL: result.user.profile?.imageURL(withDimension: 200)?.absoluteString,
                favoriteTeams: [],
                reputationScore: 0,
                followersCount: 0,
                followingCount: 0,
                reportsCount: 0,
                createdAt: Date(),
                bio: nil,
                isPremium: false,
                accuracyScore: 0,
                totalVotesReceived: 0
            )
            try await createUserProfile(user: user)
        }
    }

    // MARK: - Apple Sign In

    private var currentNonce: String?

    func startAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    func signInWithApple(authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.appleSignInFailed
        }

        isLoading = true
        defer { isLoading = false }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        let authResult = try await Auth.auth().signIn(with: credential)

        if currentUser == nil {
            let displayName = [
                appleIDCredential.fullName?.givenName,
                appleIDCredential.fullName?.familyName
            ].compactMap { $0 }.joined(separator: " ")

            let username = generateUsername(from: displayName.isEmpty ? "user" : displayName)
            let user = AppUser(
                id: authResult.user.uid,
                username: username,
                email: authResult.user.email ?? "",
                profileImageURL: nil,
                favoriteTeams: [],
                reputationScore: 0,
                followersCount: 0,
                followingCount: 0,
                reportsCount: 0,
                createdAt: Date(),
                bio: nil,
                isPremium: false,
                accuracyScore: 0,
                totalVotesReceived: 0
            )
            try await createUserProfile(user: user)
        }
    }

    // MARK: - User Profile

    func fetchUserProfile(uid: String) async {
        do {
            let doc = try await db.collection(Constants.Firestore.usersCollection).document(uid).getDocument()
            currentUser = try doc.data(as: AppUser.self)
        } catch {
            print("Error fetching user profile: \(error)")
        }
    }

    func updateUserProfile(_ user: AppUser) async throws {
        guard let id = user.id else { throw AuthError.unknown }
        try db.collection(Constants.Firestore.usersCollection).document(id).setData(from: user, merge: true)
        currentUser = user
    }

    private func createUserProfile(user: AppUser) async throws {
        guard let id = user.id else { throw AuthError.unknown }
        try db.collection(Constants.Firestore.usersCollection).document(id).setData(from: user)
        currentUser = user
    }

    private func isUsernameAvailable(_ username: String) async -> Bool {
        do {
            let snapshot = try await db.collection(Constants.Firestore.usersCollection)
                .whereField("username", isEqualTo: username)
                .limit(to: 1)
                .getDocuments()
            return snapshot.documents.isEmpty
        } catch {
            return true
        }
    }

    // MARK: - Helpers

    private func generateUsername(from name: String) -> String {
        let base = name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        let truncated = String(base.prefix(20))
        let random = Int.random(in: 100...999)
        return "\(truncated)\(random)"
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce.")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case usernameTaken
    case googleSignInFailed
    case appleSignInFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .usernameTaken: return "That username is already taken. Please choose another."
        case .googleSignInFailed: return "Google sign-in failed. Please try again."
        case .appleSignInFailed: return "Apple sign-in failed. Please try again."
        case .unknown: return "An unknown error occurred. Please try again."
        }
    }
}
