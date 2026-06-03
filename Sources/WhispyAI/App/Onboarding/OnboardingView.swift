import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to WhispyAI")
                .font(.largeTitle)
            Text("Speak naturally and let AI improve your text before it is inserted where you are typing.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 320)
    }
}
