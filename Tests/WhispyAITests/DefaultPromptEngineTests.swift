import XCTest
@testable import WhispyAI

final class DefaultPromptEngineTests: XCTestCase {
    func testPromptInjectsDictatedText() {
        let suiteName = "DefaultPromptEngineTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(defaults: defaults)
        let engine = DefaultPromptEngine(settingsStore: store)

        let prompt = engine.makePrompt(for: "Hola mundo", context: PromptContext(kind: .neutral, appName: nil))

        XCTAssertTrue(prompt.contains("Hola mundo"))
        XCTAssertTrue(prompt.contains("Devuelve exclusivamente el texto final mejorado."))
    }

    func testPromptUsesEmailInstructions() {
        let suiteName = "DefaultPromptEngineTests.email"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(defaults: defaults)
        let engine = DefaultPromptEngine(settingsStore: store)

        let prompt = engine.makePrompt(
            for: "hola equipo queria compartir una actualizacion",
            context: PromptContext(kind: .email, appName: "Mail")
        )

        XCTAssertTrue(prompt.contains("Contexto detectado: email en Mail."))
        XCTAssertTrue(prompt.contains("Reescribe como un email claro, natural y bien redactado."))
        XCTAssertTrue(prompt.contains("No inventes asunto, destinatario, contexto, datos, compromisos ni información no mencionada."))
        XCTAssertTrue(prompt.contains("Devuelve solo el cuerpo final del email, sin explicaciones."))
    }

    func testEmailFragmentPromptDoesNotAddGreetingOrClosingInstructions() {
        let suiteName = "DefaultPromptEngineTests.email.fragment"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(defaults: defaults)
        let engine = DefaultPromptEngine(settingsStore: store)

        let prompt = engine.makePrompt(
            for: "recuerda tenemos una reunion a las 7 de la tarde",
            context: PromptContext(kind: .email, appName: "Mail")
        )

        XCTAssertTrue(prompt.contains("El texto parece una frase breve o un fragmento parcial."))
        XCTAssertTrue(prompt.contains("No agregues saludo ni despedida."))
        XCTAssertTrue(prompt.contains("No lo conviertas artificialmente en un email completo."))
        XCTAssertFalse(prompt.contains("Si falta saludo, puedes agregar \"Hola,\"."))
    }

    func testCompleteEmailDraftPromptAddsFallbackGreetingAndClosingInstructions() {
        let suiteName = "DefaultPromptEngineTests.email.complete"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(defaults: defaults)
        let engine = DefaultPromptEngine(settingsStore: store)

        let prompt = engine.makePrompt(
            for: "queria comentarte que ya terminamos la integracion y podemos lanzar mañana, avisame si ves algo antes",
            context: PromptContext(kind: .email, appName: "Mail")
        )

        XCTAssertTrue(prompt.contains("El texto parece un borrador relativamente completo de email."))
        XCTAssertTrue(prompt.contains("Si falta saludo, puedes agregar \"Hola,\"."))
        XCTAssertTrue(prompt.contains("Si falta despedida, puedes agregar \"Un saludo.\"."))
        XCTAssertTrue(prompt.contains("Ordena el contenido en un formato natural de correo con párrafos claros."))
    }

    func testPromptContextUsesStructuredInstructions() {
        let suiteName = "DefaultPromptEngineTests.prompt"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(defaults: defaults)
        let engine = DefaultPromptEngine(settingsStore: store)

        let prompt = engine.makePrompt(
            for: "crea un script en python para renombrar archivos",
            context: PromptContext(kind: .prompt, appName: "Cursor")
        )

        XCTAssertTrue(prompt.contains("Contexto detectado: prompt o instrucción técnica en Cursor."))
        XCTAssertTrue(prompt.contains("Reescribe el texto para convertirlo en un prompt claro, preciso y accionable."))
        XCTAssertTrue(prompt.contains("No inventes pasos, APIs, archivos, dependencias, formatos, condiciones ni requisitos no mencionados o no claramente implícitos."))
        XCTAssertTrue(prompt.contains("Devuelve solo el prompt final."))
    }

    func testPromptFragmentGetsMinimumStructureGuidance() {
        let suiteName = "DefaultPromptEngineTests.prompt.fragment"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(defaults: defaults)
        let engine = DefaultPromptEngine(settingsStore: store)

        let prompt = engine.makePrompt(
            for: "haz un regex para validar emails",
            context: PromptContext(kind: .prompt, appName: "ChatGPT")
        )

        XCTAssertTrue(prompt.contains("El texto parece una instrucción breve o todavía ambigua."))
        XCTAssertTrue(prompt.contains("Conviértelo en un prompt más claro y ejecutable."))
        XCTAssertTrue(prompt.contains("Si aporta valor, dale una estructura mínima útil con objetivo, restricciones y salida esperada."))
        XCTAssertTrue(prompt.contains("No agregues secciones vacías ni relleno innecesario."))
    }

    func testCompletePromptDraftGetsReorganizationGuidance() {
        let suiteName = "DefaultPromptEngineTests.prompt.complete"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(defaults: defaults)
        let engine = DefaultPromptEngine(settingsStore: store)

        let prompt = engine.makePrompt(
            for: "crea un script en python que lea un csv y genere un json, no uses librerias externas y devuelve ejemplos de salida",
            context: PromptContext(kind: .prompt, appName: "Cursor")
        )

        XCTAssertTrue(prompt.contains("El texto ya parece un borrador técnico relativamente completo."))
        XCTAssertTrue(prompt.contains("Mejora claridad, orden y precisión sin expandirlo artificialmente."))
        XCTAssertTrue(prompt.contains("Reorganiza mejor requisitos, restricciones, contexto y salida esperada si hace falta."))
    }
}
