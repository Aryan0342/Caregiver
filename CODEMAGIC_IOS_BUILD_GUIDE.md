# Complete Codemagic iOS Build Guide

## 📋 Project Analysis Summary

### ✅ What's Already Configured

1. **Bundle Identifier**: `com.je-dag-in-beeld.caregiver` ✅
2. **App Display Name**: "Je Dag in Beeld" ✅
3. **Version**: 1.0.0+1 (from pubspec.yaml) ✅
4. **Firebase Configuration**: `GoogleService-Info.plist` present ✅
5. **Code Signing Style**: Automatic ✅
6. **iOS Deployment Target**: Configured ✅
7. **Info.plist**: Properly configured with all required keys ✅

### 📦 Dependencies & Requirements

- **Flutter SDK**: ^3.10.7
- **Firebase**: Core, Auth, Firestore
- **Other Dependencies**: Cloudinary, HTTP, Path Provider, Cached Network Image, etc.
- **Minimum iOS Version**: Checked in project.pbxproj (typically iOS 12.0+)

---

## 🚀 Complete Codemagic Setup Guide

### Step 1: Create Codemagic Account & Connect Repository

1. **Sign up/Login to Codemagic**
   - Go to https://codemagic.io/
   - Sign up with GitHub/GitLab/Bitbucket (wherever your code is hosted)

2. **Add Your App**
   - Click "Add application"
   - Select your repository (`Caregiver` project)
   - Choose **Flutter** as the project type

---

### Step 2: Configure iOS Code Signing

#### Option A: Automatic Code Signing (Recommended for First Time)

1. **In Codemagic Dashboard:**
   - Go to your app → **Settings** → **Code signing**
   - Click **Add code signing certificate**

2. **Upload Apple Developer Credentials:**
   - **Apple ID**: Your Apple Developer account email
   - **App-specific password**: 
     - Go to https://appleid.apple.com/
     - Sign in → App-Specific Passwords → Generate new password
     - Copy and paste into Codemagic

3. **Select Certificate Type:**
   - Choose **Distribution certificate** (for App Store)
   - Codemagic will automatically:
     - Create/download certificates
     - Generate provisioning profiles
     - Configure signing

#### Option B: Manual Certificate Upload (If you already have certificates)

1. **Export from Keychain (macOS):**
   ```bash
   # Export certificate
   security find-identity -v -p codesigning
   # Note the certificate ID, then export
   ```

2. **Upload to Codemagic:**
   - Upload `.p12` certificate file
   - Upload `.mobileprovision` provisioning profile
   - Enter certificate password

---

### Step 3: Create Codemagic Configuration File

Create `codemagic.yaml` in your project root (`D:\Apps\Caregiver\caregiver\codemagic.yaml`):

```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
      groups:
        - app_store_credentials # Reference to your code signing credentials
      vars:
        APP_ID: com.je-dag-in-beeld.caregiver
        BUNDLE_ID: com.je-dag-in-beeld.caregiver
        XCODE_WORKSPACE: "ios/Runner.xcworkspace"
        XCODE_SCHEME: "Runner"
        FLUTTER_BUILD_MODE: "release"
    scripts:
      - name: Get Flutter dependencies
        script: |
          flutter pub get
      - name: Install CocoaPods dependencies
        script: |
          cd ios && pod install && cd ..
      - name: Flutter build ipa
        script: |
          flutter build ipa \
            --release \
            --export-options-plist=/Users/builder/export_options.plist
    artifacts:
      - build/ios/ipa/*.ipa
      - /tmp/xcodebuild_logs/*.log
      - flutter_drive.log
    publishing:
      email:
        recipients:
          - your-email@example.com
        notify:
          success: true
          failure: false
      app_store_connect:
        auth: integration
        
        # Submit to TestFlight (optional)
        submit_to_testflight: false
        
        # Submit to App Store (set to true for production)
        submit_to_app_store: false
        
        # Beta groups for TestFlight (optional)
        beta_groups:
          - group name 1
          - group name 2
```

---

### Step 4: Configure Export Options Plist

