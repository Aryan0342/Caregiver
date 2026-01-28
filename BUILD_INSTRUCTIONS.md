# How to Build APK Files for Your Caregiver App

## Quick Commands

### Build Release APK (Recommended for Distribution)
```bash
flutter build apk --release
```
**Output Location:** `build/app/outputs/flutter-apk/app-release.apk`

### Build Debug APK (For Testing Only)
```bash
flutter build apk --debug
```
**Output Location:** `build/app/outputs/flutter-apk/app-debug.apk`

### Build Split APKs by ABI (Smaller Size)
```bash
flutter build apk --split-per-abi
```
**Output:** Creates separate APKs for each architecture:
- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`

This reduces APK size as each APK only includes code for one architecture.

### Build App Bundle (For Google Play Store)
```bash
flutter build appbundle --release
```
**Output Location:** `build/app/outputs/bundle/release/app-release.aab`

## Prerequisites

1. **Flutter SDK** installed and configured
2. **Android SDK** installed (comes with Android Studio)
3. **Java JDK** (version 17 is configured in your project)

## Current Build Configuration

Your app is currently configured to use **debug signing** for release builds (line 40 in `build.gradle.kts`). This is fine for testing, but for production releases you should:

### Setting Up Release Signing (For Production)

1. Create a keystore file:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` file:
   ```
   storePassword=<password from previous step>
   keyPassword=<password from previous step>
   keyAlias=upload
   storeFile=<location of the keystore file, e.g., /Users/<user name>/upload-keystore.jks>
   ```

3. Update `android/app/build.gradle.kts` to use the keystore for signing.

## Troubleshooting

If you encounter Kotlin compilation errors (like the warnings you saw), try:

1. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Delete build folder:**
   ```bash
   rm -rf build/  # Linux/Mac
   rmdir /s build  # Windows
   ```

3. **Invalidate caches** if using Android Studio

## Installing the APK

After building, you can install the APK on an Android device:

```bash
flutter install
```

Or manually via:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## File Size Optimization

Your current APK is 52.6MB. To reduce size:

1. Use `--split-per-abi` flag (creates smaller, architecture-specific APKs)
2. Enable code shrinking and obfuscation in `build.gradle.kts`
3. Remove unused assets and dependencies
4. Use App Bundle format for Play Store distribution
