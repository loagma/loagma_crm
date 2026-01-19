#!/bin/bash

# Firebase Deployment Script for Live Salesman Tracking System
# This script deploys all Firebase configuration and Cloud Functions

set -e  # Exit on any error

echo "🚀 Starting Firebase deployment for Live Salesman Tracking System..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please log in to Firebase:"
    firebase login
fi

# Check if firebase.json exists
if [ ! -f "firebase.json" ]; then
    echo "❌ firebase.json not found. Make sure you're in the firebase directory."
    exit 1
fi

echo "📋 Current Firebase projects:"
firebase projects:list

echo ""
read -p "Enter your Firebase project ID: " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Project ID cannot be empty"
    exit 1
fi

echo "🎯 Using Firebase project: $PROJECT_ID"
firebase use "$PROJECT_ID"

echo ""
echo "🔧 Deploying Firebase configuration..."

# Deploy Firestore rules and indexes
echo "📄 Deploying Firestore rules..."
firebase deploy --only firestore:rules

echo "📊 Deploying Firestore indexes..."
firebase deploy --only firestore:indexes

# Deploy Realtime Database rules
echo "🔄 Deploying Realtime Database rules..."
firebase deploy --only database

# Deploy Cloud Functions (if functions directory exists)
if [ -d "functions" ]; then
    echo "☁️ Installing Cloud Functions dependencies..."
    cd functions
    npm install
    cd ..
    
    echo "🚀 Deploying Cloud Functions..."
    firebase deploy --only functions
else
    echo "⚠️ Functions directory not found, skipping Cloud Functions deployment"
fi

echo ""
echo "✅ Firebase deployment completed successfully!"
echo ""
echo "🔗 Useful links:"
echo "Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
echo "Firestore: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo "Authentication: https://console.firebase.google.com/project/$PROJECT_ID/authentication"
echo "Realtime Database: https://console.firebase.google.com/project/$PROJECT_ID/database"

echo ""
echo "📝 Next steps:"
echo "1. Configure Flutter apps with your project credentials"
echo "2. Create initial admin user using the createInitialAdmin Cloud Function"
echo "3. Test authentication and database operations"
echo "4. Proceed to Mapbox setup (Task 2)"

echo ""
echo "🧪 To test with emulators, run:"
echo "firebase emulators:start"