import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var appState: AppState

    private let sectionBackground = Color(red: 0.78, green: 0.86, blue: 0.97)

    var body: some View {
        Form {
            Toggle("Complete onboarding manually", isOn: $appState.hasCompletedOnboarding)
                .disabled(true)

            Text("The main settings flow will be implemented after the core dictation path is wired.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .scrollContentBackground(.hidden)
        .background(sectionBackground.ignoresSafeArea())
        .padding()
    }
}
