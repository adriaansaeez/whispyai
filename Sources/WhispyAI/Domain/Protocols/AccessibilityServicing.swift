import Foundation

@MainActor
protocol AccessibilityServicing: Sendable {
    func checkPermission() -> Bool
    func requestPermission()
    func captureInsertionTarget() throws
    func insert(text: String) async throws
}
