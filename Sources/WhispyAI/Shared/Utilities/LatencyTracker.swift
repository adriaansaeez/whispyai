import Foundation

actor LatencyTracker {
    private(set) var marks: [String: Date] = [:]

    func mark(_ label: String) {
        marks[label] = Date()
    }
}
