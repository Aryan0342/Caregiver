
import SwiftUI

struct IdleView: View {
    var body: some View {
        Text("Start a session on your phone")
            .font(.system(size: 15, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundColor(.primary)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
