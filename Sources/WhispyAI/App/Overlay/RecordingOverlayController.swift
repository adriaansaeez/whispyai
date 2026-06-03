import AppKit
import SwiftUI

@MainActor
final class RecordingOverlayController {
    static let shared = RecordingOverlayController()

    enum OverlayState {
        case listening
        case processing(PromptContextKind?, isManual: Bool)

        var isProcessing: Bool {
            if case .processing = self { return true }
            return false
        }
    }

    private var panel: NSPanel?
    private var hostingView: NSHostingView<OverlayBadgeView>?

    func show(_ state: OverlayState) {
        let panel = panel ?? makePanel()
        let view = OverlayBadgeView(state: state)

        if let hostingView {
            hostingView.rootView = view
        } else {
            let newHostingView = NSHostingView(rootView: view)
            newHostingView.frame = NSRect(x: 0, y: 0, width: 250, height: 44)
            panel.contentView = newHostingView
            hostingView = newHostingView
        }

        positionPanelNearCursor(panel)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 250, height: 44),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        self.panel = panel
        return panel
    }

    private func positionPanelNearCursor(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let x = mouseLocation.x + 14
        let y = mouseLocation.y - panel.frame.height - 10
        panel.setFrameOrigin(NSPoint(x: x, y: max(y, 20)))
    }
}

private struct OverlayBadgeView: View {
    let state: RecordingOverlayController.OverlayState
    @State private var isContextVisible = false
    @State private var isSpinning = false

    var body: some View {
        HStack(spacing: 10) {
            if state.isProcessing {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 14, weight: .semibold))
                    .rotation3DEffect(.degrees(isSpinning ? 360 : 0), axis: (x: 0, y: 0, z: 1))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isSpinning)
                    .onAppear { isSpinning = true }
                    .onDisappear { isSpinning = false }
            } else {
                Image(systemName: "mic.fill")
                    .font(.system(size: 14, weight: .semibold))
            }

            if let contextName {
                Text(contextName)
                    .font(.system(size: 13, weight: .semibold))
                    .opacity(isContextVisible ? 1 : 0)
                    .offset(x: isContextVisible ? 0 : -4)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.22)) {
                            isContextVisible = true
                        }
                    }
                    .onChange(of: contextName) { _, _ in
                        isContextVisible = false
                        withAnimation(.easeOut(duration: 0.22)) {
                            isContextVisible = true
                        }
                    }
            } else {
                Text("Listening")
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(foregroundColor.opacity(0.14), lineWidth: 1)
        )
    }

    private var contextName: String? {
        switch state {
        case .listening:
            return nil
        case let .processing(kind, isManual):
            guard let kind else { return nil }
            return isManual ? "Manual: \(kind.displayName)" : kind.displayName
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .listening:
            return Color(red: 0.98, green: 0.84, blue: 0.84)
        case let .processing(kind, _):
            switch kind ?? .neutral {
            case .autodetect:
                return Color(red: 0.95, green: 0.91, blue: 0.84)
            case .email:
                return Color(red: 0.84, green: 0.92, blue: 1.0)
            case .chat:
                return Color(red: 0.87, green: 0.96, blue: 0.86)
            case .prompt:
                return Color(red: 0.93, green: 0.87, blue: 1.0)
            case .neutral:
                return Color(red: 0.95, green: 0.91, blue: 0.84)
            }
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .listening:
            return Color(red: 0.42, green: 0.08, blue: 0.08)
        case let .processing(kind, _):
            switch kind ?? .neutral {
            case .autodetect:
                return Color(red: 0.45, green: 0.31, blue: 0.14)
            case .email:
                return Color(red: 0.12, green: 0.33, blue: 0.54)
            case .chat:
                return Color(red: 0.15, green: 0.42, blue: 0.22)
            case .prompt:
                return Color(red: 0.37, green: 0.18, blue: 0.56)
            case .neutral:
                return Color(red: 0.45, green: 0.31, blue: 0.14)
            }
        }
    }
}
