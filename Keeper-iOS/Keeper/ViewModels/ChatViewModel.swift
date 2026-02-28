import Foundation
import SwiftUI

// MARK: - Chat View Model
// Reference: MPID "The "Ghost Log" Protocol (Core Feature)"

@MainActor
final class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var currentStage: KeeperConstants.Stage = .infant
    @Published var logToEdit: Log?
    @Published var showingEditSheet: Bool = false
    
    // Mock child age for demo (3 months old)
    @Published var childAgeInMonths: Int = 3
    @Published var transcribedText: String = ""
    @Published var isSpeechAuthorized: Bool = false
    
    // MARK: - Services
    private let openAI = OpenAIService.shared
    private let safetyService = SafetyService.shared
    private let haptics = HapticsService.shared
    private let speechService = SpeechService.shared
    private let supabase = SupabaseService.shared
    private let logStore = LogStore.shared
    
    // MARK: - Mock Data
    private let mockFamilyId = UUID()
    private let mockUserId = UUID()
    
    // MARK: - Send Message
    
    /// Send a text message and process it through AI
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Clear input
        inputText = ""
        haptics.messageSent()
        
        // 1. Add user message (Optimistic UI)
        let userMessage = ChatMessage.user(text)
        messages.insert(userMessage, at: 0)
        
        // 2. Show processing indicator
        isProcessing = true
        let processingMessage = ChatMessage.processing()
        messages.insert(processingMessage, at: 0)
        
        do {
            // 3. Parse with AI
            let parsed = try await openAI.parseLog(text: text, stage: currentStage)
            
            // 4. Create log data
            let logData = parsed.toLogData()
            let eventType = parsed.toEventType()
            
            // 5. Run safety check (HARD-CODED RULES)
            var safetyResult = SafetyCheckResult.safe
            if eventType.isMedical {
                safetyResult = safetyService.checkSafety(
                    logData: logData,
                    childAgeInMonths: childAgeInMonths,
                    stage: currentStage
                )
                
                // Provide haptic feedback for safety warnings
                haptics.feedback(for: safetyResult)
            }
            
            // 6. Create the Ghost Log (unconfirmed)
            var updatedLogData = logData
            if !safetyResult.isSafe {
                // Add safety warning to log data
                updatedLogData = LogData(
                    event: logData.event,
                    subtype: logData.subtype,
                    amount: logData.amount,
                    unit: logData.unit,
                    drug: logData.drug,
                    time: logData.time,
                    warning: safetyResult.warning,
                    notes: logData.notes
                )
            }
            
            let ghostLog = Log(
                familyId: mockFamilyId,
                creatorId: mockUserId,
                stageContext: currentStage,
                eventType: eventType,
                rawText: text,
                structuredData: updatedLogData,
                isConfirmed: false
            )
            
            // 7. Remove processing indicator and add ghost log
            messages.removeAll { $0.isProcessing }
            let ghostMessage = ChatMessage.ghostLog(ghostLog)
            messages.insert(ghostMessage, at: 0)
            
        } catch {
            // Handle error gracefully
            messages.removeAll { $0.isProcessing }
            
            // Create failed log for manual entry
            let failedLog = Log(
                familyId: mockFamilyId,
                creatorId: mockUserId,
                stageContext: currentStage,
                eventType: .note,
                rawText: text,
                structuredData: LogData(
                    event: "note",
                    subtype: nil,
                    amount: nil,
                    unit: nil,
                    drug: nil,
                    time: Date(),
                    warning: "Transcription failed. Tap to edit.",
                    notes: text
                ),
                isConfirmed: false
            )
            
            let errorMessage = ChatMessage.ghostLog(failedLog)
            messages.insert(errorMessage, at: 0)
            
            haptics.error()
        }
        
        isProcessing = false
    }
    
    // MARK: - Confirm Log
    
    /// Confirm a ghost log and save to database
    func confirmLog(messageId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }),
              var log = messages[index].log else { return }
        
        // Mark as confirmed
        log.isConfirmed = true
        log.clientUpdatedAt = Date()
        
        // Update message
        messages[index] = ChatMessage(
            id: messageId,
            role: .ai,
            log: log,
            timestamp: messages[index].timestamp
        )
        
        // Save to local store
        logStore.addLog(log)
        
        // Save to Supabase
        Task {
            do {
                let supabaseLog = SupabaseLog(from: log)
                _ = try await supabase.createLog(supabaseLog)
                print("✅ Log saved to Supabase: \(log.id)")
            } catch {
                print("⚠️ Failed to save to Supabase: \(error)")
                // Note: Log is still shown locally even if sync fails
            }
        }
        
        // Haptic feedback
        haptics.logConfirmed()
    }
    
    // MARK: - Edit Log
    
    /// Open edit mode for a log
    func editLog(messageId: UUID) {
        guard let message = messages.first(where: { $0.id == messageId }),
              let log = message.log else { return }
        
        logToEdit = log
        showingEditSheet = true
    }
    
    /// Save edited log
    func saveEditedLog(_ updatedLog: Log) {
        // Update in messages
        if let index = messages.firstIndex(where: { $0.log?.id == updatedLog.id }) {
            messages[index] = ChatMessage(
                id: messages[index].id,
                role: .ai,
                log: updatedLog,
                timestamp: messages[index].timestamp
            )
        }
        
        // Save to store
        logStore.updateLog(updatedLog)
        
        // Sync to Supabase
        Task {
            do {
                let supabaseLog = SupabaseLog(from: updatedLog)
                _ = try await supabase.createLog(supabaseLog)
                print("✅ Updated log saved to Supabase: \(updatedLog.id)")
            } catch {
                print("⚠️ Failed to save update to Supabase: \(error)")
            }
        }
        
        haptics.logConfirmed()
        showingEditSheet = false
        logToEdit = nil
    }
    
    /// Delete a log
    func deleteLog(messageId: UUID) {
        guard let message = messages.first(where: { $0.id == messageId }),
              let log = message.log else { return }
        
        // Remove from messages
        messages.removeAll { $0.id == messageId }
        
        // Remove from store
        logStore.deleteLog(log)
        
        haptics.lightTap()
    }
    
    // MARK: - Recording (Speech-to-Text)
    
    func toggleRecording() {
        Task {
            if isRecording {
                // Stop recording and get transcription
                let text = speechService.stopRecording()
                isRecording = false
                
                if !text.isEmpty {
                    inputText = text
                    await sendMessage()
                }
            } else {
                // Start recording
                do {
                    try await speechService.startRecording()
                    isRecording = true
                    
                    // Observe transcription updates
                    Task {
                        for await _ in Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().values {
                            if speechService.isRecording {
                                transcribedText = speechService.transcribedText
                            } else {
                                break
                            }
                        }
                    }
                } catch {
                    print("Speech recording error: \(error)")
                    haptics.error()
                }
            }
        }
    }
    
    /// Check speech authorization on init
    func checkSpeechAuthorization() {
        speechService.checkAuthorization()
        isSpeechAuthorized = speechService.isAuthorized
    }
    
    // MARK: - Quick Actions (Chip buttons)
    
    func sendQuickAction(_ text: String) async {
        inputText = text
        await sendMessage()
    }
}

// MARK: - Preview Helper
extension ChatViewModel {
    static var preview: ChatViewModel {
        let vm = ChatViewModel()
        
        // Add some sample messages
        let sampleLog = Log(
            familyId: UUID(),
            creatorId: UUID(),
            stageContext: .infant,
            eventType: .feed,
            rawText: "He drank 4oz of formula",
            structuredData: LogData(
                event: "feed",
                subtype: "formula",
                amount: 4,
                unit: "oz",
                drug: nil,
                time: Date(),
                warning: nil,
                notes: nil
            ),
            isConfirmed: false
        )
        
        vm.messages = [
            ChatMessage.ghostLog(sampleLog),
            ChatMessage.user("He drank 4oz of formula")
        ]
        
        return vm
    }
}

