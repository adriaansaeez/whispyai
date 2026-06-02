import AppKit

struct PromptContextDetector: Sendable {
    func detect(for text: String) -> PromptContext {
        let appName = NSWorkspace.shared.frontmostApplication?.localizedName
        let loweredText = text.lowercased()
        let loweredAppName = appName?.lowercased()

        var scores: [PromptContextKind: Int] = [
            .email: 0,
            .chat: 0,
            .prompt: 0,
            .neutral: 0,
        ]

        if let loweredAppName {
            applyApplicationSignals(loweredAppName, to: &scores)
        }

        applyTextSignals(loweredText, originalText: text, to: &scores)

        let bestKind = scores.max { lhs, rhs in
            lhs.value < rhs.value
        }?.key ?? .neutral

        if scores[bestKind, default: 0] <= 0 {
            return PromptContext(kind: .neutral, appName: appName)
        }

        return PromptContext(kind: bestKind, appName: appName)
    }
}

private extension PromptContextDetector {
    func applyApplicationSignals(_ appName: String, to scores: inout [PromptContextKind: Int]) {
        if matchesAny(appName, within: ["mail", "outlook", "spark", "superhuman", "airmail"]) {
            scores[.email, default: 0] += 4
        }

        if matchesAny(appName, within: ["slack", "discord", "telegram", "messages", "whatsapp", "signal"]) {
            scores[.chat, default: 0] += 4
        }

        if matchesAny(appName, within: ["cursor", "visual studio code", "code", "xcode", "terminal", "iterm", "warp", "claude", "chatgpt", "opencode"]) {
            scores[.prompt, default: 0] += 4
        }
    }

    func applyTextSignals(_ loweredText: String, originalText: String, to scores: inout [PromptContextKind: Int]) {
        if containsAny(loweredText, phrases: ["estimado", "estimada", "hola equipo", "buenos dias", "buenas tardes", "saludos", "un saludo", "cordialmente", "adjunto", "gracias de antemano"]) {
            scores[.email, default: 0] += 3
        }

        if loweredText.contains("asunto:") || loweredText.contains("subject:") {
            scores[.email, default: 0] += 3
        }

        if containsAny(loweredText, phrases: ["jaja", "jeje", "xd", "vale", "ok", "nos vemos", "te paso", "avísame", "avisame", "gracias!"]) {
            scores[.chat, default: 0] += 3
        }

        if originalText.contains("?") || originalText.contains("!") || originalText.contains("🙂") || originalText.contains("😂") || originalText.contains("👍") {
            scores[.chat, default: 0] += 1
        }

        if originalText.count < 90 {
            scores[.chat, default: 0] += 1
        }

        if containsAny(loweredText, phrases: ["actua como", "actúa como", "genera", "crea", "escribe un", "write a", "build a", "haz un", "quiero un script", "necesito una funcion", "necesito una función"]) {
            scores[.prompt, default: 0] += 3
        }

        if containsAny(loweredText, phrases: ["json", "sql", "regex", "bash", "swift", "python", "javascript", "typescript", "api", "prompt", "funcion", "función", "class ", "struct ", "markdown", "csv"]) {
            scores[.prompt, default: 0] += 2
        }

        if scores[.email, default: 0] == 0, scores[.chat, default: 0] == 0, scores[.prompt, default: 0] == 0 {
            scores[.neutral, default: 0] += 1
        }
    }

    func containsAny(_ text: String, phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }

    func matchesAny(_ text: String, within phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }
}
