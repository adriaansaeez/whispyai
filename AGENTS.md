# AGENTS

## Repo Reality (Current State)
- This repository currently contains only `PLAN.md`; there is no executable app code, build config, CI, or test setup yet.
- Treat `PLAN.md` as the only source of truth for architecture and product scope until implementation files exist.

## Product Intent to Preserve
- Target app: native macOS menubar utility in Swift/SwiftUI.
- Core user flow must stay: global hotkey -> dictation via Apple Speech -> AI rewrite -> automatic text insertion at cursor.
- Speech recognition is local (Apple Speech Framework); only rewrite calls external AI providers.
- Provider model is BYOK/BYOM: design for interchangeable providers (OpenAI, Anthropic, Gemini, OpenRouter; Ollama planned later).

## Architectural Boundaries (from plan)
- Keep modules separated: `Speech Service`, `Prompt Engine`, `AI Provider Layer`, `Accessibility Service`.
- Maintain provider abstraction shape (`AIProvider.transform(text, prompt) async throws -> String`) so providers are swappable.
- Accessibility integration is a first-class requirement (AXUIElement-based text replacement), not a post-processing extra.

## MVP Scope Guardrails
- In scope for v1: global hotkey, Apple Speech transcription, one provider path (OpenAI), configurable prompt, text replacement, onboarding, menubar app.
- Out of scope for v1: history, sync, templates, multi-prompt workflows, analytics, Ollama.
- Primary metric to optimize during implementation: time from hotkey to inserted rewritten text (<3s target).

## Agent Workflow Guidance
- When scaffolding starts, prefer decisions that keep latency low and preserve original language/meaning in rewrite defaults.
- Do not invent repo commands (`build`, `test`, `lint`) until actual tooling/config is added; derive commands from manifests when they appear.
