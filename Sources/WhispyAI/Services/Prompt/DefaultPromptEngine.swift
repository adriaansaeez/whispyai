struct DefaultPromptEngine: PromptBuilding {
    static let legacyPromptTemplate = """
    Reescribe el siguiente texto dictado.
    Objetivos:
    - Mejorar gramatica.
    - Mejorar puntuacion.
    - Mejorar claridad.
    - Mantener significado.
    - No inventar informacion.
    - Mantener el idioma original.
    Texto:
    {{TEXT}}
    """

    static let defaultPromptTemplate = """
    Instrucciones globales:
    - Devuelve exclusivamente el texto final mejorado.
    - No agregues explicaciones, prefacios, notas, comillas, markdown ni comentarios.
    - Mantén el significado original.
    - No inventes información.
    - Mantén el idioma original.
    - Conserva nombres propios, URLs, comandos, código y placeholders si aparecen.
    """

    let settingsStore: SettingsStore

    func makePrompt(for text: String, context: PromptContext) -> String {
        let settings = settingsStore.load()
        let basePrompt = normalizedCustomInstructions(from: settings.rewritePrompt)

        return [
            basePrompt,
            contextInstructions(for: context, text: text),
            "Texto dictado:",
            text,
        ]
        .joined(separator: "\n")
    }
}

private extension DefaultPromptEngine {
    func normalizedCustomInstructions(from storedPrompt: String) -> String {
        let trimmedPrompt = storedPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedPrompt.isEmpty || trimmedPrompt == Self.legacyPromptTemplate.trimmingCharacters(in: .whitespacesAndNewlines) {
            return Self.defaultPromptTemplate
        }

        if trimmedPrompt == Self.defaultPromptTemplate.trimmingCharacters(in: .whitespacesAndNewlines) {
            return Self.defaultPromptTemplate
        }

        return [
            Self.defaultPromptTemplate,
            "Instrucciones adicionales del usuario:",
            trimmedPrompt,
        ]
        .joined(separator: "\n")
    }

    func contextInstructions(for context: PromptContext, text: String) -> String {
        switch context.kind {
        case .autodetect:
            return """
            Contexto detectado: texto general\(context.appName.map { " en \($0)" } ?? "").
            - Mejora gramática, puntuación y claridad.
            - Mantén el tono original salvo errores evidentes.
            - Devuelve solo el texto final.
            """
        case .email:
            return emailInstructions(for: context, text: text)
        case .chat:
            return """
            Contexto detectado: mensaje informal\(context.appName.map { " en \($0)" } ?? "").
            - Reescribe con tono natural, cercano y breve.
            - Corrige errores sin volverlo demasiado formal.
            - Mantén el ritmo conversacional.
            - Devuelve solo el mensaje final.
            """
        case .prompt:
            return promptInstructions(for: context, text: text)
        case .neutral:
            return """
            Contexto detectado: texto general\(context.appName.map { " en \($0)" } ?? "").
            - Mejora gramática, puntuación y claridad.
            - Mantén el tono original salvo errores evidentes.
            - Devuelve solo el texto final.
            """
        }
    }

    func emailInstructions(for context: PromptContext, text: String) -> String {
        let draftMode = emailDraftMode(for: text)

        let structureGuidance: String
        switch draftMode {
        case .completeDraft:
            structureGuidance = """
            - El texto parece un borrador relativamente completo de email.
            - Si falta saludo, puedes agregar "Hola,".
            - Si falta despedida, puedes agregar "Un saludo.".
            - Ordena el contenido en un formato natural de correo con párrafos claros.
            """
        case .fragment:
            structureGuidance = """
            - El texto parece una frase breve o un fragmento parcial.
            - No agregues saludo ni despedida.
            - No lo conviertas artificialmente en un email completo.
            - Limítate a mejorar redacción, claridad y puntuación.
            """
        }

        return """
        Contexto detectado: email\(context.appName.map { " en \($0)" } ?? "").
        - Reescribe como un email claro, natural y bien redactado.
        - Mantén cortesía natural sin sonar robótico.
        \(structureGuidance)
        - Mantén el significado original.
        - No inventes asunto, destinatario, contexto, datos, compromisos ni información no mencionada.
        - Devuelve solo el cuerpo final del email, sin explicaciones.
        """
    }

