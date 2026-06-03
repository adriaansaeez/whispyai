import Foundation

enum ConnectivityResult {
    case success(modelCount: Int)
    case failure(String)
}

enum FetchModelsResult {
    case success([String])
    case failure(String)
}

struct ProviderConnectivityService: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func testConnection(baseURL: String, model: String, useAuth: Bool, apiKey: String) async -> ConnectivityResult {
        var normalizedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        normalizedBaseURL = normalizedBaseURL.removingTrailingSlash()

        guard let url = URL(string: "\(normalizedBaseURL)/v1/models") else {
            return .failure("URL inválida")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        if useAuth, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure("Respuesta no válida del servidor")
            }

            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
                    return .success(modelCount: decoded.data.count)
                } catch {
                    return .success(modelCount: 0)
                }
            } else {
                let message = parseErrorMessage(from: data, statusCode: httpResponse.statusCode)
                return .failure(message)
            }
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                return .failure("La conexión excedió el tiempo límite (15s)")
            }
            if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                return .failure("No se pudo conectar. Verifica la URL y tu conexión a internet.")
            }
            return .failure("Error de conexión: \(urlError.localizedDescription)")
        } catch {
            return .failure("Error: \(error.localizedDescription)")
        }
    }

    private func parseErrorMessage(from data: Data, statusCode: Int) -> String {
        do {
            let decoded = try JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
            if let message = decoded.error?.message {
                return "Error \(statusCode): \(message)"
            }
        } catch {}

        let body = String(data: data, encoding: .utf8) ?? "sin cuerpo"
        return "Error \(statusCode): \(body)"
    }

    func fetchModels(baseURL: String, useAuth: Bool, apiKey: String) async -> FetchModelsResult {
        var normalizedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        normalizedBaseURL = normalizedBaseURL.removingTrailingSlash()

        guard !normalizedBaseURL.isEmpty, let url = URL(string: "\(normalizedBaseURL)/v1/models") else {
            return .failure("URL inválida")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        if useAuth, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure("Respuesta no válida del servidor")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = parseErrorMessage(from: data, statusCode: httpResponse.statusCode)
                return .failure(message)
            }

            let decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
            let modelNames = decoded.data.map(\.id).sorted()
            return .success(modelNames)
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                return .failure("La conexión excedió el tiempo límite")
            }
            return .failure("Error de conexión: \(urlError.localizedDescription)")
        } catch {
            return .failure("Error: \(error.localizedDescription)")
        }
    }
}

private extension String {
    func removingTrailingSlash() -> String {
        var result = self
        while result.hasSuffix("/") {
            result.removeLast()
        }
        return result
    }
}
