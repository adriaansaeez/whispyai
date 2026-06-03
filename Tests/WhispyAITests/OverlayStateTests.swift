import XCTest
@testable import WhispyAI

final class OverlayStateTests: XCTestCase {
    func testProcessingStateCanBeManual() {
        let state = RecordingOverlayController.OverlayState.processing(.email, isManual: true)
        if case let .processing(kind, isManual) = state {
            XCTAssertEqual(kind, .email)
            XCTAssertTrue(isManual)
        } else {
            XCTFail("Expected .processing case")
        }
    }

    func testProcessingStateCanBeAutoDetected() {
        let state = RecordingOverlayController.OverlayState.processing(.chat, isManual: false)
        if case let .processing(kind, isManual) = state {
            XCTAssertEqual(kind, .chat)
            XCTAssertFalse(isManual)
        } else {
            XCTFail("Expected .processing case")
        }
    }

    func testProcessingStateNilKindWithManual() {
        let state = RecordingOverlayController.OverlayState.processing(nil, isManual: true)
        if case let .processing(kind, isManual) = state {
            XCTAssertNil(kind)
            XCTAssertTrue(isManual)
        } else {
            XCTFail("Expected .processing case")
        }
    }
}
