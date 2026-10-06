import Flutter
import UIKit
import UserNotifications
import WatchConnectivity

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
  private static let channelName = "com.jedaginbeeld.wear"
  private static let pendingNavigationKey = "pendingWatchNavigation"
  private static let pendingContextKey = "pendingWatchContext"

  private var watchChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Show step reminders (flutter_local_notifications) while the app is open.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: Self.channelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleWatchChannel(call, result: result)
      }
      watchChannel = channel
    } else {
      NSLog("[AppDelegate] Could not find FlutterViewController for watch channel")
    }

    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleWatchChannel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "sendToWear":
      guard let args = call.arguments as? [String: Any],
            let data = args["data"] as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "data is required", details: nil))
        return
      }
      guard WCSession.isSupported() else {
        result(FlutterError(code: "WATCH_UNSUPPORTED", message: "WatchConnectivity is unavailable", details: nil))
        return
      }

      let session = WCSession.default
      guard session.activationState == .activated else {
        UserDefaults.standard.set(data, forKey: Self.pendingContextKey)
        result(nil)
        return
      }

      do {
        // Application context is a latest-state channel. Flutter always sends a
        // complete session snapshot, so delayed delivery remains self-contained.
        try session.updateApplicationContext(data)
        UserDefaults.standard.removeObject(forKey: Self.pendingContextKey)
        result(nil)
      } catch {
        UserDefaults.standard.set(data, forKey: Self.pendingContextKey)
        result(nil)
      }

    case "isWatchAppInstalled":
      guard WCSession.isSupported() else {
        result(false)
        return
      }
      let session = WCSession.default
      result(
        session.activationState == .activated &&
        session.isPaired &&
        session.isWatchAppInstalled
      )

    case "getPendingWatchNavigation":
      let defaults = UserDefaults.standard
      let pending = defaults.dictionary(forKey: Self.pendingNavigationKey)
      if pending != nil {
        defaults.removeObject(forKey: Self.pendingNavigationKey)
      }
      result(pending)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    if let error = error {
      NSLog("[AppDelegate] WCSession activation failed: \(error.localizedDescription)")
    } else {
      NSLog("[AppDelegate] WCSession activated: \(activationState.rawValue)")
      flushPendingContext(to: session)
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
    NSLog("[AppDelegate] WCSession became inactive")
  }

  func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }

  func sessionWatchStateDidChange(_ session: WCSession) {
    publishReachability(session)
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    publishReachability(session)
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    receiveNavigation(message)
  }

  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    receiveNavigation(message)
    replyHandler(["accepted": true])
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    receiveNavigation(userInfo)
  }

  private func publishReachability(_ session: WCSession) {
    let available = session.activationState == .activated &&
      session.isPaired &&
      session.isWatchAppInstalled
    DispatchQueue.main.async { [weak self] in
      self?.watchChannel?.invokeMethod(
        "onReachabilityChanged",
        arguments: ["isReachable": session.isReachable, "isAvailable": available]
      )
    }
  }

  private func flushPendingContext(to session: WCSession) {
    guard session.activationState == .activated,
          let pending = UserDefaults.standard.dictionary(forKey: Self.pendingContextKey) else {
      return
    }
    do {
      try session.updateApplicationContext(pending)
      UserDefaults.standard.removeObject(forKey: Self.pendingContextKey)
    } catch {
      NSLog("[AppDelegate] Pending watch context failed: \(error.localizedDescription)")
    }
  }

  private func receiveNavigation(_ payload: [String: Any]) {
    guard payload["action"] is String else { return }

    // Keep the most recent command until Dart explicitly consumes it. This
    // covers commands delivered before the Flutter screen installs its handler.
    UserDefaults.standard.set(payload, forKey: Self.pendingNavigationKey)

    DispatchQueue.main.async { [weak self] in
      self?.watchChannel?.invokeMethod("onWatchNavigation", arguments: payload)
    }
  }
}
