import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Section("Onboarding") {
                Button("Relaunch Onboarding") {
                    SettingsStore().setHasCompletedOnboarding(false)
                    appState.hasCompletedOnboarding = false
                    OnboardingWindowController.shared.show(appState: appState)
                }
            }
        }
        .padding()
    }
}
