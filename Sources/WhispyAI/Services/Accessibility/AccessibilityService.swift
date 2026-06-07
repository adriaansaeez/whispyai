import AppKit
@preconcurrency import ApplicationServices

@MainActor
final class AccessibilityService: AccessibilityServicing, @unchecked Sendable {
    private var capturedApplication: NSRunningApplication?
    private var capturedElement: AXUIElement?

    func checkPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func requestPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func captureInsertionTarget() throws {
        guard checkPermission() else {
            requestPermission()
            throw WhispyError.accessibilityPermissionDenied
        }

        let target = try resolveCurrentTarget()
        capturedApplication = target.application
        capturedElement = target.element
        DebugLogger.log("captured target app=\(target.application.localizedName ?? "unknown") pid=\(target.application.processIdentifier)")
    }

    func insert(text: String) async throws {
        guard checkPermission() else {
            requestPermission()
            throw WhispyError.accessibilityPermissionDenied
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            DebugLogger.log("insert aborted: empty trimmed text")
            throw WhispyError.insertionFailed
        }

        let target = try resolvePreferredTarget()
        let uiElement = target.element
        DebugLogger.log("using insertion target app=\(target.application.localizedName ?? "unknown") pid=\(target.application.processIdentifier)")

        DebugLogger.log("using pasteboard insertion as primary strategy")
        do {
            try pasteUsingPasteboard(trimmedText, into: target.application)
            DebugLogger.log("pasteboard insertion dispatched")
            return
        } catch {
            DebugLogger.log("pasteboard insertion failed; falling back to AX: \(error.localizedDescription)")
        }

        var selectedRange: CFTypeRef?
        let rangeError = AXUIElementCopyAttributeValue(
            uiElement,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRange
        )
        DebugLogger.log("selected text range lookup result=\(rangeError.rawValue)")

        let inserted: Bool
        if rangeError == .success {
            inserted = replaceSelection(uiElement: uiElement, with: trimmedText)
            DebugLogger.log("replaceSelection result=\(inserted)")
        } else {
            inserted = try setValue(uiElement: uiElement, text: trimmedText)
            DebugLogger.log("setValue result=\(inserted)")
        }

        if inserted {
            DebugLogger.log("AX insertion succeeded")
            return
        }

        DebugLogger.log("AX insertion failed")
    }
}

private extension AccessibilityService {
    typealias InsertionTarget = (application: NSRunningApplication, element: AXUIElement)

    func resolvePreferredTarget() throws -> InsertionTarget {
        if let capturedApplication, let capturedElement {
            DebugLogger.log("using captured insertion target")
            return (capturedApplication, capturedElement)
        }

        DebugLogger.log("no captured target; resolving current target")
        return try resolveCurrentTarget()
    }

    func resolveCurrentTarget() throws -> InsertionTarget {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            throw WhispyError.noFocusedApplication
        }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        var focusedElement: CFTypeRef?
        let elementError = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard elementError == .success, let focusedUIElement = focusedElement else {
            DebugLogger.log("failed to resolve focused element; error=\(elementError.rawValue)")
            throw WhispyError.noFocusedElement
        }

        DebugLogger.log("resolved current target app=\(frontApp.localizedName ?? "unknown") pid=\(frontApp.processIdentifier)")
        return (frontApp, focusedUIElement as! AXUIElement)
    }

    func replaceSelection(uiElement: AXUIElement, with text: String) -> Bool {
        let setError = AXUIElementSetAttributeValue(
            uiElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )
        DebugLogger.log("AXSelectedText set error=\(setError.rawValue)")
        return setError == .success
    }

    func setValue(uiElement: AXUIElement, text: String) throws -> Bool {
        let setError = AXUIElementSetAttributeValue(
            uiElement,
            kAXValueAttribute as CFString,
            text as CFTypeRef
        )
        DebugLogger.log("AXValue set error=\(setError.rawValue)")
        return setError == .success
    }

    func pasteUsingPasteboard(_ text: String, into application: NSRunningApplication) throws {
        DebugLogger.log("pasteboard fallback target app=\(application.localizedName ?? "unknown") pid=\(application.processIdentifier)")
        let pasteboard = NSPasteboard.general
        let previousItems = pasteboard.pasteboardItems?.map { item in
            item.types.reduce(into: [NSPasteboard.PasteboardType: Data]()) { partialResult, type in
                if let data = item.data(forType: type) {
                    partialResult[type] = data
                }
            }
        } ?? []

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            DebugLogger.log("failed to write string to pasteboard")
            throw WhispyError.insertionFailed
        }

        application.activate()
        DebugLogger.log("target application activated for paste fallback")

        Thread.sleep(forTimeInterval: 0.15)

        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x0B, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x0B, keyDown: false) else {
            DebugLogger.log("failed to create CGEvents for paste fallback")
            restorePasteboard(previousItems, on: pasteboard)
            throw WhispyError.insertionFailed
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            self.restorePasteboard(previousItems, on: pasteboard)
            DebugLogger.log("pasteboard restored after fallback")
        }
    }

    func restorePasteboard(_ items: [[NSPasteboard.PasteboardType: Data]], on pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        guard !items.isEmpty else { return }

        for storedItem in items {
            let item = NSPasteboardItem()
            for (type, data) in storedItem {
                item.setData(data, forType: type)
            }
            pasteboard.writeObjects([item])
        }
    }

}
