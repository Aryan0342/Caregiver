# Fix: Codemagic Building .app.zip Instead of .ipa

## 🔴 Issue
Build completed successfully but produced `Runner.app.zip` instead of `caregiver.ipa`

## ✅ What This Means

**`Runner.app.zip`** = iOS App Bundle (for simulator/testing)
- ❌ Cannot be uploaded to App Store
- ❌ Not properly code-signed for distribution
- ✅ Can be used for testing on simulators

**`caregiver.ipa`** = iOS App Archive (for App Store)
- ✅ Properly code-signed
- ✅ Ready for App Store submission
- ✅ This is what you need!

## 🔧 Solution

### Step 1: Verify You're Using the Correct Workflow

In Codemagic dashboard:
1. Click on **Build #2** (the successful one)
2. Check which **workflow** was used
3. It should say **"iOS Production Build"** or **"ios-production"**
4. If it says **"Default Workflow"**, that's the problem!

### Step 2: Ensure Code Signing is Configured

**In Codemagic Dashboard:**
1. Go to your app → **Settings** → **Code signing**
2. Verify you have:
   - ✅ Apple Developer account connected
   - ✅ Distribution certificate configured
   - ✅ Provisioning profile for `com.je-dag-in-beeld.caregiver`

**If code signing is NOT configured:**
- Codemagic will build `.app` bundle (simulator build)
- You need code signing to build `.ipa` (App Store build)

### Step 3: Start New Build with Correct Workflow

1. **In Codemagic Dashboard:**
   - Click **"Start new build"**
   - Select **iOS** platform
   - **IMPORTANT**: Select workflow **"ios-production"** (not "Default Workflow")
   - Ensure code signing credentials are selected
   - Click **"Start new build"**

### Step 4: Verify codemagic.yaml is Committed

Make sure your `codemagic.yaml` is committed to your repository:

```bash
cd D:\Apps\Caregiver\caregiver
git add codemagic.yaml
git commit -m "Add Codemagic iOS build configuration"
git push
```

### Step 5: Check Build Logs

After starting a new build:
1. Click on the build to view logs
2. Look for:
   - ✅ "Flutter build ipa" step
   - ✅ Code signing messages
   - ✅ "Built build/ios/ipa/caregiver.ipa"

If you see errors about:
- ❌ "No code signing certificate"
- ❌ "Provisioning profile not found"
- ❌ "Code signing failed"

→ You need to configure code signing in Codemagic Settings first!

---

## 📋 Updated codemagic.yaml (Ensure This is Used)

Your current `codemagic.yaml` looks correct. Make sure Codemagic is using it:

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
        - app_store_credentials  # ← This must be configured!
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
            --export-options-plist=/Users/builder/export_options.plist
    artifacts:
      - build/ios/ipa/*.ipa  # ← This should produce .ipa file
    publishing:
      email:
        recipients:
          - your-email@example.com  # ← Update with your email!
        notify:
          success: true
          failure: true
      app_store_connect:
        auth: integration
        submit_to_testflight: false
        submit_to_app_store: false
```

---

## ✅ Success Indicators

When build succeeds correctly, you should see:

**In Artifacts:**
- ✅ `caregiver.ipa` (or `app-release.ipa`)
- ❌ NOT `Runner.app.zip`

**In Build Logs:**
- ✅ "Building IPA..."
- ✅ "Code signing..."
- ✅ "Built build/ios/ipa/caregiver.ipa"

---

## 🎯 Quick Fix Checklist

- [ ] Code signing configured in Codemagic Settings
- [ ] `codemagic.yaml` committed to repository
- [ ] Using workflow **"ios-production"** (not "Default Workflow")
- [ ] App Store Connect API key configured (if auto-upload enabled)
- [ ] Build produces `.ipa` file (not `.app.zip`)

---

## 🆘 If Still Getting .app.zip

**Check 1: Workflow Selection**
- Make sure you're selecting **"ios-production"** workflow
- Not "Default Workflow" or any other workflow

**Check 2: Code Signing**
- Go to Settings → Code signing
- Verify Apple Developer credentials are added
- Verify certificate is "Distribution" type (not Development)

**Check 3: Build Logs**
- Check the "Flutter build ipa" step in logs
- Look for code signing errors
- Share error messages if any

---

**Next Step**: Configure code signing in Codemagic, then start a new build using the **"ios-production"** workflow!
