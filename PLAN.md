AI Dictation Rewriter for macOS
Visión
Aplicación nativa para macOS que permite al usuario dictar texto mediante el reconocimiento de voz de Apple y transformarlo automáticamente utilizando el modelo de IA que configure.
Objetivo:
Dictar de forma natural.
Obtener texto mejor redactado.
Funcionar en cualquier aplicación.
No depender de Whisper ni de modelos locales.
Utilizar la infraestructura de reconocimiento de voz de Apple.
Permitir que el usuario utilice su propio proveedor de IA.
Ejemplos:
Emails
Slack
WhatsApp
Notion
Documentación
Redes sociales
CRM
ChatGPT
Cursor
Propuesta de valor
El usuario habla.
La aplicación:
Transcribe con Apple Speech Framework.
Envía el texto a un modelo de IA.
Recibe una versión mejorada.
Inserta automáticamente el resultado donde estaba escribiendo.
El usuario nunca copia ni pega nada.
Principios del producto
Simplicidad
Una única acción:
Hotkey → Hablar → Resultado.
Bring Your Own Model
El usuario utiliza:
OpenAI
Anthropic
Gemini
OpenRouter
Ollama (futuro)
La aplicación no obliga a utilizar un proveedor concreto.
Nativo
Toda la experiencia debe sentirse como una funcionalidad propia de macOS.
Mínima latencia
La transcripción ocurre localmente mediante Apple.
Solo el paso de reescritura utiliza internet.
Arquitectura General
┌─────────────────┐
│ Global Hotkey   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Speech Service  │
│ Apple Speech    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Prompt Engine   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ AI Provider     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Accessibility   │
│ Text Replace    │
└─────────────────┘
Tecnologías
UI
SwiftUI
Lenguaje
Swift
Speech To Text
Speech Framework
AVFoundation
Hotkeys
KeyboardShortcuts
Integración del sistema
Accessibility API
AXUIElement
Persistencia
UserDefaults
Networking
URLSession
Distribución
DMG firmado
Notarización Apple
Módulos
Speech Service
Responsabilidad:
Convertir voz a texto.
Input:
Audio del micrófono.
Output:
Texto transcrito.
Prompt Engine
Responsabilidad:
Construir el prompt que se enviará al modelo.
Ejemplo:
"Convierte este texto dictado en un email profesional manteniendo el significado."
AI Provider Layer
Responsabilidad:
Abstraer el proveedor de IA.
Interfaz:
protocol AIProvider {
    func transform(
        text: String,
        prompt: String
    ) async throws -> String
}
Implementaciones:
OpenAIProvider
AnthropicProvider
GeminiProvider
OpenRouterProvider
Accessibility Service
Responsabilidad:
Insertar el resultado donde se encuentra el cursor.
Funciones:
Obtener foco actual
Obtener selección
Reemplazar selección
Insertar texto
Flujo Principal
Caso de uso
Usuario redactando un email.
Paso 1
Pulsa la hotkey.
Ejemplo:
⌥ + Espacio
Paso 2
Se activa el micrófono.
Paso 3
Habla.
Ejemplo:
"Hola Juan quería comentarte que ya hemos terminado la integración y podemos lanzar mañana."
Paso 4
Apple genera la transcripción.
Paso 5
La aplicación construye el prompt.
Paso 6
Se envía al modelo seleccionado.
Paso 7
La IA devuelve:
"Hola Juan,
Quería comentarte que hemos finalizado la integración y estamos preparados para realizar el lanzamiento mañana.
Quedo atento a cualquier comentario.
Un saludo."
Paso 8
El texto es insertado automáticamente.
Onboarding
Pantalla 1
Bienvenida.
Mensaje:
"Habla y deja que la IA redacte mejor por ti."
Botón:
Continuar
Pantalla 2
Permiso de micrófono.
Solicitar:
Audio Recording Permission
Pantalla 3
Permisos de accesibilidad.
Solicitar:
Accessibility Permission
Explicar:
"Necesitamos acceso para insertar texto en tus aplicaciones."
Pantalla 4
Proveedor de IA.
Opciones:
OpenAI
Anthropic
Gemini
OpenRouter
Pantalla 5
API Key.
Campo seguro.
Validación automática.
Pantalla 6
Prompt por defecto.
Valor inicial:
"Reescribe el texto mejorando gramática, puntuación y claridad sin alterar el significado."
Pantalla 7
Hotkey.
Valor por defecto:
⌥ + Espacio
Pantalla 8
Prueba rápida.
Usuario dicta una frase.
La aplicación muestra el resultado.
Finalizar onboarding.
Configuración
General
Iniciar al arrancar macOS
Mostrar icono en menú
Sonido al iniciar grabación
Hotkey
Configurar atajo global
IA
Proveedor
API Key
Modelo
Prompt
Editable por el usuario.
Avanzado
Temperatura
Máximo de tokens
Tiempo de espera
Prompt por Defecto
Reescribe el siguiente texto dictado.
Objetivos:
Mejorar gramática.
Mejorar puntuación.
Mejorar claridad.
Mantener significado.
No inventar información.
Mantener el idioma original.
Texto:
{{TEXT}}
MVP v1
Incluye:
Hotkey global
Speech Framework
OpenAI
Prompt configurable
Reemplazo de texto
Menubar app
Onboarding
No incluye:
Historial
Sincronización
Plantillas
Ollama
Múltiples prompts
Analytics
Roadmap v2
Plantillas por contexto
Email mode
Slack mode
WhatsApp mode
Traducción automática
Ollama local
Historial de dictados
Atajos personalizados
Marketplace de prompts
Métrica Principal
Time To Text.
Tiempo desde pulsar la hotkey hasta que el texto mejorado aparece en pantalla.
Objetivo MVP:
< 3 segundos.