# Credentials Migration Checklist

Quick reference for all files and values that need to be changed.

## 🔥 Firebase Configuration Files (REPLACE ENTIRE FILES)

### 1. Android Configuration
- **File:** `android/app/google-services.json`
- **Source:** Firebase Console → Project Settings → Your apps → Android app → Download
- **Action:** Replace entire file

### 2. iOS Configuration  
- **File:** `ios/Runner/GoogleService-Info.plist`
- **Source:** Firebase Console → Project Settings → Your apps → iOS app → Download
- **Action:** Replace entire file

### 3. Flutter Firebase Options
- **File:** `lib/firebase_options.dart`
- **Source:** Generate using `flutterfire configure` command
- **Action:** Regenerate using FlutterFire CLI (recommended) or manually update

---

## 📝 Files Requiring Manual Edits

### Android Package Name

#### File: `android/app/build.gradle.kts`
```kotlin
// Line 12 - Change namespace
namespace = "com.example.caregiver"  // ← Change to client's package name

// Line 27 - Change applicationId
applicationId = "com.example.caregiver"  // ← Change to client's package name
```

**Current Value:** `com.example.caregiver`  
**Client Value:** `_________________`

---

### iOS Bundle ID

#### Option 1: Via Xcode (Recommended)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Runner" project → "Runner" target
3. "Signing & Capabilities" tab
4. Change "Bundle Identifier"

#### Option 2: Manual Edit
**File:** `ios/Runner.xcodeproj/project.pbxproj`
- Search and replace: `com.example.caregiver` → Client's bundle ID
- **Warning:** This file is auto-generated, Xcode method is safer

**Current Value:** `com.example.caregiver`  
**Client Value:** `_________________`

---

### macOS Bundle ID

#### Option 1: Via Xcode (Recommended)
1. Open `macos/Runner.xcworkspace` in Xcode
2. Select "Runner" project → "Runner" target
3. "Signing & Capabilities" tab
4. Change "Bundle Identifier"

#### Option 2: Manual Edit
**File:** `macos/Runner/Configs/AppInfo.xcconfig`
```
PRODUCT_BUNDLE_IDENTIFIER = com.example.caregiver  // ← Change to client's bundle ID
```

**Current Value:** `com.example.caregiver`  
**Client Value:** `_________________`

---

### Flutter Firebase Options (if not using CLI)

**File:** `lib/firebase_options.dart`

#### Android Section (Lines 53-59):
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyAimfqIo6F8afMLQu4jkwKkyijxL6EEhrA',  // ← From google-services.json
  appId: '1:929615381650:android:049fef3cfaec642bbe124b',  // ← From google-services.json
  messagingSenderId: '929615381650',  // ← From google-services.json
  projectId: 'caregiver-cba18',  // ← From google-services.json
  storageBucket: 'caregiver-cba18.firebasestorage.app',  // ← From google-services.json
);
```

#### iOS Section (Lines 61-68):
```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSyAEkOQycup-JESgrmOqiVwJadjzwI2nbXo',  // ← From GoogleService-Info.plist
  appId: '1:929615381650:ios:e814e977cbca7ee0be124b',  // ← From GoogleService-Info.plist
  messagingSenderId: '929615381650',  // ← From GoogleService-Info.plist
  projectId: 'caregiver-cba18',  // ← From GoogleService-Info.plist
  storageBucket: 'caregiver-cba18.firebasestorage.app',  // ← From GoogleService-Info.plist
  iosBundleId: 'com.example.caregiver',  // ← Change to client's bundle ID
);
```

#### Web Section (Lines 43-51):
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyAOLnuJ736V3NU1VA1UId9K_0gg0JG1o54',  // ← From Firebase Console
  appId: '1:929615381650:web:2b8dd8de8bbf1689be124b',  // ← From Firebase Console
  messagingSenderId: '929615381650',  // ← From Firebase Console
  projectId: 'caregiver-cba18',  // ← From Firebase Console
  authDomain: 'caregiver-cba18.firebaseapp.com',  // ← From Firebase Console
  storageBucket: 'caregiver-cba18.firebasestorage.app',  // ← From Firebase Console
  measurementId: 'G-CJZ0BQKF3Z',  // ← From Firebase Console
);
```

#### macOS Section (Lines 70-77):
```dart
static const FirebaseOptions macos = FirebaseOptions(
  // Usually same as iOS values
  apiKey: 'AIzaSyAEkOQycup-JESgrmOqiVwJadjzwI2nbXo',  // ← Same as iOS
  appId: '1:929615381650:ios:e814e977cbca7ee0be124b',  // ← Same as iOS
  messagingSenderId: '929615381650',  // ← Same as iOS
  projectId: 'caregiver-cba18',  // ← Same as iOS
  storageBucket: 'caregiver-cba18.firebasestorage.app',  // ← Same as iOS
  iosBundleId: 'com.example.caregiver',  // ← Change to client's bundle ID
);
```

