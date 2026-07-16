
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        Group {
            if sessionStore.isActive &amp;&amp; sessionStore.totalSteps &gt; 0 {
                SessionView(
                    setName: sessionStore.setName,
                    currentIndex: sessionStore.currentIndex,
                    totalSteps: sessionStore.totalSteps,
                    steps: sessionStore.steps,
                    onSwipeNext: { sessionStore.sendNavigation(action: "next") },
                    onSwipePrevious: { sessionStore.sendNavigation(action: "prev") }
                )
            } else {
                IdleView()
            }
        }
    }
}
