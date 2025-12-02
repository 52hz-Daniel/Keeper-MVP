import Foundation
import Speech
import AVFoundation

// MARK: - Speech Service
// Apple Speech Framework integration for voice-to-text
// Reference: MPID "Voice-First" architecture

@MainActor
final class SpeechService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isAuthorized = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Singleton
    static let shared = SpeechService()
    
    private init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    /// Check and request speech recognition authorization
    func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                switch status {
                case .authorized:
                    self?.isAuthorized = true
                case .denied:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition access denied"
                case .restricted:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition restricted on this device"
                case .notDetermined:
                    self?.isAuthorized = false
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
    }
    
    // MARK: - Recording Controls
    
    /// Start recording and transcribing speech
    func startRecording() async throws {
        guard isAuthorized else {
            throw SpeechError.notAuthorized
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerNotAvailable
        }
        
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }
        
        // Configure request
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Get input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        transcribedText = ""
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.stopRecording()
                }
                
                if result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }
        
        // Haptic feedback
        HapticsService.shared.recordingStarted()
    }
    
    /// Stop recording and return final transcription
    func stopRecording() -> String {
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        
        // Haptic feedback
        HapticsService.shared.recordingStopped()
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        return transcribedText
    }
    
    /// Toggle recording state
    func toggleRecording() async -> String? {
        if isRecording {
            return stopRecording()
        } else {
            do {
                try await startRecording()
                return nil
            } catch {
                errorMessage = error.localizedDescription
                return nil
            }
        }
    }
}

// MARK: - Speech Errors
enum SpeechError: Error, LocalizedError {
    case notAuthorized
    case recognizerNotAvailable
    case requestCreationFailed
    case audioSessionError
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized. Please enable in Settings."
        case .recognizerNotAvailable:
            return "Speech recognition not available on this device."
        case .requestCreationFailed:
            return "Could not create speech recognition request."
        case .audioSessionError:
            return "Could not configure audio session."
        }
    }
}

// MARK: - Preview Helper
extension SpeechService {
    static var preview: SpeechService {
        let service = SpeechService.shared
        service.isAuthorized = true
        return service
    }
}

