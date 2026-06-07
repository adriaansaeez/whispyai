import Foundation

struct CustomProvider: AIProvider {
    let baseURL: String
    let model: String
    let apiKey: String?
    let temperature: Double
    let maxTokens: Int
    let timeoutSeconds: Int
    let apiPath: String

    init(baseURL: String, model: String, apiKey: String?, temperature: Double, maxTokens: Int, timeoutSeconds: Int, apiPath: String? = nil) {
        self.baseURL = baseURL
        self.model = model
        self.apiKey = apiKey
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.timeoutSeconds = timeoutSeconds
        self.apiPath = apiPath ?? Self.autoDetectAPIPath(baseURL)
    }

    private static func autoDetectAPIPath(_ baseURL: String) -> String {
        guard let components = URLComponents(string: baseURL) else {
            return "/v1"
        }
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !path.isEmpty else {
            return "/v1"
        }
        return "/\(path)/v1"
    }

    func transform(text: String, prompt: String) async throws -> String {
        let messages = [
            ProviderMessage(role: "system", content: prompt),
            ProviderMessage(role: "user", content: text),
        ]

        let requestBody = OpenAIRewriteRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens
        )

        guard let baseComponents = URLComponents(string: baseURL) else {
            throw WhispyError.notImplemented("Invalid custom provider URL: \(baseURL)")
        }

        // Parse apiPath to separate path from query params
        let normalizedAPIPath = apiPath.hasPrefix("/") ? apiPath : "/\(apiPath)"
        let apiPathComponents = URLComponents(string: normalizedAPIPath)
        let apiPathOnly = apiPathComponents?.path ?? normalizedAPIPath
        let apiPathQueryItems = apiPathComponents?.queryItems ?? []

        // Build the endpoint path
        let basePath = baseComponents.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpoint = basePath.isEmpty ? "\(apiPathOnly)/chat/completions" : "\(basePath)\(apiPathOnly)/chat/completions"

        // Combine query items from baseURL and apiPath
        let baseQueryItems = baseComponents.queryItems ?? []
        let allQueryItems = baseQueryItems + apiPathQueryItems

        // Construct final URL with query params
        var finalComponents = URLComponents()
        finalComponents.scheme = baseComponents.scheme ?? "http"
        finalComponents.host = baseComponents.host ?? ""
        finalComponents.port = baseComponents.port
        finalComponents.path = "/\(endpoint)"
        if !allQueryItems.isEmpty {
            finalComponents.queryItems = allQueryItems
        }

        guard let url = finalComponents.url else {
            throw WhispyError.notImplemented("Invalid custom provider URL: \(finalComponents.string ?? "nil")")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = TimeInterval(timeoutSeconds)

        if let apiKey = apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(requestBody)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw WhispyError.notImplemented("Network error: \(error.localizedDescription)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhispyError.notImplemented("Invalid response from custom provider")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            throw WhispyError.notImplemented("Custom provider returned HTTP \(httpResponse.statusCode): \(body)")
        }

        let decoded = try JSONDecoder().decode(CustomProviderResponse.self, from: data)

        guard let content = decoded.choices.first?.message.content else {
            throw WhispyError.notImplemented("Custom provider returned empty response")
        }

        return sanitize(content)
    }
}

private extension CustomProvider {
    func sanitize(_ content: String) -> String {
        var sanitized = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if sanitized.hasPrefix("```") && sanitized.hasSuffix("```") {
            sanitized = sanitized
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let prefixes = [
            "texto mejorado:",
            "mensaje mejorado:",
            "email mejorado:",
            "resultado:",
        ]

        for prefix in prefixes where sanitized.lowercased().hasPrefix(prefix) {
            sanitized.removeFirst(prefix.count)
            sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
            break
        }

        return sanitized
    }
}

struct CustomProviderResponse: Codable, Sendable {
    let choices: [Choice]
}

struct Choice: Codable, Sendable {
    let message: ResponseMessage
}

struct ResponseMessage: Codable, Sendable {
    let content: String
}
