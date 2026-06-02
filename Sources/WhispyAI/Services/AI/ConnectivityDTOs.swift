import Foundation

struct ModelsResponse: Codable, Sendable {
    let data: [ModelInfo]
}

struct ModelInfo: Codable, Sendable {
    let id: String
}

struct OpenAIErrorResponse: Codable, Sendable {
    let error: ErrorDetail?
}

struct ErrorDetail: Codable, Sendable {
    let message: String
}
