import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Toggle("Complete onboarding manually", isOn: $appState.hasCompletedOnboarding)
                .disabled(true)

            Text("The main settings flow will be implemented after the core dictation path is wired.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
