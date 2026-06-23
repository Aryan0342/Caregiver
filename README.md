
# PHONE (Flutter + Firebase Auth)
├── User starts sequence in ClientModeSessionScreen
├── WatchSessionService.startSession() called
│   ├── Writes to Firestore: watch_sessions/{userId}
│   └── Sends via DataLayer: PutDataMapRequest to /watch_session
│
ANDROID NATIVE (phone side - MainActivity.kt)
├── MethodChannel handler: 'com.jedaginbeeld.wear'
├── Receives 'sendToWear' calls from Flutter
└── Pushes PutDataMapRequest to paired watch
│
WEAROS APP
├── MainActivity → WearApp composable
├── WearDataReceiver (DataClient.OnDataChangedListener)
│   ├── Listens on path: /watch_session
│   ├── Parses action: START / INDEX_CHANGE / END
│   └── Updates SessionRepository (StateFlow)
├── SessionViewModel observes SessionRepository
├── WearApp renders based on state.isActive
│   ├── true → SessionScreen(state)
│   └── false → IdleScreen()
└── SessionScreen has Prev/Next buttons
    └── Sends MessageClient back to phone: /navigation {action: "next"/"prev"}
│
ANDROID NATIVE (phone side - again)
└── MessageClient listener → calls Flutter MethodChannel back
    └── Flutter updates _currentStepIndex → calls updateIndex()
caregiver

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