    func emailDraftMode(for text: String) -> EmailDraftMode {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let loweredText = trimmedText.lowercased()
        let wordCount = trimmedText.split { $0.isWhitespace || $0.isNewline }.count
        let sentenceSeparators = trimmedText.filter { ".!?\n".contains($0) }.count
        let hasLineBreak = trimmedText.contains("\n")
        let hasGreeting = containsAny(loweredText, phrases: [
            "hola",
            "buenos dias",
            "buenas tardes",
            "buenas noches",
            "estimado",
            "estimada",
            "dear",
        ])
        let hasClosing = containsAny(loweredText, phrases: [
            "un saludo",
            "saludos",
            "cordialmente",
            "gracias",
            "thanks",
            "best regards",
        ])
        let hasEmailStyleCue = containsAny(loweredText, phrases: [
            "queria comentarte",
            "quería comentarte",
            "te escribo",
            "te escribia",
            "te escribía",
            "adjunto",
            "avísame",
            "avisame",
            "quedo atento",
            "quedo atenta",
            "let me know",
        ])
        let looksStructured = hasLineBreak || sentenceSeparators >= 2
        let hasEnoughContent = wordCount >= 14 && (trimmedText.contains(",") || hasEmailStyleCue)

        if hasGreeting || hasClosing || looksStructured || hasEnoughContent {
            return .completeDraft
        }

        return .fragment
    }

    func promptInstructions(for context: PromptContext, text: String) -> String {
        let draftMode = promptDraftMode(for: text)

        let structureGuidance: String
        switch draftMode {
        case .completeDraft:
            structureGuidance = """
            - El texto ya parece un borrador técnico relativamente completo.
            - Mejora claridad, orden y precisión sin expandirlo artificialmente.
            - Reorganiza mejor requisitos, restricciones, contexto y salida esperada si hace falta.
            """
        case .fragment:
            structureGuidance = """
            - El texto parece una instrucción breve o todavía ambigua.
            - Conviértelo en un prompt más claro y ejecutable.
            - Si aporta valor, dale una estructura mínima útil con objetivo, restricciones y salida esperada.
            - No agregues secciones vacías ni relleno innecesario.
            """
        }

        return """
        Contexto detectado: prompt o instrucción técnica\(context.appName.map { " en \($0)" } ?? "").
        - Reescribe el texto para convertirlo en un prompt claro, preciso y accionable.
        \(structureGuidance)
        - Conserva intención, requisitos, restricciones, detalles técnicos, formato esperado y lenguaje del original.
        - No inventes pasos, APIs, archivos, dependencias, formatos, condiciones ni requisitos no mencionados o no claramente implícitos.
        - Devuelve solo el prompt final.
        """
    }

    func promptDraftMode(for text: String) -> PromptDraftMode {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let loweredText = trimmedText.lowercased()
        let wordCount = trimmedText.split { $0.isWhitespace || $0.isNewline }.count
        let hasLineBreak = trimmedText.contains("\n")
        let hasBulletList = trimmedText.contains("- ") || trimmedText.contains("* ")
        let instructionCueCount = [
            "actua como",
            "actúa como",
            "haz",
            "crea",
            "genera",
            "escribe",
            "build",
            "write",
            "generate",
            "create",
        ].reduce(0) { partialResult, phrase in
            partialResult + (loweredText.contains(phrase) ? 1 : 0)
        }
        let technicalCueCount = [
            "json",
            "sql",
            "regex",
            "api",
            "swift",
            "python",
            "javascript",
            "typescript",
            "class ",
            "struct ",
            "markdown",
            "csv",
        ].reduce(0) { partialResult, phrase in
            partialResult + (loweredText.contains(phrase) ? 1 : 0)
        }
        let restrictionCueCount = [
            "sin ",
            "no uses",
            "no utilices",
            "must",
            "only",
            "debe",
            "deben",
        ].reduce(0) { partialResult, phrase in
            partialResult + (loweredText.contains(phrase) ? 1 : 0)
        }
        let looksStructured = hasLineBreak || hasBulletList
        let hasEnoughContent = wordCount >= 18 && instructionCueCount >= 1 && (technicalCueCount >= 1 || restrictionCueCount >= 1)

        if looksStructured || hasEnoughContent || instructionCueCount >= 2 || (technicalCueCount >= 2 && restrictionCueCount >= 1) {
            return .completeDraft
        }

        return .fragment
    }

    func containsAny(_ text: String, phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }

    enum EmailDraftMode {
        case completeDraft
        case fragment
    }

    enum PromptDraftMode {
        case completeDraft
        case fragment
    }
}
