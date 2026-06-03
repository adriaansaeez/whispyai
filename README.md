# WhispyAI

<div align="center">

**Dictate naturally. Get polished text instantly.**

[macOS 14.0+](https://developer.apple.com/macos/) · [Swift 6.0](https://www.swift.org/) · [OpenAI-compatible](Sources/WhispyAI/Services/AI/CustomProvider.swift)

</div>

WhispyAI is a native macOS menubar utility that lets you dictate text using Apple's built-in speech recognition, automatically rewrites it with your preferred AI provider, and inserts the polished result directly into any app — no copy-paste, no context switching.

```
Hotkey → Speak → AI rewrite → Text appears where you're typing
```

## Features

### Core Flow

- **Global hotkey** — press `Option + Space` (customizable) from anywhere on your Mac to start dictating
- **Apple Speech transcription** — local, offline speech-to-text using the native Speech Framework
- **AI-powered rewriting** — send your raw dictation to any OpenAI-compatible API for polished output
- **Seamless text insertion** — the rewritten text replaces your selection or inserts at your cursor using macOS Accessibility APIs

### Smart Context Detection

WhispyAI detects the context of your dictation and adapts the rewriting style automatically:

| Mode | Behavior |
|------|----------|
| **Auto** | Analyzes the active app and dictation content to choose the best rewriting style |
| **Email** | Rewrites as a clear, professional email with proper greeting and closing |
| **Chat** | Keeps your message casual and concise for Slack, WhatsApp, or team chats |
| **Prompt** | Structures your dictation into a clear, well-organized technical prompt |
| **Neutral** | Minimal changes — fixes grammar and punctuation while preserving your voice |

You can also cycle between modes on the fly with a separate hotkey (`Option + Shift + C`).

### Provider Support

WhispyAI uses a Bring Your Own Key model — you choose the AI provider:

- **OpenAI** — GPT-4o, GPT-4o-mini, and other OpenAI models
- **Custom API** — any OpenAI-compatible endpoint (LiteLLM, Ollama, local servers, etc.)
- **Coming soon** — Anthropic, Gemini, OpenRouter

### Privacy & Security

- Your API key is stored in the **macOS Keychain**, never in plaintext
- Speech transcription happens **locally** on your Mac
- Only the rewritten prompt and raw dictation are sent to your chosen AI provider
- No telemetry, analytics, or data collection

### Menubar App

- Lightweight menubar icon with status indicators
- Start/stop dictation directly from the menu
- Quick access to settings
- Launch at login support

## Installation

### From Source (Development)

```bash
git clone https://github.com/adriaansaeez/whispyai.git
cd whispyai
swift build
swift run
```

Or open the project directly in Xcode 15+ and build.

### Requirements

- **macOS 14.0** (Sonoma) or later
- **Xcode 15** or later (for development)
- An API key from your chosen AI provider
- Internet connection (for AI rewriting only; transcription is offline)

## Quick Start

### 1. First Launch

On first launch, the onboarding wizard guides you through:

1. **Welcome** — overview of WhispyAI
2. **Provider selection** — choose OpenAI or a custom endpoint
3. **Configuration** — enter your API key and model name
4. **Work mode** — pick how Whispy should rewrite your text
5. **Hotkey setup** — confirm or customize your dictation shortcut
6. **Quick test** — try a dictation to verify everything works

### 2. Grant Permissions

WhispyAI requires two system permissions:

- **Microphone access** — for speech recognition
- **Accessibility access** — to insert text into other applications

You'll be prompted during onboarding, or you can grant them manually in:
- **System Settings → Privacy & Security → Microphone**
- **System Settings → Privacy & Security → Accessibility**

### 3. Start Dictating

Press your hotkey (`Option + Space` by default), speak naturally, and press again to stop. The rewritten text appears where you're typing.

## Configuration

Open Settings from the menubar to customize:

### Hotkey & Work Mode

- **Dictation hotkey** — change the global shortcut
- **Work mode** — set default rewriting context (Auto, Email, Chat, Prompt, Neutral)

### Provider

- **Provider type** — OpenAI or Custom
- **Base URL** — for custom providers (e.g., `http://localhost:4000`)
- **Model** — the model name to use
- **API Key** — stored securely in Keychain
- **Connection test** — verify your provider is reachable before saving

### General

- **Launch at login** — start WhispyAI when your Mac boots
- **Show menubar icon** — toggle the menubar presence
- **Relaunch onboarding** — reset the setup wizard

## Architecture

```
┌─────────────────┐
│   Global Hotkey   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Speech Service  │  ← Apple Speech Framework (local transcription)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Prompt Engine   │  ← Context-aware prompt building
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AI Provider     │  ← OpenAI / Custom (swappable)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Accessibility    │  ← AXUIElement text insertion
└─────────────────┘
```

### Modules

| Module | Responsibility |
|--------|---------------|
| **Speech Service** | Captures microphone audio and transcribes to text locally using Apple Speech |
| **Prompt Engine** | Builds context-aware prompts based on the detected work mode and user settings |
| **AI Provider Layer** | Abstracts the AI provider behind a single protocol — swappable and extensible |
| **Accessibility Service** | Inserts rewritten text at the cursor position or replaces selected text in the active app |
| **Overlay Controller** | Shows a floating badge near the cursor indicating listening and processing states |

## Roadmap

### v1.0 — Current

- [x] Global hotkey dictation
- [x] Apple Speech transcription
- [x] OpenAI + Custom provider support
- [x] Context-aware prompt engine (Auto, Email, Chat, Prompt, Neutral)
- [x] Smart text insertion via Accessibility APIs
- [x] Menubar app with status indicators
- [x] Secure Keychain storage
- [x] Onboarding wizard
- [x] Recording overlay with context badges

### v1.1 — Planned

- **Transcription animations** — real-time waveform and live transcription preview in the overlay
- **Prompt improvements** — better system prompts with few-shot examples for each work mode
- **Context awareness** — deeper integration with app detection and text field type analysis

### v2.0 — Future

- **History** — browse and reuse past dictations
- **Template library** — save and switch between custom prompt templates
- **Multi-prompt workflows** — chain multiple rewrites (e.g., draft → polish → shorten)
- **Translation** — dictation in one language, rewritten in another
- **Ollama support** — fully local AI rewriting with open-source models
- **Custom prompt marketplace** — share and discover community prompt templates

## Building

### Prerequisites

- macOS 14.0+
- Xcode 15+ with Swift 6 toolchain
- Cocoa (included with Xcode)

### Build & Run

```bash
swift build
swift run
```

### Test

```bash
swift test
```

## Development

### Project Structure

```
Sources/WhispyAI/
├── App/
│   ├── Onboarding/          # Setup wizard
│   ├── MenuBar/             # Menubar menu UI
│   └── Overlay/             # Recording overlay
├── Features/
│   └── Settings/            # Settings views & view model
├── Services/
│   ├── AI/                  # Provider implementations
│   ├── Accessibility/       # Text insertion
│   ├── Prompt/              # Context detection & prompt building
│   └── Dictation/           # Speech recognition
├── Infrastructure/
│   ├── Storage/             # UserDefaults & Keychain
│   └── Shared/              # Logo, utilities
└── WhispyAIApp.swift        # App entry point
```

### Key Protocols

```swift
// AI Provider — swap any OpenAI-compatible service
protocol AIProvider {
    func transform(text: String, prompt: String) async throws -> String
}

// Prompt Building — context-aware prompt generation
protocol PromptBuilding {
    func makePrompt(for text: String, context: PromptContext) -> String
}
```

## Troubleshooting

### Text not inserting into an app

Some apps don't expose their text fields via Accessibility APIs. WhispyAI works best with:
- TextEdit, Notes, Mail
- Safari and Chrome web inputs
- Slack, Discord, and most Electron apps

If insertion fails in a specific app, check that Accessibility permission is granted in System Settings.

### Microphone not working

Ensure Microphone permission is granted:
**System Settings → Privacy & Security → Microphone → WhispyAI**

### Hotkey conflicts

If your chosen hotkey doesn't work, it may be reserved by macOS or another app. Change it in WhispyAI Settings.

## License

This project is licensed under the terms of the license included in the `LICENSE` file.

## Credits

Built with:
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) — declarative UI
- [Apple Speech Framework](https://developer.apple.com/documentation/speech) — speech recognition
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) — global hotkey management
- [macOS Accessibility API](https://developer.apple.com/documentation/accessibility) — text insertion

---

**Time to Text**: from hotkey press to inserted text — target under 3 seconds.
