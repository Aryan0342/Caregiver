
import Foundation
import WatchConnectivity
import Combine

struct WatchPictogramStep: Identifiable {
    let id: Int
    let keyword: String
    let imageUrl: String
}

final class SessionStore: NSObject, ObservableObject, WCSessionDelegate {

    @Published var isActive: Bool = false
    @Published var setName: String = ""
    @Published var currentIndex: Int = 0
    @Published var totalSteps: Int = 0
    @Published var steps: [WatchPictogramStep] = []

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendNavigation(action: String) {
        let payload: [String: Any] = ["action": action]
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                NSLog("[SessionStore] sendMessage failed (\(error.localizedDescription)), falling back to transferUserInfo")
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            NSLog("[SessionStore] Activation failed: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    // Mirrors android/wear/.../SessionRepository.kt's updateSession(action, data)
    // exactly. INDEX_CHANGE payloads only ever carry "action" and "currentIndex"
    // — they do NOT include setName/totalSteps/pictograms. Do not overwrite the
    // whole state on every payload or every swipe will wipe the pictogram list.
    private func apply(_ payload: [String: Any]) {
        let action = payload["action"] as? String ?? ""

        DispatchQueue.main.async {
            switch action {
            case "START":
                self.setName = payload["setName"] as? String ?? self.setName
                self.currentIndex = payload["currentIndex"] as? Int ?? 0
                self.totalSteps = payload["totalSteps"] as? Int ?? 0
                self.steps = Self.parseSteps(payload["pictograms"])
                self.isActive = true

            case "INDEX_CHANGE":
                if let index = payload["currentIndex"] as? Int {
                    self.currentIndex = index
                }

            case "END":
                self.isActive = false

            default:
                break
            }
        }
    }

    private static func parseSteps(_ raw: Any?) -&gt; [WatchPictogramStep] {
        guard let list = raw as? [[String: Any]] else { return [] }
        return list.compactMap { item in
            guard let index = item["index"] as? Int,
                  let keyword = item["keyword"] as? String,
                  let imageUrl = item["imageUrl"] as? String else { return nil }
            return WatchPictogramStep(id: index, keyword: keyword, imageUrl: imageUrl)
        }
    }
}
