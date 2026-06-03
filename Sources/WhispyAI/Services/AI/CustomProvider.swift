import Foundation

struct CustomProvider: AIProvider {
    let baseURL: String
    let model: String
    let apiKey: String?
    let temperature: Double
    let maxTokens: Int
    let timeoutSeconds: Int

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

        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            throw WhispyError.notImplemented("Invalid custom provider URL")
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