Create `export_options.plist` in your project root (`D:\Apps\Caregiver\caregiver\export_options.plist`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>destination</key>
    <string>upload</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.je-dag-in-beeld.caregiver</key>
        <string>YOUR_PROVISIONING_PROFILE_NAME</string>
    </dict>
</dict>
</plist>
```

**Note**: Codemagic can auto-generate this, but you can customize it if needed.

---

### Step 5: Set Up App Store Connect API Key (For Automatic Upload)

1. **Create API Key in App Store Connect:**
   - Go to https://appstoreconnect.apple.com/
   - Users and Access → Keys → App Store Connect API
   - Click "+" to generate new key
   - Download `.p8` key file
   - Note the **Key ID** and **Issuer ID**

2. **Add to Codemagic:**
   - Go to **Settings** → **App Store Connect API**
   - Upload `.p8` key file
   - Enter **Key ID**
   - Enter **Issuer ID**
   - Save

---

### Step 6: Configure Environment Variables (Optional but Recommended)

In Codemagic Dashboard → Your App → **Environment variables**:

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `APP_ID` | `com.je-dag-in-beeld.caregiver` | Bundle identifier |
| `APP_NAME` | `Je Dag in Beeld` | App display name |
| `FLUTTER_BUILD_MODE` | `release` | Build mode |

---

### Step 7: First Build Configuration

1. **In Codemagic Dashboard:**
   - Go to your app
   - Click **Start new build**
   - Select **iOS** platform
   - Select **Release** configuration
   - Choose your workflow (or use the default)

2. **Before Starting Build:**
   - ✅ **Bundle ID**: Already verified - `com.je-dag-in-beeld.caregiver` ✅
   - ✅ **GoogleService-Info.plist**: Already verified - exists in `ios/Runner/` ✅
   - ⚠️ **Code signing credentials**: **YOU MUST CONFIGURE THIS MANUALLY** in Codemagic dashboard (Settings → Code signing)

---

### Step 8: Build Process

Codemagic will automatically:

1. ✅ Clone your repository
2. ✅ Install Flutter dependencies (`flutter pub get`)
3. ✅ Install CocoaPods (`pod install`)
4. ✅ Build iOS app (`flutter build ipa`)
5. ✅ Code sign with your certificates
6. ✅ Generate `.ipa` file
7. ✅ (Optional) Upload to App Store Connect

---

### Step 9: Download & Verify Build

1. **After Build Completes:**
   - Go to **Builds** tab
   - Click on completed build
   - Download `.ipa` file from **Artifacts** section

2. **Verify IPA:**
   ```bash
   # Check IPA contents (optional)
   unzip -l your-app.ipa
   ```

---

### Step 10: Upload to App Store Connect (If Not Automatic)

If you didn't enable automatic upload:

1. **Download IPA from Codemagic**

2. **Upload via Transporter App (macOS):**
   - Download Transporter from Mac App Store
   - Open Transporter
   - Drag `.ipa` file
   - Click **Deliver**

3. **Or via Xcode:**
   - Open Xcode → Window → Organizer
   - Click **Distribute App**
   - Select **App Store Connect**
   - Choose your `.ipa` file

---

## 🔧 Troubleshooting Common Issues

### Issue 1: Code Signing Errors

**Error**: `No signing certificate found`

**Solution**:
- Verify Apple Developer account is connected in Codemagic
- Check that Distribution certificate is uploaded
- Ensure bundle ID matches: `com.je-dag-in-beeld.caregiver`

### Issue 2: Provisioning Profile Mismatch

**Error**: `Provisioning profile doesn't match bundle identifier`

**Solution**:
- In Codemagic, regenerate provisioning profiles
- Ensure bundle ID in Xcode project matches: `com.je-dag-in-beeld.caregiver`

### Issue 3: CocoaPods Installation Fails

**Error**: `pod install` fails

**Solution**:
- Add this to your `codemagic.yaml`:
  ```yaml
  scripts:
    - name: Install CocoaPods dependencies
      script: |
        cd ios
        pod repo update
        pod install --repo-update
        cd ..
  ```

### Issue 4: Firebase Configuration Missing

**Error**: `GoogleService-Info.plist not found`

**Solution**:
- Ensure `ios/Runner/GoogleService-Info.plist` exists
- Verify it's not in `.gitignore` (should be committed)
- Check file path is correct

### Issue 5: Version Number Issues

**Error**: `Invalid version number`

**Solution**:
- Check `pubspec.yaml`: `version: 1.0.0+1`
- First number (1.0.0) = Marketing version
- Second number (+1) = Build number
- Increment build number for each build

---

## 📝 Complete codemagic.yaml Template

Here's a complete, production-ready `codemagic.yaml`:

```yaml
workflows:
  ios-production:
    name: iOS Production Build
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
      groups:
        - app_store_credentials
      vars:
        APP_ID: com.je-dag-in-beeld.caregiver
        BUNDLE_ID: com.je-dag-in-beeld.caregiver
    scripts:
      - name: Get Flutter dependencies
        script: |
          flutter pub get
      - name: Install CocoaPods dependencies
        script: |
          cd ios
          pod repo update
          pod install --repo-update
          cd ..
      - name: Flutter build ipa
        script: |
          flutter build ipa \
            --release \
            --export-options-plist=/Users/builder/export_options.plist \
            --build-name=$(FLUTTER_BUILD_NAME) \
            --build-number=$(FLUTTER_BUILD_NUMBER)
    artifacts:
      - build/ios/ipa/*.ipa
    publishing:
      email:
        recipients:
          - your-email@example.com
        notify:
          success: true
          failure: true
      app_store_connect:
        auth: integration
        submit_to_testflight: false
        submit_to_app_store: false
```

---

## ✅ Pre-Build Checklist

Before running your first build, verify:

- [ ] Codemagic account created and repository connected
- [ ] Apple Developer account credentials added to Codemagic
- [ ] Bundle ID configured: `com.je-dag-in-beeld.caregiver`
- [ ] `GoogleService-Info.plist` exists in `ios/Runner/`
- [ ] `codemagic.yaml` created in project root
- [ ] Version number updated in `pubspec.yaml` (if needed)
- [ ] App Store Connect API key configured (for auto-upload)
- [ ] Code signing certificates configured in Codemagic

---

## 🎯 Quick Start Commands

### Create codemagic.yaml
```bash
cd D:\Apps\Caregiver\caregiver
# Copy the template above and save as codemagic.yaml
```

### Test Locally (if you have macOS)
```bash
cd D:\Apps\Caregiver\caregiver
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ipa --release
```

---

## 📚 Additional Resources

- **Codemagic Documentation**: https://docs.codemagic.io/
- **Flutter iOS Deployment**: https://docs.flutter.dev/deployment/ios
- **App Store Connect**: https://appstoreconnect.apple.com/
- **Apple Developer Portal**: https://developer.apple.com/

---

## 🆘 Support

If you encounter issues:

1. Check Codemagic build logs
2. Verify all credentials are correct
3. Ensure bundle ID matches everywhere
4. Check Firebase configuration
5. Review Codemagic documentation

---

**Last Updated**: Based on current project structure analysis
**Project**: Je Dag in Beeld (Caregiver App)
**Bundle ID**: `com.je-dag-in-beeld.caregiver`
**Version**: 1.0.0+1
