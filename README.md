# ScoutHQ iOS App

A fan-powered scouting + rankings platform for NFL, NBA, and MLB built with SwiftUI and Firebase.

## Features

- 🔐 **Authentication** — Email/password, Google Sign-In, Apple Sign-In
- 🏠 **Home Feed** — Trending players, rising/falling prospects, featured reports, Top Scouts leaderboard
- 📊 **Rankings** — Filterable by sport, league, and position with consensus scores and rank movement
- 👤 **Player Profiles** — Stats, AI-generated scouting reports, community reports with upvote/downvote
- 📝 **Submit Reports** — 4-step guided report submission with rating sliders
- 👤 **Profile** — Reputation system, report history, sport-based activity tracking
- 🤖 **AI Reports** — Aggregates user data via Claude API to generate consensus scouting reports

## Architecture

```
ScoutHQ/
├── App/                    # Entry point (ScoutHQApp, SplashView, RootView)
├── Models/                 # Data models (User, Player, ScoutingReport, Ranking)
├── ViewModels/             # MVVM ViewModels (Auth, Home, Rankings, Player, Scout, Profile)
├── Views/
│   ├── Auth/               # Login / SignUp screens
│   ├── Main/               # MainTabView with custom tab bar
│   ├── Home/               # Home feed with trending, movers, featured reports
│   ├── Rankings/           # Rankings list with filter sheet
│   ├── Players/            # Player profile (Overview, AI Report, User Reports)
│   ├── ScoutingReport/     # 4-step submit report flow
│   ├── Profile/            # User profile + edit
│   └── Components/         # Shared components (cards, sliders, badges)
├── Services/               # Firebase Auth, Firestore, AI, Mock Data
└── Utils/                  # Theme, Constants, Extensions
```

## Setup Instructions

### 1. Prerequisites

- Xcode 15.0+
- iOS 17.0+ deployment target
- Firebase account
- (Optional) Anthropic API key for AI scouting reports

### 2. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new iOS project
3. Set Bundle ID to `com.yourname.scouthq`
4. Enable **Authentication** with:
   - Email/Password
   - Google Sign-In
   - Apple Sign-In
5. Enable **Cloud Firestore** in your region
6. Enable **Firebase Storage**
7. Download `GoogleService-Info.plist` and replace the placeholder in `ScoutHQ/Resources/`

### 3. Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /players/{playerId} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only
    }

    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.user_id == request.auth.uid;
      allow update: if request.auth != null
        && (resource.data.user_id == request.auth.uid
            || request.resource.data.diff(resource.data).affectedKeys()
               .hasOnly(['upvotes', 'downvotes', 'user_votes']));
    }

    match /rankings/{rankingId} {
      allow read: if request.auth != null;
      allow write: if false; // Cloud Functions only
    }

    match /ai_reports/{reportId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### 4. Open in Xcode

```bash
# Option A: Open Package.swift directly
open Package.swift

# Option B: Generate Xcode project (requires xcodegen)
brew install xcodegen
xcodegen generate
open ScoutHQ.xcodeproj
```

### 5. Configure Google Sign-In

In your `Info.plist`, add the URL scheme for Google Sign-In:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Find your `REVERSED_CLIENT_ID` in `GoogleService-Info.plist`.

### 6. AI Scouting Reports (Optional)

Set the `ANTHROPIC_API_KEY` environment variable in Xcode:

1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Add `ANTHROPIC_API_KEY` = `sk-ant-...`

Without the API key, the app uses realistic mock AI reports.

### 7. Build & Run

1. Select your target device or simulator (iOS 17+)
2. Press `Cmd+R` to build and run
3. The app will use mock data by default — Firebase data is populated on first launch

## Data Models

| Collection | Purpose |
|-----------|---------|
| `users` | User profiles with reputation scores |
| `players` | Player profiles with stats |
| `reports` | Community scouting reports |
| `rankings` | Computed consensus rankings |
| `ai_reports` | Cached AI-generated scout reports |

## Reputation System

| Tier | Points Required | Badge |
|------|----------------|-------|
| Rookie Scout | 0 | 👤 |
| Scout | 100 | 🔭 |
| Analyst | 500 | 📊 |
| Expert | 1,500 | ⭐ |
| Elite Scout | 5,000 | 👑 |

Points are awarded for:
- Submitting a report: +10 pts
- Getting an upvote: +5 pts  
- Getting a downvote: -2 pts
- Accurate prediction: +25 pts

## Monetization

Premium tier placeholder is built in. To implement:
1. Set up StoreKit in Xcode
2. Create a subscription product in App Store Connect
3. Hook into `isPremium` in `AppUser` model
4. Gate features with `@EnvironmentObject var authService` + `user.isPremium`

## Tech Stack

- **SwiftUI** — Declarative UI framework
- **Firebase Auth** — Authentication
- **Cloud Firestore** — NoSQL database
- **Firebase Storage** — Media storage
- **Claude API** — AI scouting report generation
- **Google Sign-In SDK** — Google authentication
- **MVVM** — Architecture pattern
- **Swift Concurrency** — async/await throughout
