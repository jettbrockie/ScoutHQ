#!/bin/bash
# ScoutHQ Firebase Setup Script
# Run this after configuring your Firebase project and placing GoogleService-Info.plist

echo "🏈 ScoutHQ Firebase Setup"
echo "========================="

# Check for Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "Installing Firebase CLI..."
    npm install -g firebase-tools
fi

# Login to Firebase
echo "Logging into Firebase..."
firebase login

# Initialize Firestore
echo "Setting up Firestore security rules..."
cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /players/{playerId} {
      allow read: if request.auth != null;
      allow write: if false;
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
      allow write: if false;
    }
    match /ai_reports/{reportId} {
      allow read, write: if request.auth != null;
    }
    match /hot_takes/{takeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.user_id == request.auth.uid;
    }
  }
}
EOF

echo "Deploying Firestore rules..."
firebase deploy --only firestore:rules

# Create Firestore indexes
cat > firestore.indexes.json << 'EOF'
{
  "indexes": [
    {
      "collectionGroup": "reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "player_id", "order": "ASCENDING" },
        { "fieldPath": "created_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "player_id", "order": "ASCENDING" },
        { "fieldPath": "upvotes", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "user_id", "order": "ASCENDING" },
        { "fieldPath": "created_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "rankings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "sport", "order": "ASCENDING" },
        { "fieldPath": "league", "order": "ASCENDING" },
        { "fieldPath": "overall_rank", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "players",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "sport", "order": "ASCENDING" },
        { "fieldPath": "is_trending", "order": "DESCENDING" },
        { "fieldPath": "trending_score", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
EOF

echo "Deploying Firestore indexes..."
firebase deploy --only firestore:indexes

echo ""
echo "✅ Firebase setup complete!"
echo ""
echo "Next steps:"
echo "1. Replace ScoutHQ/Resources/GoogleService-Info.plist with your real plist"
echo "2. Add your REVERSED_CLIENT_ID to Info.plist URL schemes"
echo "3. Enable Auth providers in Firebase Console:"
echo "   - Email/Password"
echo "   - Google"
echo "   - Apple"
echo "4. Open Package.swift in Xcode and build the app"
echo ""
echo "Optional:"
echo "5. Set ANTHROPIC_API_KEY in Xcode scheme environment variables"
echo "   for AI-powered scouting report generation"
