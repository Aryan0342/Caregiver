import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        Group {
            if sessionStore.isActive && sessionStore.totalSteps > 0 {
                SessionView(
                    setName: sessionStore.setName,
                    currentIndex: sessionStore.currentIndex,
                    totalSteps: sessionStore.totalSteps,
                    steps: sessionStore.steps,
                    onNext: { sessionStore.navigate(by: 1) },
                    onPrevious: { sessionStore.navigate(by: -1) }
                )
            } else {
                IdleView(message: sessionStore.connectionMessage)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: sessionStore.isActive)
    }
}
