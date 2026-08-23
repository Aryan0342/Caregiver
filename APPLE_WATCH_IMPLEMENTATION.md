# Apple Watch companion implementation

## What is included

The iOS application now embeds a native SwiftUI watchOS companion target named
`CaregiverWatch`. It mirrors the existing Wear OS session experience:

- idle/connection screen;
- routine name and progress;
- current pictogram image and keyword;
- previous/next navigation by horizontal swipe;
- previous/next navigation with the Digital Crown;
- haptic feedback;
- phone-to-watch session start, index changes, and session end;
- watch-to-phone navigation with background delivery fallback.

The watch target bundle ID is
`com.je-dag-in-beeld.caregiver.watchkitapp`, paired with the iOS bundle
`com.je-dag-in-beeld.caregiver`. It targets watchOS 9.0 or newer.

## Runtime data flow

### iPhone to Apple Watch

1. `ClientModeSessionScreen` starts `WatchSessionService` after restoring any
   client progress.
2. Flutter creates a complete versioned snapshot containing the session ID,
   revision, active state, set name, index, step count, and pictograms.
3. Flutter calls the native `com.jedaginbeeld.wear` method channel.
4. `Runner/AppDelegate.swift` publishes the snapshot through
   `WCSession.updateApplicationContext`.
5. If Watch Connectivity is not activated yet, the snapshot is retained in
   `UserDefaults` and sent after activation.
6. `WatchApp/SessionStore.swift` receives and validates the latest snapshot.
7. SwiftUI automatically switches between `IdleView` and `SessionView`.

Every update is a complete snapshot. A delayed index update therefore cannot
erase the routine metadata or pictogram list.

### Apple Watch to iPhone

1. A swipe or Digital Crown movement updates the Watch UI optimistically.
2. The Watch sends a command containing a unique command ID, session ID,
   revision, action, and target index.
3. When the iPhone app is reachable, Watch Connectivity uses `sendMessage`.
4. Otherwise it queues the command with `transferUserInfo`.
5. `AppDelegate` retains the most recent command until Flutter consumes it.
6. Flutter deduplicates the command, rejects commands for old sessions, and
   invokes the existing next/previous callback.
7. The phone persists progress and sends the authoritative state back to the
   Watch.

The Apple Watch does not need Firebase credentials or direct Firestore access.
Nearby phone/watch synchronization also operates when Firestore is temporarily
unavailable.

## Files

- `ios/WatchApp/CaregiverWatchApp.swift` — watch entry point
- `ios/WatchApp/SessionStore.swift` — Watch Connectivity and state
- `ios/WatchApp/ContentView.swift` — active/idle routing
- `ios/WatchApp/SessionView.swift` — routine UI and navigation
- `ios/WatchApp/IdleView.swift` — inactive state
- `ios/WatchApp/Assets.xcassets` — accent color and watch icons
- `ios/Runner/AppDelegate.swift` — iPhone native bridge
- `lib/services/watch_session_service.dart` — shared Flutter protocol
- `ios/Runner.xcodeproj/project.pbxproj` — embedded watch target

## What still requires a Mac

Apple does not provide the watchOS SDK, simulator, signing tools, or App Store
archive tooling for Windows. This repository therefore includes a Codemagic
macOS workflow that compiles the Watch target and verifies it is embedded in
the iPhone archive. Before signing, CI also performs an unsigned watchOS
Simulator compilation. This catches Swift compiler errors, missing target
membership, invalid asset catalogs, and broken Xcode project settings without
requiring an Apple Watch or provisioning profile.

The `ios-production` workflow uses the existing Codemagic Developer Portal
integration to register `com.je-dag-in-beeld.caregiver.watchkitapp` when needed
and create/download its App Store provisioning profile. It retains the existing
Apple Distribution certificate and iPhone provisioning profile. Codemagic must
still have access to the `Steph van Hoffe` integration and the existing signing
identity references.

Alternatively, on a Mac with the current stable Xcode:

1. Install Flutter and CocoaPods.
2. From the repository root run `flutter pub get`.
3. From `ios/` run `pod install`.
4. Open `ios/Runner.xcworkspace`, not `Runner.xcodeproj`.
5. Select the `Runner` target and choose the Apple Developer team under
   Signing & Capabilities.
6. Select `CaregiverWatch` and choose the same team.
7. Confirm Xcode accepts the two bundle IDs. Change both consistently if the
   Apple Developer account uses a different registered prefix.
8. Select the `CaregiverWatch` scheme and a paired iPhone/Watch simulator.
9. Build and run the watch app, then run `Runner` on the paired iPhone.
10. Repeat the test using a physical iPhone and Apple Watch before release.

The final signing step requires access to the project's Apple Developer team.
Xcode may offer harmless project-setting upgrades when it first opens the
manually prepared target; review and commit those generated changes separately.

## Acceptance checklist

- Start a routine on the phone; the correct first pictogram appears on Watch.
- Advance and go back on the phone; Watch follows.
- Swipe and rotate the crown on Watch; phone follows.
- Close and reopen the Watch app; it restores the latest snapshot.
- Start navigation while the iPhone app is backgrounded; it is delivered when
  the app can process it.
- End the phone session; Watch returns to its idle screen.
- Disable network access while keeping devices paired; nearby sync still works.
- Validate layouts on small and large Watch simulators.
- Archive `Runner` and verify that `CaregiverWatch.app` is embedded.
