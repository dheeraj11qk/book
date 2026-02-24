//
//  ChatView.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var screenshotService = ScreenshotService()
    @StateObject private var captureObserver = ScreenCaptureObserver()
    @StateObject private var autoTyperViewModel = AutoTyperViewModel()
    @StateObject private var browserViewModel = BrowserViewModel()
    @StateObject private var webViewStore = WebViewStore()
    @State private var inputText: String = ""
    @State private var showingSettings = false
    @State private var showingBrowser = false
    @State private var randomGreeting: String = ""
    @State private var hasScrolledToStreamStart = false
    
    private var shareBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.white)
        #endif
    }
    
    private var isHiding: Bool {
        // Only hide from capture when toggle is ON, but user can always see their content
        // The hiding only affects screen capture/recording, not the user's view
        false // User always sees content
    }
    
    private var shouldHideFromCapture: Bool {
        UserDefaults.standard.hideFromCapture
    }
    
    private let greetings = [
        "Hey there",
        "What's up?",
        "How's it going?",
        "How are things?",
        "What's going on?",
        "How's everything?",
        "What's new?",
        "How've you been?",
        "What's happening?",
        "How's life?"
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            if isHiding {
                // This should never show since isHiding is always false
                // User always sees their content
                shareBackground
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "eye.slash.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Content Hidden During Screen Share")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            } else {
                // Normal chat interface - user always sees this
                VStack(spacing: 0) {
                    // Top bar with settings, auto-type overlay, and reset button (only show when browser is closed)
                    if !showingBrowser {
                        HStack {
                            // Settings button
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            .buttonStyle(.plain)
                            
                            // Browser button
                            Button(action: {
                                showingBrowser.toggle()
                            }) {
                                Image(systemName: "safari")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            // Auto Type Overlay - centered between settings and reset
                            if let clipboardText = autoTyperViewModel.clipboardText, !clipboardText.isEmpty {
                                AutoTypeOverlay(viewModel: autoTyperViewModel)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.clearChat()
                                screenshotService.clearScreenshots()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    
                    // Conditional content area
                    if showingBrowser {
                        // Browser view
                        BrowserView(
                            isPresented: $showingBrowser,
                            viewModel: browserViewModel,
                            webViewStore: webViewStore,
                            speechRecognizer: speechRecognizer,
                            screenshotService: screenshotService
                        )
                    } else {
                        // Chat messages area
                        ScrollViewReader { proxy in
                        ScrollView {
                            if viewModel.messages.isEmpty && viewModel.currentStreamingMessage.isEmpty {
                                // Empty state
                                VStack {
                                    
                                    Spacer()
                                    Text(randomGreeting)
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                VStack(spacing: 16) {
                                    ForEach(viewModel.messages) { message in
                                        MessageBubbleView(message: message)
                                            .id(message.id)
                                    }
                                    
                                    // Streaming message with loader
                                    if viewModel.isLoading {
                                        if viewModel.currentStreamingMessage.isEmpty {
                                            // Show loader when streaming starts
                                            HStack {
                                                ThreeDotsLoader()
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .id("loader")
                                        } else {
                                            // Show streaming message
                                            MessageBubbleView(
                                                message: Message(text: viewModel.currentStreamingMessage, isUser: false)
                                            )
                                            .id("streaming")
                                        }
                                    }
                                }
                                .padding(16)
                            }
                        }
                        .privacySensitive(shouldHideFromCapture)
                        .onChange(of: viewModel.messages.count) {
                            // Auto-scroll only when user sends message (not when AI response completes)
                            // Check if the last message is from user
                            if let lastMessage = viewModel.messages.last, lastMessage.isUser {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                            // Reset flag when new message arrives
                            hasScrolledToStreamStart = false
                        }
                        .onChange(of: viewModel.currentStreamingMessage) {
                            // Auto-scroll ONCE when streaming starts (first chunk arrives)
                            if viewModel.isLoading && !viewModel.currentStreamingMessage.isEmpty && !hasScrolledToStreamStart {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo("streaming", anchor: .bottom)
                                }
                                hasScrolledToStreamStart = true
                            }
                        }
                    } // closes ScrollViewReader
                    } // closes else
                    
                    // Divider and Input area (only show when not in browser mode)
                    if !showingBrowser {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        // Input area
                        InputBarView(
                        inputText: $inputText,
                        isRecording: speechRecognizer.isRecording,
                        isProcessing: speechRecognizer.isProcessing,
                        isLoading: viewModel.isLoading,
                        screenshots: screenshotService.screenshots,
                        systemAudioOnly: false,
                        onMicTap: {
                            if speechRecognizer.isRecording {
                                speechRecognizer.stopRecording()
                            } else {
                                // Duck audio before starting recording
                                webViewStore.duckAudio()
                                speechRecognizer.startRecording()
                            }
                        },
                        onScreenshotTap: {
                            Task {
                                await screenshotService.takeScreenshot()
                            }
                        },
                        onRemoveScreenshot: { index in
                            screenshotService.removeScreenshot(at: index)
                        },
                        onSend: {
                            sendMessage()
                        },
                        onStop: {
                            viewModel.stopStreaming()
                        }
                    )
                    .privacySensitive(shouldHideFromCapture)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .privacySensitive()
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            // Set random greeting when app opens
            randomGreeting = greetings.randomElement() ?? "Hey there"
            
            // Start auto-typer monitoring
            autoTyperViewModel.startMonitoring()
            
            speechRecognizer.requestAuthorization()
            speechRecognizer.onTranscriptUpdate = { transcript in
                inputText = transcript
            }
            speechRecognizer.onCorrectedTranscript = { correctedText in
                // Update input with corrected text
                inputText = correctedText
                
                // Auto-send after correction is complete
                if !correctedText.trimmingCharacters(in: .whitespaces).isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        sendMessage()
                    }
                }
            }
            speechRecognizer.onRecordingStop = {
                // When mic stops, restore audio and wait for AI correction
                webViewStore.restoreAudio()
                // The corrected text will be handled by onCorrectedTranscript
            }
            
            #if canImport(AppKit)
            captureObserver.updateWindowSharingType(isHidden: shouldHideFromCapture)
            #endif
        }
        .onDisappear {
            // Stop auto-typer monitoring when view disappears
            autoTyperViewModel.stopMonitoring()
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty || !screenshotService.screenshots.isEmpty else { return }
        guard !viewModel.isLoading else { return }
        
        // Check if we have screenshots
        if !screenshotService.screenshots.isEmpty {
            // Send with images
            let messageText = text.isEmpty ? "Analyze this image" : text
            viewModel.sendMessageWithImages(messageText, images: screenshotService.screenshots)
            
            // Clear input and screenshots
            inputText = ""
            screenshotService.clearScreenshots()
        } else {
            // Send text only
            viewModel.sendMessage(text)
            
            // Clear input immediately
            inputText = ""
        }
    }
}

// Three dots loader animation
struct ThreeDotsLoader: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(12)
        .onAppear {
            animating = true
        }
    }
}
