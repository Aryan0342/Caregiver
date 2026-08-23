import SwiftUI

struct SessionView: View {
    let setName: String
    let currentIndex: Int
    let totalSteps: Int
    let steps: [WatchPictogramStep]
    let onNext: () -> Void
    let onPrevious: () -> Void

    private var currentStep: WatchPictogramStep? {
        guard currentIndex >= 0 && currentIndex < steps.count else { return nil }
        return steps[currentIndex]
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(setName)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text("\(currentIndex + 1)/\(totalSteps)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let step = currentStep {
                AsyncImage(url: step.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholder
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(step.keyword)
                    .font(.caption.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            } else {
                placeholder
            }
        }
        .padding(.horizontal, 3)
        .focusable(true)
        .digitalCrownRotation(
            Binding(
                get: { Double(currentIndex) },
                set: { value in
                    let target = Int(value.rounded())
                    if target > currentIndex { onNext() }
                    if target < currentIndex { onPrevious() }
                }
            ),
            from: 0,
            through: Double(max(totalSteps - 1, 0)),
            by: 1,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width < -20 {
                        onNext()
                    } else if value.translation.width > 20 {
                        onPrevious()
                    }
                }
        )
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
            .padding(24)
    }
}
