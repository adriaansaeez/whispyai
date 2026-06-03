import SwiftUI

struct SettingsRootView: View {
    @Bindable var appState: AppState
    @State private var viewModel = SettingsViewModel()

    private let tabBackground = Color(red: 0.88, green: 0.93, blue: 1.0)
    private let sectionBackground = Color(red: 0.78, green: 0.86, blue: 0.97)

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
        .background(tabBackground.ignoresSafeArea())
        .onAppear {
            viewModel.load()
        }
    }
}
