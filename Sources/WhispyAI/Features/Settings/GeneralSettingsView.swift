import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Section {
                Button("Relaunch Onboarding") {
                    SettingsStore().setHasCompletedOnboarding(false)
                    appState.hasCompletedOnboarding = false
                    OnboardingWindowController.shared.show(appState: appState)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.bright)
            } header: {
                Label("Onboarding", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.white)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding()
    }
}