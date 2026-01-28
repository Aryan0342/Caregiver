# Fix: Android Build Signed in Debug Mode Error

## 🔴 Error Message
"You uploaded an APK or Android App Bundle that was signed in debug mode. You need to sign your APK or Android App Bundle in release mode."

## ✅ Solution Steps

### Step 1: Verify Keystore Configuration

Your keystore is configured, but let's verify the path is correct:

**Current configuration:**
- Keystore file: `android/app/upload-keystore.jks` ✅ (exists)
- Key properties: `android/key.properties` ✅ (exists)

**Check the storeFile path in key.properties:**
The path `storeFile=../app/upload-keystore.jks` should be relative to where `build.gradle.kts` loads it from.

Since `build.gradle.kts` is at `android/app/build.gradle.kts` and loads `../key.properties` (which is `android/key.properties`), the storeFile path needs to be relative to the `android/app/` directory.

### Step 2: Fix key.properties Path (If Needed)

Open `android/key.properties` and verify/update the path:

```properties
storePassword=Stepha001.
keyPassword=Stepha001.
keyAlias=upload
storeFile=app/upload-keystore.jks
```

**Note:** The path should be `app/upload-keystore.jks` (not `../app/upload-keystore.jks`) because it's relative to the `android/` directory where `key.properties` is located.

### Step 3: Clean Previous Builds

```bash
cd D:\Apps\Caregiver\caregiver
flutter clean
```

### Step 4: Build Release App Bundle (CORRECT COMMAND)

**IMPORTANT:** Make sure you use `--release` flag:

```bash
flutter build appbundle --release
```

**DO NOT use:**
- ❌ `flutter build appbundle` (without --release)
- ❌ `flutter build apk` (unless you specifically need APK)
- ❌ `flutter build` (builds debug by default)

### Step 5: Verify the Build is Release-Signed

After building, verify the AAB file:

**Option A: Check build output**
Look for this in the build output:
```
✓ Built build/app/outputs/bundle/release/app-release.aab
```

**Option B: Verify signing (Windows PowerShell)**
```powershell
# Navigate to build directory
cd build\app\outputs\bundle\release

# Check if file exists
Test-Path app-release.aab
```

### Step 6: Upload to Google Play Console

1. Go to Google Play Console
2. Select your app
3. Go to **Production** → **Create new release**
4. Upload `build/app/outputs/bundle/release/app-release.aab`
5. The error should be gone! ✅

---

## 🔍 Troubleshooting

### Issue: Still getting debug signing error

**Check 1: Verify keystore is being used**

Look at the build output. You should see:
```
✓ Built build/app/outputs/bundle/release/app-release.aab
```

If you see warnings about debug signing, the keystore isn't being loaded.

**Check 2: Verify key.properties path**

The `storeFile` path in `key.properties` should be correct. Try:

```properties
storeFile=app/upload-keystore.jks
```

**Check 3: Verify build.gradle.kts**

Make sure the release build type uses the release signing config:

```kotlin
buildTypes {
    getByName("release") {
        if (keystorePropertiesFile.exists()) {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

**Check 4: Build command**

Always use:
```bash
flutter build appbundle --release
```

Never use:
```bash
flutter build appbundle  # Missing --release flag!
```

---

## 📋 Quick Fix Checklist

- [ ] Keystore file exists: `android/app/upload-keystore.jks`
- [ ] Key properties file exists: `android/key.properties`
- [ ] `storeFile` path in key.properties is correct: `app/upload-keystore.jks`
- [ ] Run `flutter clean` before building
- [ ] Use command: `flutter build appbundle --release`
- [ ] Verify output file: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Upload the `.aab` file (not `.apk`)

---

## 🎯 Correct Build Command

```bash
cd D:\Apps\Caregiver\caregiver
flutter clean
flutter pub get
flutter build appbundle --release
```

**Output file:** `build/app/outputs/bundle/release/app-release.aab`

Upload this `.aab` file to Google Play Console!

---

## ⚠️ Common Mistakes

1. **Building without `--release` flag** → Results in debug signing
2. **Using `flutter build apk` instead of `appbundle`** → Play Store prefers AAB
3. **Not running `flutter clean`** → May use cached debug build
4. **Wrong keystore path** → Falls back to debug signing
5. **Uploading APK instead of AAB** → Play Store prefers AAB format

---

## ✅ Success Indicators

When build succeeds, you should see:
- ✓ Build completes without errors
- ✓ Output: `Built build/app/outputs/bundle/release/app-release.aab`
- ✓ File size is reasonable (not tiny like debug builds)
- ✓ Upload to Play Console succeeds without signing errors

---

**Need more help?** Check the build logs for any warnings about signing configuration.
