
import SwiftUI

struct SessionView: View {
    let setName: String
    let currentIndex: Int
    let totalSteps: Int
    let steps: [WatchPictogramStep]
    let onSwipeNext: () -&gt; Void
    let onSwipePrevious: () -&gt; Void

    private var currentStep: WatchPictogramStep? {
        guard currentIndex &gt;= 0 &amp;&amp; currentIndex &lt; steps.count else { return nil }
        return steps[currentIndex]
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(currentIndex + 1) / \(totalSteps)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 2)

            if let step = currentStep {
                AsyncImage(url: URL(string: step.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.secondary)
                            .padding(20)
                    default:
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 2)

                Text(step.keyword)
                    .font(.system(size: 11, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 2)
            } else {
                Text("No pictogram")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 2)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    guard abs(horizontal) &gt; abs(vertical) else { return }
                    if horizontal &lt; -20 {
                        onSwipeNext()
                    } else if horizontal &gt; 20 {
                        onSwipePrevious()
                    }
                }
        )
    }
}
