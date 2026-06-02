import XCTest
@testable import WhispyAI

@MainActor
final class AppStateContextModeTests: XCTestCase {
    // MARK: - cycleContextMode

    func testCycleContextModeSetsFirstManualKind() {
        let state = AppState()
        state.cycleContextMode()

        XCTAssertNotNil(state.manualContextKind)
        XCTAssertEqual(state.manualContextKind, .autodetect, "First cycle should set .autodetect")
    }

    func testCycleContextModeCyclesThroughAllCases() {
        let state = AppState()

        let expectedOrder: [PromptContextKind] = [.autodetect, .email, .chat, .prompt, .neutral]

        for expected in expectedOrder {
            state.cycleContextMode()
            XCTAssertEqual(state.manualContextKind, expected, "Expected \(expected) after cycle")
        }
    }

    func testCycleContextModeWrapsAroundToAutodetect() {
        let state = AppState()

        // Cycle through all cases
        for _ in PromptContextKind.allCases {
            state.cycleContextMode()
        }
        XCTAssertEqual(state.manualContextKind, .neutral)

        // One more cycle should wrap to .autodetect
        state.cycleContextMode()
        XCTAssertEqual(state.manualContextKind, .autodetect, "Should wrap around to .autodetect")
    }

    func testCycleContextModeResetToNil() {
        let state = AppState()
        state.cycleContextMode()
        XCTAssertNotNil(state.manualContextKind)

        state.resetContextMode()
        XCTAssertNil(state.manualContextKind, "resetContextMode should set manualContextKind to nil")
    }

    // MARK: - manualContextKind default

    func testManualContextKindDefaultsToNil() {
        let state = AppState()
        XCTAssertNil(state.manualContextKind, "manualContextKind should default to nil (autodetect)")
    }
}
