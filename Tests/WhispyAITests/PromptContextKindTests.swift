import XCTest
@testable import WhispyAI

final class PromptContextKindTests: XCTestCase {
    // MARK: - CaseIterable

    func testCaseIterableIncludesAutodetect() {
        let allCases = PromptContextKind.allCases
        XCTAssertTrue(allCases.contains(.autodetect), "allCases should include .autodetect")
    }

    func testCaseIterableFirstIsAutodetect() {
        let allCases = PromptContextKind.allCases
        XCTAssertEqual(allCases.first, .autodetect, ".autodetect should be the first case")
    }

    func testCaseIterableHasAllExpectedCases() {
        let allCases = PromptContextKind.allCases
        let expected: [PromptContextKind] = [.autodetect, .email, .chat, .prompt, .neutral]
        XCTAssertEqual(allCases, expected, "allCases should match expected order")
    }

    // MARK: - Autodetect displayName

    func testAutodetectDisplayName() {
        XCTAssertEqual(PromptContextKind.autodetect.displayName, "Autodetect")
    }

    // MARK: - Autodetect is default

    func testAutodetectIsDefaultForPromptContext() {
        let context = PromptContext(kind: .autodetect, appName: nil)
        XCTAssertEqual(context.kind, .autodetect)
    }
}
