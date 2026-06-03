import SwiftUI

struct SettingsRootView: View {
    @Bindable var appState: AppState
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        TabView {
            GeneralSettingsView(appState: appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ProviderSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }

            HotkeySettingsView(appState: appState, viewModel: viewModel)
                .tabItem {
                    Label("Hotkey", systemImage: "keyboard")
                }
        }
        .scenePadding()
        .frame(minWidth: 560, minHeight: 380)
        .background(AppColors.backgroundGradient.ignoresSafeArea())
        .onAppear {
            viewModel.load()
        }
    }
}