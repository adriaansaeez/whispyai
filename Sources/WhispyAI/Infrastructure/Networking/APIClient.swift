import Foundation

struct APIClient: Sendable {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }
}
