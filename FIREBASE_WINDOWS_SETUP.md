# Firebase Windows Setup Guide

## Current Issue
The Firebase C++ SDK extraction is failing during the Windows build process, causing CMake errors about missing include directories.

## Temporary Solution (Current State)
Firebase has been temporarily disabled to allow the app to build and run on Windows. The app will work without Firebase functionality.

## To Re-enable Firebase on Windows

### Option 1: Try Building Again (Recommended First Step)
Sometimes the Firebase SDK extraction works on retry:

```powershell
flutter clean
flutter pub get
flutter run -d windows
```

### Option 2: Manual Firebase SDK Setup
If automatic extraction continues to fail:

1. **Download Firebase C++ SDK manually:**
   - Visit: https://firebase.google.com/download/cpp
   - Download the latest Windows SDK
   - Extract to: `build/windows/x64/extracted/firebase_cpp_sdk_windows/`

2. **Ensure the directory structure is:**
   ```
   build/windows/x64/extracted/firebase_cpp_sdk_windows/
   ├── CMakeLists.txt
   ├── include/
   │   └── firebase/
   └── libs/
       └── windows/
   ```

3. **Update CMakeLists.txt:**
   - The Firebase SDK's CMakeLists.txt requires CMake 3.5+
   - Run `.\fix_firebase_cmake.ps1` if needed

### Option 3: Use Firebase Only on Other Platforms
If Windows Firebase support isn't critical, you can:
- Keep Firebase enabled for Android/iOS/Web
- Use conditional initialization in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only initialize Firebase on supported platforms
  if (!kIsWeb && !Platform.isWindows) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  runApp(const MyApp());
}
```

## Re-enabling Firebase

1. **Uncomment in `pubspec.yaml`:**
   ```yaml
   dependencies:
     firebase_core: ^4.3.0
   ```

2. **Uncomment in `lib/main.dart`:**
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     runApp(const MyApp());
   }
   ```

3. **Run:**
   ```powershell
   flutter pub get
   flutter clean
   flutter run -d windows
   ```

## Known Issues
- Firebase Windows support is still experimental
- Some Firebase features may not work on Windows
- CMake version compatibility issues (requires CMake 3.5+)

## Resources
- [FlutterFire Windows Documentation](https://firebase.flutter.dev/docs/overview)
- [Firebase C++ SDK](https://firebase.google.com/docs/cpp/setup)
- [FlutterFire GitHub Issues](https://github.com/firebase/flutterfire/issues)
