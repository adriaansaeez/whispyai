import AVFoundation
import Speech

final class SpeechService: NSObject, SpeechRecognizing, @unchecked Sendable {
    private let recognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var finalContinuation: CheckedContinuation<String, any Error>?
    private var finalTranscript = ""
    private var isEngineRunning = false
    private var didDetectSpeech = false

    override init() {
        if let recognizer = SFSpeechRecognizer() {
            self.recognizer = recognizer
        } else {
            self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
        }
        super.init()
        recognizer.delegate = self
    }

    func requestPermissions() async throws {
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch micStatus {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if !granted { throw WhispyError.microphonePermissionDenied }
        case .denied, .restricted:
            throw WhispyError.microphonePermissionDenied
        case .authorized:
            break
        @unknown default:
            throw WhispyError.microphonePermissionDenied
        }

        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        switch speechStatus {
        case .notDetermined:
            let status = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
            if status != .authorized { throw WhispyError.speechPermissionDenied }
        case .denied, .restricted:
            throw WhispyError.speechPermissionDenied
        case .authorized:
            break
        @unknown default:
            throw WhispyError.speechPermissionDenied
        }
    }

    func startRecording() async throws {
        try await requestPermissions()

        cancelExistingTask()

        guard recognizer.isAvailable else {
            throw WhispyError.speechUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false
        recognitionRequest = request

        finalTranscript = ""
        didDetectSpeech = false

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let error = error {
                if finalContinuation != nil {
                    finalContinuation?.resume(throwing: mapRecognitionError(error))
                    finalContinuation = nil
                }
                return
            }

            guard let result else { return }

            didDetectSpeech = true
            finalTranscript = result.bestTranscription.formattedString

            if result.isFinal {
                finalContinuation?.resume(returning: finalTranscript)
                finalContinuation = nil
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isEngineRunning = true
    }

    func stopRecording() async throws -> String {
        audioEngine.stop()
        isEngineRunning = false
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        return try await withCheckedThrowingContinuation { continuation in
            if recognitionTask?.state == .completed {
                if didDetectSpeech {
                    continuation.resume(returning: finalTranscript)
                } else {
                    continuation.resume(throwing: WhispyError.noSpeechDetected)
                }
            } else {
                finalContinuation = continuation
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    guard let finalContinuation = self.finalContinuation else { return }

                    if didDetectSpeech, !finalTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        finalContinuation.resume(returning: finalTranscript)
                    } else {
                        finalContinuation.resume(throwing: WhispyError.noSpeechDetected)
                    }
                    self.finalContinuation = nil
                }
            }
        }
    }

    func checkIfRecording() async -> Bool {
        isEngineRunning
    }

    private func cancelExistingTask() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        isEngineRunning = false
        finalContinuation?.resume(throwing: CancellationError())
        finalContinuation = nil
    }

    private func mapRecognitionError(_ error: any Error) -> any Error {
        let nsError = error as NSError

        if nsError.domain == "kAFAssistantErrorDomain" {
            switch nsError.code {
            case 1110, 1117, 203:
                return WhispyError.noSpeechDetected
            case 1101:
                return WhispyError.speechCancelled
            default:
                break
            }
        }

        return error
    }
}

extension SpeechService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            cancelExistingTask()
        }
    }
}
