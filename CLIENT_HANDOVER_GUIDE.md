# Client Handover Guide - Credentials Migration

This guide lists all credentials and configurations that need to be changed when handing over the project to the client.

## 📋 Table of Contents
1. [Firebase Configuration Files](#firebase-configuration-files)
2. [Package Names & Bundle IDs](#package-names--bundle-ids)
3. [Step-by-Step Migration Process](#step-by-step-migration-process)
4. [How to Find Client Credentials](#how-to-find-client-credentials)
5. [Verification Checklist](#verification-checklist)

---

## 🔥 Firebase Configuration Files

### Files That Need to Be Replaced:

1. **`android/app/google-services.json`** (Android)
   - Contains: Project ID, API keys, App ID, Package name
   - **Location in client's Firebase:** Project Settings → Your apps → Android app → Download `google-services.json`

2. **`ios/Runner/GoogleService-Info.plist`** (iOS)
   - Contains: API keys, Project ID, Bundle ID, App ID
   - **Location in client's Firebase:** Project Settings → Your apps → iOS app → Download `GoogleService-Info.plist`

3. **`lib/firebase_options.dart`** (Flutter - All platforms)
   - Contains: API keys, App IDs, Project IDs for all platforms (Android, iOS, Web, Windows, macOS)
   - **How to regenerate:** Use FlutterFire CLI (see instructions below)

4. **`firebase.json`** (Firebase CLI config)
   - Contains: Project ID and App IDs
   - **Location:** Root of project

---

## 📦 Package Names & Bundle IDs

### Current Values (YOUR PROJECT):
- **Android Package Name:** `com.example.caregiver`
- **iOS Bundle ID:** `com.example.caregiver`
- **macOS Bundle ID:** `com.example.caregiver`

### Files That Need Package Name Changes:

#### Android:
1. **`android/app/build.gradle.kts`**
   - Line 12: `namespace = "com.example.caregiver"`
   - Line 27: `applicationId = "com.example.caregiver"`

#### iOS:
1. **`ios/Runner.xcodeproj/project.pbxproj`**
   - Multiple lines with: `PRODUCT_BUNDLE_IDENTIFIER = com.example.caregiver;`
   - **Note:** This file is auto-generated, better to change via Xcode

2. **`ios/Runner/Info.plist`**
   - Uses `$(PRODUCT_BUNDLE_IDENTIFIER)` (inherits from Xcode project)

3. **`lib/firebase_options.dart`**
   - Line 67: `iosBundleId: 'com.example.caregiver',`
   - Line 76: `iosBundleId: 'com.example.caregiver',`

#### macOS:
1. **`macos/Runner/Configs/AppInfo.xcconfig`**
   - Line 11: `PRODUCT_BUNDLE_IDENTIFIER = com.example.caregiver`

---

## 🔄 Step-by-Step Migration Process

### Step 1: Create Firebase Project for Client

**Client needs to:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Follow the setup wizard
4. Enable the following services:
   - ✅ Authentication (Email/Password)
   - ✅ Cloud Firestore
   - ✅ Storage (if using image uploads)

### Step 2: Register Apps in Firebase

#### For Android App:
1. In Firebase Console → Project Settings → Your apps
2. Click "Add app" → Select Android
3. Enter package name: `com.clientname.caregiver` (or client's preferred package name)
4. Download `google-services.json`
5. Copy it to: `android/app/google-services.json`
6. **IMPORTANT:** Firebase Console will show instructions to "Add Firebase SDK" and "Sync Gradle files" - **YOU CAN SKIP THESE STEPS** because:
   - The project is already configured with `google-services` plugin (already in `build.gradle.kts`)
   - Firebase SDKs are managed by Flutter plugins (`firebase_core`, `firebase_auth`, etc. in `pubspec.yaml`)
   - Only replacing the `google-services.json` file is needed

#### For iOS App:
1. In Firebase Console → Project Settings → Your apps
2. Click "Add app" → Select iOS
3. Enter bundle ID: `com.clientname.caregiver` (must match Xcode bundle ID)
4. Download `GoogleService-Info.plist`
5. Copy it to: `ios/Runner/GoogleService-Info.plist`
6. **IMPORTANT:** Firebase Console may show instructions to add Firebase SDK - **YOU CAN SKIP THESE STEPS** because:
   - Firebase SDKs are managed by Flutter plugins (`firebase_core`, `firebase_auth`, etc.)
   - Only replacing the `GoogleService-Info.plist` file is needed

#### For Web App (if needed):
1. In Firebase Console → Project Settings → Your apps
2. Click "Add app" → Select Web
3. Register app name
4. Copy the config object (will be used in FlutterFire CLI)

#### For Windows App (if needed):
1. Register as Web app (Windows uses web config)
2. Copy the config object

### Step 3: Update Package Names/Bundle IDs

**IMPORTANT:** Package names must match exactly between:
- Firebase app registration
- Android `build.gradle.kts` / iOS Xcode project
- `google-services.json` / `GoogleService-Info.plist`

#### Android:
```kotlin
// android/app/build.gradle.kts
namespace = "com.clientname.caregiver"
applicationId = "com.clientname.caregiver"
```

#### iOS (via Xcode):
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Runner" project in left sidebar
3. Select "Runner" target
4. Go to "Signing & Capabilities" tab
5. Change "Bundle Identifier" to: `com.clientname.caregiver`
6. This will automatically update `project.pbxproj`

#### macOS (via Xcode):
1. Open `macos/Runner.xcworkspace` in Xcode
2. Follow same steps as iOS

### Step 4: Regenerate firebase_options.dart

**Using FlutterFire CLI (Recommended):**

1. Install FlutterFire CLI (if not installed):
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Configure Firebase:
   ```bash
   cd caregiver
   flutterfire configure
   ```

3. Follow the prompts:
   - Select the client's Firebase project
   - Select platforms: Android, iOS, Web, Windows, macOS
   - For each platform, select the corresponding app you registered
   - The CLI will automatically update `lib/firebase_options.dart`

**Manual Method (if CLI doesn't work):**

Update `lib/firebase_options.dart` with values from:
- Android: `google-services.json`
- iOS: `GoogleService-Info.plist`
- Web/Windows: Firebase Console → Project Settings → Your apps → Web app → Config

### Step 5: Update firebase.json

Update the project ID in `firebase.json`:
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "CLIENT_PROJECT_ID",  // ← Change this
          "appId": "CLIENT_ANDROID_APP_ID",  // ← Change this
          "fileOutput": "android/app/google-services.json"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "CLIENT_PROJECT_ID",  // ← Change this
          "configurations": {
            "android": "CLIENT_ANDROID_APP_ID",  // ← Change this
            "ios": "CLIENT_IOS_APP_ID",         // ← Change this
            "macos": "CLIENT_IOS_APP_ID",       // ← Change this (usually same as iOS)
            "web": "CLIENT_WEB_APP_ID",         // ← Change this
            "windows": "CLIENT_WEB_APP_ID"      // ← Change this (usually same as web)
          }
        }
      }
    }
  }
}
```

### Step 6: Set Up Firestore

1. In Firebase Console → Firestore Database
2. Create database (Start in test mode, then update rules)
3. Copy `firestore.rules` content to Firestore Rules
4. Copy `firestore.indexes.json` content to Firestore Indexes
5. Deploy rules:
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only firestore:indexes
   ```

### Step 7: Configure Firebase Authentication

1. In Firebase Console → Authentication → Sign-in method
2. Enable "Email/Password" provider
3. (Optional) Configure email templates (see `FIREBASE_EMAIL_CUSTOMIZATION.md`)

### Step 8: Set Up Firebase Storage (if used)

1. In Firebase Console → Storage
2. Create storage bucket
3. Set up security rules (if needed)

---

## 🔍 How to Find Client Credentials

### Firebase Project ID
- **Location:** Firebase Console → Project Settings → General tab
- **Field:** "Project ID"
- **Example:** `caregiver-cba18` → Client's will be different

### API Keys
- **Location:** Firebase Console → Project Settings → General tab → Your apps
- **For each app (Android/iOS/Web):**
  - Click on the app
  - Find "API Key" in the config
  - **Note:** API keys are safe to expose in client apps (they're restricted by domain/package)

### App IDs
- **Location:** Firebase Console → Project Settings → General tab → Your apps
- **Format:** `1:PROJECT_NUMBER:platform:APP_ID_SUFFIX`
- **Example:** `1:929615381650:android:049fef3cfaec642bbe124b`
- **Components:**
  - `PROJECT_NUMBER`: Found in Project Settings → General
  - `APP_ID_SUFFIX`: Auto-generated when you register the app

### Messaging Sender ID
- **Location:** Firebase Console → Project Settings → Cloud Messaging tab
- **Field:** "Sender ID"
- **Note:** Same as Project Number

### Storage Bucket
- **Location:** Firebase Console → Storage → Files tab
- **Format:** `PROJECT_ID.firebasestorage.app`
- **Or:** Firebase Console → Project Settings → General → Your apps → Storage bucket

### Auth Domain
- **Location:** Firebase Console → Authentication → Settings
- **Field:** "Authorized domains"
- **Format:** `PROJECT_ID.firebaseapp.com`

### Measurement ID (for Analytics/Web)
- **Location:** Firebase Console → Project Settings → General → Your apps → Web app
- **Field:** "Measurement ID"
- **Format:** `G-XXXXXXXXXX`

---

## ✅ Verification Checklist

After migration, verify the following:

### Firebase Configuration
- [ ] `android/app/google-services.json` replaced with client's file
- [ ] `ios/Runner/GoogleService-Info.plist` replaced with client's file
- [ ] `lib/firebase_options.dart` updated with client's credentials
- [ ] `firebase.json` updated with client's project ID

### Package Names
- [ ] Android `applicationId` matches Firebase Android app package name
- [ ] iOS Bundle ID matches Firebase iOS app bundle ID
- [ ] `google-services.json` has correct `package_name`
- [ ] `GoogleService-Info.plist` has correct `BUNDLE_ID`
- [ ] `firebase_options.dart` has correct `iosBundleId`

### Firebase Services
- [ ] Authentication enabled (Email/Password)
- [ ] Firestore database created
- [ ] Firestore rules deployed
- [ ] Firestore indexes deployed
- [ ] Storage bucket created (if needed)

### Testing
- [ ] App builds successfully for Android
- [ ] App builds successfully for iOS
- [ ] User can register/login
- [ ] Data saves to Firestore correctly
- [ ] Images upload to Storage (if applicable)

---

## 🚨 Important Notes

1. **Package Name Consistency:** The package name/bundle ID must be EXACTLY the same in:
   - Firebase app registration
   - Android `build.gradle.kts` / iOS Xcode project
   - Configuration files

2. **Firebase Project:** Client should create their own Firebase project. Do NOT share your Firebase project credentials.

3. **Firestore Data:** Existing data in your Firestore will NOT transfer automatically. Client starts with empty database.

4. **Authentication Users:** User accounts need to be created fresh in client's Firebase Authentication.

5. **Storage Files:** Any uploaded images/files need to be migrated separately if needed.

6. **Firestore Rules:** Make sure to deploy the security rules from `firestore.rules` to client's Firestore.

7. **Indexes:** Deploy indexes from `firestore.indexes.json` to avoid query errors.

---

## 📞 Support

If the client encounters issues:
1. Verify all package names match exactly
2. Check Firebase Console for any error messages
3. Ensure all Firebase services are enabled
4. Check FlutterFire CLI output for any warnings
5. Review Firebase Console → Project Settings → General for any missing configurations

---

## 🔄 Quick Reference: Current vs Client Values

| Item | Current (Yours) | Client (To Fill) |
|------|----------------|-------------------|
| Firebase Project ID | `caregiver-cba18` | `_____________` |
| Android Package | `com.example.caregiver` | `_____________` |
| iOS Bundle ID | `com.example.caregiver` | `_____________` |
| Android App ID | `1:929615381650:android:...` | `_____________` |
| iOS App ID | `1:929615381650:ios:...` | `_____________` |
| Web App ID | `1:929615381650:web:...` | `_____________` |
| Messaging Sender ID | `929615381650` | `_____________` |

---

**Last Updated:** January 2025
