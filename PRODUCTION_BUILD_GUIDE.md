# Production Build Guide - Play Store & App Store

This guide will help you create production-ready builds for both Android (Play Store) and iOS (App Store).

---

## 📱 Android Production Build

### Step 1: Create Signing Keystore

**IMPORTANT:** You need to create a keystore file for signing your Android app. This keystore is required for Play Store uploads.

1. **Open terminal/command prompt** in the project root directory

2. **Run this command** (replace with your details):
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

3. **You'll be prompted for:**
   - Keystore password (remember this!)
   - Key password (can be same as keystore password)
   - Your name
   - Organizational unit
   - Organization name
   - City
   - State/Province
   - Country code (2 letters, e.g., NL for Netherlands)

4. **IMPORTANT:** Save the keystore password and key password securely. You'll need them for future updates!

### Step 2: Create key.properties File

Create a file `android/key.properties` with this content:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

**Replace:**
- `YOUR_KEYSTORE_PASSWORD` with the password you set for the keystore
- `YOUR_KEY_PASSWORD` with the password you set for the key

**Security Note:** Add `android/key.properties` to `.gitignore` to keep passwords secure!

### Step 3: Update build.gradle.kts

The build.gradle.kts file has been updated to use the keystore. Verify the signing configuration is correct.

### Step 4: Build Android App Bundle (AAB)

**For Google Play Store, you need an App Bundle (.aab file), not an APK:**

```bash
cd caregiver
flutter clean
flutter pub get
flutter build appbundle --release
```

**Output Location:** `build/app/outputs/bundle/release/app-release.aab`

This is the file you'll upload to Google Play Console.

### Alternative: Build APK (for testing or direct distribution)

If you need an APK instead:

```bash
flutter build apk --release
```

**Output Location:** `build/app/outputs/flutter-apk/app-release.apk`

---

## 🍎 iOS Production Build

### Prerequisites

1. **macOS computer** (required for iOS builds)
2. **Xcode** installed (latest version recommended)
3. **Apple Developer Account** ($99/year)
4. **App Store Connect** access

### Step 1: Open Project in Xcode

```bash
cd caregiver/ios
open Runner.xcworkspace
```

**Important:** Open `.xcworkspace`, NOT `.xcodeproj`!

### Step 2: Configure Signing & Capabilities

1. In Xcode, select **"Runner"** project in the left sidebar
2. Select **"Runner"** target
3. Go to **"Signing & Capabilities"** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** (your Apple Developer account)
6. Verify **Bundle Identifier** is: `com.je-dag-in-beeld.caregiver`

### Step 3: Configure App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Create a new app (if not already created):
   - App Name: "Je Dag in Beeld"
   - Primary Language: Dutch (or your preferred language)
   - Bundle ID: `com.je-dag-in-beeld.caregiver`
   - SKU: (unique identifier, e.g., `je-dag-in-beeld-001`)

### Step 4: Update Version & Build Number

The current version is `1.0.0+1` (defined in `pubspec.yaml`).

- **Version (1.0.0):** This is the user-facing version (e.g., 1.0.0, 1.1.0, 2.0.0)
- **Build Number (+1):** This must increment for each upload to App Store

To update version:
```yaml
# In pubspec.yaml
version: 1.0.0+1  # Change to 1.0.0+2 for next build, etc.
```

### Step 5: Build Archive

**Option A: Using Xcode (Recommended)**

1. In Xcode, select **"Any iOS Device"** or **"Generic iOS Device"** as the target
2. Go to **Product → Archive**
3. Wait for the archive to build
4. When complete, the **Organizer** window will open
5. Select your archive and click **"Distribute App"**
6. Choose **"App Store Connect"**
7. Follow the wizard to upload

**Option B: Using Flutter Command Line**

```bash
cd caregiver
flutter clean
flutter pub get
flutter build ipa --release
```

**Output Location:** `build/ios/ipa/caregiver.ipa`

Then upload the `.ipa` file using **Transporter** app or **Xcode Organizer**.

---

## 📋 Pre-Upload Checklist

### Android (Play Store)
- [ ] Keystore file created (`upload-keystore.jks`)
- [ ] `key.properties` file created with correct passwords
- [ ] App Bundle (.aab) built successfully
- [ ] App tested on physical device
- [ ] Version number set correctly
- [ ] App icon and screenshots ready
- [ ] Privacy policy URL ready (if required)
- [ ] Content rating completed

### iOS (App Store)
- [ ] Apple Developer account active
- [ ] App created in App Store Connect
- [ ] Bundle ID matches: `com.je-dag-in-beeld.caregiver`
- [ ] Signing configured in Xcode
- [ ] Archive built successfully
- [ ] App tested on physical device
- [ ] Version and build number set correctly
- [ ] App icon and screenshots ready
- [ ] Privacy policy URL ready (if required)
- [ ] App Store listing information ready

---

## 🔐 Security Notes

1. **Never commit these files to Git:**
   - `android/key.properties`
   - `android/app/upload-keystore.jks`
   - Add them to `.gitignore`

2. **Backup your keystore:**
   - Store `upload-keystore.jks` in a secure location
   - You'll need it for all future app updates
   - If lost, you cannot update your app on Play Store!

3. **Keep passwords secure:**
   - Store keystore passwords securely
   - Consider using a password manager

---

## 🚀 Quick Build Commands

### Android
```bash
# Clean and build App Bundle for Play Store
cd caregiver
flutter clean
flutter pub get
flutter build appbundle --release
```

### iOS
```bash
# Clean and build IPA
cd caregiver
flutter clean
flutter pub get
flutter build ipa --release
```

---

## 📞 Troubleshooting

### Android Build Issues

**Error: "Keystore file not found"**
- Make sure `upload-keystore.jks` is in `android/app/` directory
- Check `key.properties` has correct `storeFile` path

**Error: "Wrong password"**
- Verify passwords in `key.properties` match keystore passwords

### iOS Build Issues

**Error: "No signing certificate found"**
- Make sure you're logged into Xcode with your Apple Developer account
- Check "Automatically manage signing" is enabled
- Verify your Apple Developer account is active

**Error: "Bundle identifier already exists"**
- The bundle ID might be taken by another developer
- You'll need to use a different bundle ID or contact Apple

---

## 📝 Version Management

### For Future Updates

**Android:**
- Keep using the same keystore file
- Increment version in `pubspec.yaml` (e.g., `1.0.0+1` → `1.0.1+2`)
- Build new App Bundle

**iOS:**
- Increment build number in `pubspec.yaml` for each upload
- Version can stay same for patches (e.g., `1.0.0+1` → `1.0.0+2`)
- Version should increment for releases (e.g., `1.0.0+1` → `1.1.0+1`)

---

**Last Updated:** After production build setup
**Status:** Ready for production builds
