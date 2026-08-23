import Combine
import Foundation
import WatchConnectivity
import WatchKit

struct WatchPictogramStep: Identifiable, Equatable {
    let id: Int
    let keyword: String
    let imageURL: URL?
}

final class SessionStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var isActive = false
    @Published private(set) var sessionID = ""
    @Published private(set) var setName = ""
    @Published private(set) var currentIndex = 0
    @Published private(set) var totalSteps = 0
    @Published private(set) var steps: [WatchPictogramStep] = []
    @Published private(set) var connectionMessage = "Connecting to iPhone…"

    private var revision = 0

    override init() {
        super.init()
        guard WCSession.isSupported() else {
            connectionMessage = "This watch does not support phone sync."
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func navigate(by offset: Int) {
        guard isActive, totalSteps > 0 else { return }
        let target = min(max(currentIndex + offset, 0), totalSteps - 1)
        guard target != currentIndex else { return }

        currentIndex = target
        WKInterfaceDevice.current().play(.click)

        let payload: [String: Any] = [
            "commandId": UUID().uuidString,
            "action": offset > 0 ? "next" : "prev",
            "targetIndex": target,
            "sessionId": sessionID,
            "revision": revision
        ]
        sendNavigation(payload)
    }

    private func sendNavigation(_ payload: [String: Any]) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                NSLog("[SessionStore] Immediate navigation failed: \(error.localizedDescription)")
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
            DispatchQueue.main.async {
                self.connectionMessage = "Could not connect to iPhone."
            }
            NSLog("[SessionStore] Activation failed: \(error.localizedDescription)")
            return
        }

        DispatchQueue.main.async {
            self.connectionMessage = session.isCompanionAppInstalled
                ? "Start a session on your iPhone."
                : "Install Je Dag in Beeld on your iPhone."
        }

        let initialContext = session.receivedApplicationContext
        if !initialContext.isEmpty {
            apply(initialContext)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    private func apply(_ payload: [String: Any]) {
        guard Self.number(payload["schemaVersion"]) == 1 else {
            NSLog("[SessionStore] Ignoring unsupported session payload")
            return
        }

        let incomingRevision = Self.number(payload["revision"]) ?? 0
        let incomingSessionID = payload["sessionId"] as? String ?? ""

        DispatchQueue.main.async {
            if incomingSessionID == self.sessionID && incomingRevision < self.revision {
                return
            }

            self.sessionID = incomingSessionID
            self.revision = incomingRevision
            self.isActive = payload["isActive"] as? Bool ?? false
            self.setName = payload["setName"] as? String ?? ""
            self.totalSteps = max(Self.number(payload["totalSteps"]) ?? 0, 0)
            self.steps = Self.parseSteps(payload["pictograms"])

            let requestedIndex = Self.number(payload["currentIndex"]) ?? 0
            let upperBound = max(min(self.totalSteps, self.steps.count) - 1, 0)
            self.currentIndex = min(max(requestedIndex, 0), upperBound)

            if !self.isActive {
                self.connectionMessage = "Start a session on your iPhone."
            }
        }
    }

    private static func parseSteps(_ raw: Any?) -> [WatchPictogramStep] {
        guard let list = raw as? [[String: Any]] else { return [] }
        return list.compactMap { item in
            guard let index = number(item["index"]),
                  let keyword = item["keyword"] as? String else { return nil }
            let urlString = item["imageUrl"] as? String ?? ""
            return WatchPictogramStep(
                id: index,
                keyword: keyword,
                imageURL: URL(string: urlString)
            )
        }
        .sorted { $0.id < $1.id }
    }

    private static func number(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        return nil
    }
}
