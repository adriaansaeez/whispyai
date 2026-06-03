import XCTest
@testable import WhispyAI
import KeyboardShortcuts

final class HotkeyRegistrationTests: XCTestCase {
    func testCycleContextModeShortcutNameExists() {
        // Verify the shortcut name is defined (compilation check)
        let name = KeyboardShortcuts.Name.cycleContextMode
        XCTAssertNotNil(name, "cycleContextMode shortcut name should be defined")
    }

    func testCycleContextModeDefaultShortcut() {
        let name = KeyboardShortcuts.Name.cycleContextMode
        let shortcut = name.shortcut
        XCTAssertNotNil(shortcut, "cycleContextMode should have a default shortcut configured")

        // Verify it uses ⌥+⇧+C (Option+Shift+C)
        let expectedKey = KeyboardShortcuts.Key.c
        let expectedModifiers: NSEvent.ModifierFlags = [.option, .shift]
        XCTAssertEqual(shortcut?.key, expectedKey, "Shortcut key should be C")
        XCTAssertTrue(shortcut?.modifiers.contains(expectedModifiers) ?? false,
                       "Shortcut modifiers should include Option and Shift")
    }
}
