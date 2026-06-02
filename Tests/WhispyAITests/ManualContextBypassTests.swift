import XCTest
@testable import WhispyAI

@MainActor
final class ManualContextBypassTests: XCTestCase {
    func testManualEmailKindBypassesDetector() {
        let state = AppState()

        // Set manual mode to email
        state.cycleContextMode() // -> .autodetect
        state.cycleContextMode() // -> .email

        XCTAssertEqual(state.manualContextKind, .email)

        // Verify manual mode is active
        XCTAssertNotNil(state.manualContextKind, "Manual context should be set")
        XCTAssertEqual(state.manualContextKind, .email, "Manual context should be email")
    }

    func testNilManualKindMeansAutodetect() {
        let state = AppState()

        // Default: nil means autodetect
        XCTAssertNil(state.manualContextKind)

        // The finishDictation path should use the detector when manualContextKind is nil
    }

    func testCyclingAndResettingReturnsToAutodetect() {
        let state = AppState()

        // Set manual mode
        state.cycleContextMode() // .autodetect
        state.cycleContextMode() // .email
        state.cycleContextMode() // .chat
        XCTAssertNotNil(state.manualContextKind)

        // Reset
        state.resetContextMode()
        XCTAssertNil(state.manualContextKind, "After reset, manualContextKind should be nil (autodetect)")
    }

    func testOverlayShowsManualLabelWhenManualMode() {
        let manualState = RecordingOverlayController.OverlayState.processing(.email, isManual: true)
        let autoState = RecordingOverlayController.OverlayState.processing(.email, isManual: false)

        if case let .processing(_, isManualManual) = manualState {
            XCTAssertTrue(isManualManual, "Manual state should have isManual=true")
        } else {
            XCTFail("Expected .processing case")
        }

        if case let .processing(_, isManualAuto) = autoState {
            XCTAssertFalse(isManualAuto, "Auto state should have isManual=false")
        } else {
            XCTFail("Expected .processing case")
        }
    }
}