#### Windows Section (Lines 79-87):
```dart
static const FirebaseOptions windows = FirebaseOptions(
  // Usually same as Web values
  apiKey: 'AIzaSyAOLnuJ736V3NU1VA1UId9K_0gg0JG1o54',  // ← Same as Web
  appId: '1:929615381650:web:277478030da6f986be124b',  // ← From Firebase Console
  messagingSenderId: '929615381650',  // ← Same as Web
  projectId: 'caregiver-cba18',  // ← Same as Web
  authDomain: 'caregiver-cba18.firebaseapp.com',  // ← Same as Web
  storageBucket: 'caregiver-cba18.firebasestorage.app',  // ← Same as Web
  measurementId: 'G-RXV7C7NE4N',  // ← From Firebase Console
);
```

---

### Firebase.json Configuration

**File:** `firebase.json`

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
          "projectId": "caregiver-cba18",  // ← Change to client's project ID
          "appId": "1:929615381650:android:049fef3cfaec642bbe124b",  // ← Change to client's Android app ID
          "fileOutput": "android/app/google-services.json"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "caregiver-cba18",  // ← Change to client's project ID
          "configurations": {
            "android": "1:929615381650:android:049fef3cfaec642bbe124b",  // ← Change
            "ios": "1:929615381650:ios:e814e977cbca7ee0be124b",  // ← Change
            "macos": "1:929615381650:ios:e814e977cbca7ee0be124b",  // ← Change (usually same as iOS)
            "web": "1:929615381650:web:2b8dd8de8bbf1689be124b",  // ← Change
            "windows": "1:929615381650:web:277478030da6f986be124b"  // ← Change
          }
        }
      }
    }
  }
}
```

---

## 📋 Quick Values Reference

### Current Values (YOUR PROJECT):
```
Project ID: caregiver-cba18
Project Number: 929615381650
Android Package: com.example.caregiver
iOS Bundle ID: com.example.caregiver
macOS Bundle ID: com.example.caregiver

Android App ID: 1:929615381650:android:049fef3cfaec642bbe124b
iOS App ID: 1:929615381650:ios:e814e977cbca7ee0be124b
Web App ID: 1:929615381650:web:2b8dd8de8bbf1689be124b
Windows App ID: 1:929615381650:web:277478030da6f986be124b

Android API Key: AIzaSyAimfqIo6F8afMLQu4jkwKkyijxL6EEhrA
iOS API Key: AIzaSyAEkOQycup-JESgrmOqiVwJadjzwI2nbXo
Web API Key: AIzaSyAOLnuJ736V3NU1VA1UId9K_0gg0JG1o54

Storage Bucket: caregiver-cba18.firebasestorage.app
Auth Domain: caregiver-cba18.firebaseapp.com
```

### Client Values (TO FILL):
```
Project ID: _________________
Project Number: _________________
Android Package: _________________
iOS Bundle ID: _________________
macOS Bundle ID: _________________

Android App ID: _________________
iOS App ID: _________________
Web App ID: _________________
Windows App ID: _________________

Android API Key: _________________
iOS API Key: _________________
Web API Key: _________________

Storage Bucket: _________________
Auth Domain: _________________
```

---

## ✅ Migration Steps Summary

1. [ ] Client creates Firebase project
2. [ ] Client registers Android app → Download `google-services.json` → Replace file
3. [ ] Client registers iOS app → Download `GoogleService-Info.plist` → Replace file
4. [ ] Client registers Web app (if needed)
5. [ ] Update Android package name in `build.gradle.kts`
6. [ ] Update iOS bundle ID in Xcode
7. [ ] Update macOS bundle ID in Xcode
8. [ ] Run `flutterfire configure` to regenerate `firebase_options.dart`
9. [ ] Update `firebase.json` with client's project ID and app IDs
10. [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`
11. [ ] Deploy Firestore indexes: `firebase deploy --only firestore:indexes`
12. [ ] Test app build for Android
13. [ ] Test app build for iOS
14. [ ] Test user registration/login
15. [ ] Test Firestore data operations

---

## 🔍 Where to Find Client Values in Firebase Console

### Project ID & Project Number
- **Path:** Firebase Console → Project Settings → General tab
- **Fields:** "Project ID" and "Project number"

### App IDs & API Keys
- **Path:** Firebase Console → Project Settings → General tab → Your apps
- **For each app:** Click on the app → View config → Copy values

### Storage Bucket
- **Path:** Firebase Console → Storage → Files tab (shown at top)
- **Or:** Firebase Console → Project Settings → General → Your apps → Storage bucket

### Auth Domain
- **Path:** Firebase Console → Authentication → Settings
- **Field:** "Authorized domains" → Default domain

---

**Note:** This checklist should be used alongside `CLIENT_HANDOVER_GUIDE.md` for complete migration instructions.
