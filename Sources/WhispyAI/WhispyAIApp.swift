import KeyboardShortcuts
import SwiftUI

@main
struct WhispyAIApp: App {
    @State private var appState = AppState()

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleDictation) {
            Task { @MainActor in
                AppState.shared?.toggleDictation()
            }
        }
        KeyboardShortcuts.onKeyUp(for: .cycleContextMode) {
            Task { @MainActor in
                AppState.shared?.cycleContextMode()
            }
        }
    }

    var body: some Scene {
        MenuBarExtra("WhispyAI", systemImage: appState.menuBarIconName) {
            MenuBarView(appState: appState)
        }
        .menuBarExtraStyle(.menu)
    }
}

extension KeyboardShortcuts.Name {
    static let toggleDictation = Self("toggleDictation", default: .init(.space, modifiers: [.option]))
    static let cycleContextMode = Self("cycleContextMode", default: .init(.c, modifiers: [.option, .shift]))
}
