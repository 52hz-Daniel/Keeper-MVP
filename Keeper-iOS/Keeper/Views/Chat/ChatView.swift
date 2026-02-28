import SwiftUI

// MARK: - Chat View
// Reference: MPID "The Chat Interface (Trunk)"
// Design: WhatsApp/iMessage style with user bubbles on right, AI on left

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color.midnightSlate
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Chat Messages
                messagesView
                
                // Input Area (Bottom 30% - Thumb Zone)
                inputArea
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $viewModel.showingEditSheet) {
            if let log = viewModel.logToEdit {
                LogDetailView(
                    log: log,
                    onSave: { updatedLog in
                        viewModel.saveEditedLog(updatedLog)
                    },
                    onDelete: {
                        if let id = viewModel.logToEdit?.id {
                            viewModel.messages.removeAll { $0.log?.id == id }
                        }
                        viewModel.showingEditSheet = false
                    }
                )
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Keeper")
                    .font(.system(size: KeeperConstants.UI.titleSize, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                Text("Chief of Staff")
                    .font(.system(size: KeeperConstants.UI.smallTextSize))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
            
            // Partner status indicator (placeholder)
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.safeGreen)
                    .frame(width: 8, height: 8)
                Text("Partner Online")
                    .font(.system(size: KeeperConstants.UI.smallTextSize))
                    .foregroundColor(.dimStar)
            }
        }
        .padding(.horizontal, KeeperConstants.UI.padding)
        .padding(.vertical, 12)
        .background(Color.deepSlate)
    }
    
    // MARK: - Messages
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Empty state
                    if viewModel.messages.isEmpty {
                        emptyState
                    }
                    
                    // Messages (reversed for chat style)
                    ForEach(viewModel.messages.reversed()) { message in
                        messageRow(message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, KeeperConstants.UI.padding)
                .padding(.vertical, 12)
                .padding(.bottom, KeeperConstants.UI.bottomSafeArea)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 60)
            
            // Pulsing mic indicator
            ZStack {
                Circle()
                    .fill(Color.moonlightLavender.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.moonlightLavender.opacity(0.3))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.moonlightLavender)
            }
            .accessibilityIdentifier("emptyStateMic")
            
            Text("No logs yet")
                .font(.system(size: KeeperConstants.UI.baseTextSize))
                .foregroundColor(.dimStar)
            
            Text("Try speaking or typing:")
                .font(.system(size: KeeperConstants.UI.smallTextSize))
                .foregroundColor(.dimStar)
            
            // Quick action chips
            HStack(spacing: 12) {
                QuickActionChip(text: "Ate 4oz") {
                    Task { await viewModel.sendQuickAction("Ate 4oz") }
                }
                
                QuickActionChip(text: "Fell asleep") {
                    Task { await viewModel.sendQuickAction("Fell asleep") }
                }
                
                QuickActionChip(text: "Diaper change") {
                    Task { await viewModel.sendQuickAction("Diaper change") }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Message Row
    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        switch message.role {
        case .user:
            userBubble(message)
        case .ai:
            if let log = message.log {
                GhostLogCard(
                    log: log,
                    onConfirm: { viewModel.confirmLog(messageId: message.id) },
                    onEdit: { viewModel.editLog(messageId: message.id) }
                )
            }
        case .system:
            processingBubble
        }
    }
    
    // MARK: - User Bubble
    private func userBubble(_ message: ChatMessage) -> some View {
        HStack {
            Spacer()
            
            Text(message.text ?? "")
                .font(.system(size: KeeperConstants.UI.baseTextSize))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.moonlightLavender)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .clipShape(
                    .rect(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 4,
                        topTrailingRadius: 20
                    )
                )
        }
        .accessibilityIdentifier("userMessage")
    }
    
    // MARK: - Processing Bubble
    private var processingBubble: some View {
        HStack {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.dimStar)
                
                Text("Thinking...")
                    .font(.system(size: KeeperConstants.UI.baseTextSize))
                    .foregroundColor(.dimStar)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            Spacer()
        }
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.slateGray)
            
            HStack(spacing: 12) {
                // Text Input
                TextField("Log something...", text: $viewModel.inputText)
                    .font(.system(size: KeeperConstants.UI.baseTextSize))
                    .foregroundColor(.starlightCream)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.deepSlate)
                    .clipShape(Capsule())
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        Task { await viewModel.sendMessage() }
                    }
                    .accessibilityIdentifier("messageInput")
                
                // Send or Mic Button
                if viewModel.inputText.isEmpty {
                    MicButton(
                        isRecording: viewModel.isRecording,
                        action: viewModel.toggleRecording
                    )
                } else {
                    SendButton {
                        Task { await viewModel.sendMessage() }
                    }
                }
            }
            .padding(.horizontal, KeeperConstants.UI.padding)
            .padding(.vertical, 12)
            .background(Color.midnightSlate)
        }
    }
}

// MARK: - Quick Action Chip
struct QuickActionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: KeeperConstants.UI.smallTextSize, weight: .medium))
                .foregroundColor(.moonlightLavender)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.moonlightLavender.opacity(0.15))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.moonlightLavender.opacity(0.3), lineWidth: 1)
                )
        }
        .accessibilityIdentifier("quickAction_\(text)")
    }
}

// MARK: - Send Button
struct SendButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.moonlightLavender)
        }
        .frame(width: KeeperConstants.UI.minTouchTarget, height: KeeperConstants.UI.minTouchTarget)
        .accessibilityIdentifier("sendButton")
    }
}

// MARK: - Preview
#Preview {
    ChatView()
        .environmentObject(ChatViewModel.preview)
}

