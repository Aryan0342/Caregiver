import SwiftUI

struct IdleView: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.blue)

            Text("Je Dag in Beeld")
                .font(.headline)

            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
