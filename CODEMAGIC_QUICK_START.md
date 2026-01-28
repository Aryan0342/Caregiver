# Codemagic iOS Build - Quick Start Checklist

## ✅ Step-by-Step Quick Start

### 1. Codemagic Account Setup (5 minutes)
- [ ] Go to https://codemagic.io/ and sign up/login
- [ ] Connect your repository (GitHub/GitLab/Bitbucket)
- [ ] Add your Flutter app to Codemagic

### 2. Apple Developer Credentials (10 minutes)
- [ ] In Codemagic: Settings → Code signing → Add certificate
- [ ] Enter Apple Developer account email
- [ ] Generate App-Specific Password:
  - Go to https://appleid.apple.com/
  - Sign in → Security → App-Specific Passwords
  - Generate new password → Copy to Codemagic
- [ ] Select "Distribution certificate"
- [ ] Codemagic will auto-configure signing ✅

### 3. App Store Connect API Key (Optional - for auto-upload)
- [ ] Go to https://appstoreconnect.apple.com/
- [ ] Users and Access → Keys → App Store Connect API
- [ ] Generate new key → Download `.p8` file
- [ ] Note Key ID and Issuer ID
- [ ] In Codemagic: Settings → App Store Connect API
- [ ] Upload `.p8` file, enter Key ID and Issuer ID

### 4. Configuration Files (Already Created ✅)
- [x] `codemagic.yaml` - Created in project root
- [x] `GoogleService-Info.plist` - Already exists
- [x] Bundle ID configured: `com.je-dag-in-beeld.caregiver`

### 5. First Build (5 minutes)
- [ ] In Codemagic dashboard → Your app
- [ ] Click "Start new build"
- [ ] Select iOS platform
- [ ] Select Release configuration
- [ ] Click "Start new build"
- [ ] Wait for build to complete (~10-15 minutes)

### 6. Download & Upload (If not auto-uploaded)
- [ ] Download `.ipa` from Codemagic artifacts
- [ ] Upload to App Store Connect via Transporter or Xcode

---

## 📋 Project Configuration Summary

| Item | Value | Status |
|------|-------|--------|
| **Bundle ID** | `com.je-dag-in-beeld.caregiver` | ✅ Configured |
| **App Name** | Je Dag in Beeld | ✅ Configured |
| **Version** | 1.0.0+1 | ✅ Configured |
| **Firebase** | GoogleService-Info.plist | ✅ Present |
| **Code Signing** | Automatic | ✅ Configured |
| **Codemagic Config** | codemagic.yaml | ✅ Created |

---

## 🚨 Common Issues & Quick Fixes

### Build Fails: Code Signing
**Fix**: Verify Apple Developer credentials in Codemagic Settings

### Build Fails: CocoaPods
**Fix**: Already handled in codemagic.yaml with `pod repo update`

### Build Fails: Firebase
**Fix**: Ensure `ios/Runner/GoogleService-Info.plist` exists and is committed

### Build Succeeds but Can't Upload
**Fix**: Check App Store Connect API key configuration

---

## 📞 Need Help?

1. Check build logs in Codemagic dashboard
2. Review `CODEMAGIC_IOS_BUILD_GUIDE.md` for detailed steps
3. Codemagic docs: https://docs.codemagic.io/

---

**Estimated Total Time**: 30-45 minutes for first-time setup
