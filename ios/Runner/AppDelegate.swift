
import Flutter
import UIKit
import WatchConnectivity

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {

  private var watchChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -&gt; Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.jedaginbeeld.wear",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] (call, result) in
        self?.handleWatchChannel(call, result: result)
      }
      self.watchChannel = channel
    } else {
      NSLog("[AppDelegate] Could not find FlutterViewController to attach watch channel")
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
      guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
        result(FlutterError(code: "WEAR_ERROR", message: "WCSession not activated", details: nil))
        return
      }
      do {
        try WCSession.default.updateApplicationContext(data)
        result(nil)
      } catch {
        result(FlutterError(code: "WEAR_ERROR", message: error.localizedDescription, details: nil))
      }

    case "isWatchAppInstalled":
      guard WCSession.isSupported() else {
        result(false)
        return
      }
      result(WCSession.default.isCompanionAppInstalled)

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
      NSLog("[AppDelegate] WCSession activated, state=\(activationState.rawValue)")
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
    NSLog("[AppDelegate] WCSession became inactive")
  }

  func sessionDidDeactivate(_ session: WCSession) {
    NSLog("[AppDelegate] WCSession deactivated, reactivating")
    WCSession.default.activate()
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    DispatchQueue.main.async { [weak self] in
      self?.watchChannel?.invokeMethod(
        "onReachabilityChanged",
        arguments: ["isReachable": session.isReachable]
      )
    }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    forwardNavigation(message)
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    forwardNavigation(userInfo)
  }

  private func forwardNavigation(_ payload: [String: Any]) {
    guard let action = payload["action"] as? String else { return }
    DispatchQueue.main.async { [weak self] in
      self?.watchChannel?.invokeMethod("onWatchNavigation", arguments: ["action": action])
    }
  }
}
