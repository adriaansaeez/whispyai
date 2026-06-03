struct DictationCoordinator: Sendable {
    private let speechService: SpeechRecognizing
    private let promptEngine: PromptBuilding
    private let contextDetector: PromptContextDetector
    private let providerRegistry: AIProviderRegistry
    private let accessibilityService: AccessibilityServicing
    private let latencyTracker: LatencyTracker

    init(
        speechService: SpeechRecognizing,
        promptEngine: PromptBuilding,
        contextDetector: PromptContextDetector,
        providerRegistry: AIProviderRegistry,
        accessibilityService: AccessibilityServicing,
        latencyTracker: LatencyTracker
    ) {
        self.speechService = speechService
        self.promptEngine = promptEngine
        self.contextDetector = contextDetector
        self.providerRegistry = providerRegistry
        self.accessibilityService = accessibilityService
        self.latencyTracker = latencyTracker
    }

    func beginRecording() async throws {
        await latencyTracker.mark("hotkey")
        DebugLogger.log("capturing insertion target")
        try await MainActor.run {
            try accessibilityService.captureInsertionTarget()
        }
        DebugLogger.log("insertion target captured")
        try await speechService.startRecording()
    }

    func completeRecording() async throws -> String {
        let transcript = try await speechService.stopRecording()
        await latencyTracker.mark("transcript")
        return transcript
    }

    func detectContext(for transcript: String) -> PromptContext {
        contextDetector.detect(for: transcript)
    }

    func rewrite(_ transcript: String, context: PromptContext) async throws -> String {
        DebugLogger.log("building prompt for context=\(context.kind.rawValue)")
        let prompt = promptEngine.makePrompt(for: transcript, context: context)
        let provider = try providerRegistry.currentProvider()
        let rewrittenText = try await provider.transform(text: transcript, prompt: prompt)
        await latencyTracker.mark("rewrite")
        return rewrittenText
    }

    func insert(_ text: String) async throws {
        DebugLogger.log("attempting insert; text length=\(text.count)")
        try await accessibilityService.insert(text: text)
        await latencyTracker.mark("insert")
    }
}
