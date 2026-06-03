import Observation

@Observable
@MainActor
final class AppState {
    static weak var shared: AppState?

    var dictationState: DictationState = .idle
    var hasCompletedOnboarding = false
    var menuBarIconName = "waveform.badge.mic"
    var lastErrorMessage: String?
    var isRecording = false
    var detectedContextKind: PromptContextKind?
    var manualContextKind: PromptContextKind?

    private let coordinator: DictationCoordinator
    private var currentTask: Task<Void, Never>?
    private let overlayController = RecordingOverlayController.shared

    init(coordinator: DictationCoordinator? = nil) {
        let settingsStore = SettingsStore()
        let keychainStore = KeychainStore()
        let apiClient = APIClient()
        let promptEngine = DefaultPromptEngine(settingsStore: settingsStore)
        let contextDetector = PromptContextDetector()
        let accessibilityService = AccessibilityService()
        let speechService = SpeechService()
        let providerRegistry = AIProviderRegistry(
            settingsStore: settingsStore,
            keychainStore: keychainStore,
            apiClient: apiClient
        )

        self.coordinator = coordinator ?? DictationCoordinator(
            speechService: speechService,
            promptEngine: promptEngine,
            contextDetector: contextDetector,
            providerRegistry: providerRegistry,
            accessibilityService: accessibilityService,
            latencyTracker: LatencyTracker()
        )

        Self.shared = self
        hasCompletedOnboarding = settingsStore.hasCompletedOnboarding
    }

    func toggleDictation() {
        currentTask?.cancel()
        currentTask = Task {
            do {
                DebugLogger.log("toggleDictation started; current state=\(String(describing: dictationState))")
                if dictationState == .listening {
                    try await finishDictation()
                } else {
                    try await beginDictation()
                }
            } catch is CancellationError {
                DebugLogger.log("toggleDictation cancelled")
                setDictationState(.idle)
                isRecording = false
                detectedContextKind = nil
            } catch let error as WhispyError {
                DebugLogger.log("toggleDictation failed with WhispyError: \(error.errorDescription ?? String(describing: error))")
                setDictationState(.failed(error))
                lastErrorMessage = error.errorDescription
                isRecording = false
                detectedContextKind = nil
            } catch {
                let wrapped = WhispyError.notImplemented(error.localizedDescription)
                DebugLogger.log("toggleDictation failed with unexpected error: \(error.localizedDescription)")
                setDictationState(.failed(wrapped))
                lastErrorMessage = wrapped.errorDescription
                isRecording = false
                detectedContextKind = nil
            }
        }
    }

    func cycleContextMode() {
        let allCases = PromptContextKind.allCases
        if let current = manualContextKind, let index = allCases.firstIndex(of: current) {
            let nextIndex = allCases.index(after: index)
            if nextIndex >= allCases.endIndex {
                manualContextKind = allCases.first
            } else {
                manualContextKind = allCases[nextIndex]
            }
        } else {
            manualContextKind = allCases.first
        }
    }

    func resetContextMode() {
        manualContextKind = nil
    }

    private func beginDictation() async throws {
        lastErrorMessage = nil
        DebugLogger.log("beginDictation")
        setDictationState(.listening)
        try await coordinator.beginRecording()
        isRecording = true
        DebugLogger.log("recording started")
    }

    private func finishDictation() async throws {
        setDictationState(.transcribing)
        let transcript = try await coordinator.completeRecording()
        DebugLogger.log("transcript received: \(transcript)")
        isRecording = false

        if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            DebugLogger.log("transcript empty after trim")
            setDictationState(.failed(.noSpeechDetected))
            lastErrorMessage = WhispyError.noSpeechDetected.errorDescription
            return
        }

        let context: PromptContext
        if let manualKind = manualContextKind, manualKind != .autodetect {
            DebugLogger.log("using manual context: \(manualKind.rawValue)")
            context = PromptContext(kind: manualKind, appName: nil)
        } else {
            context = coordinator.detectContext(for: transcript)
            DebugLogger.log("context detected: \(context.kind.rawValue) app=\(context.appName ?? "nil")")
        }
        detectedContextKind = context.kind
        setDictationState(.rewriting)
        let rewrittenText = try await coordinator.rewrite(transcript, context: context)
        DebugLogger.log("rewritten text received: \(rewrittenText)")

        setDictationState(.inserting)
        try await coordinator.insert(rewrittenText)
        DebugLogger.log("insert completed")

        setDictationState(.completed)
    }

    private func setDictationState(_ state: DictationState) {
        DebugLogger.log("state -> \(String(describing: state))")
        dictationState = state

        switch state {
        case .listening:
            menuBarIconName = "mic.fill"
            overlayController.show(.listening)
        case .transcribing, .rewriting, .inserting:
            menuBarIconName = "arrow.triangle.2.circlepath"
            overlayController.show(.processing(detectedContextKind, isManual: manualContextKind != nil && manualContextKind != .autodetect))
        case .idle, .completed, .failed:
            menuBarIconName = "waveform.badge.mic"
            overlayController.hide()
            detectedContextKind = nil
        }
    }
}
