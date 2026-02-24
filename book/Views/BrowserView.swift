//
//  BrowserView.swift
//  book
//
//  Created by Kiro AI
//

import SwiftUI
import WebKit

struct BrowserView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var webViewStore: WebViewStore
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @ObservedObject var screenshotService: ScreenshotService
    @State private var chatMessage: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack(spacing: 12) {
                // Back button
                Button(action: {
                    webViewStore.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16))
                        .foregroundColor(viewModel.canGoBack ? .white : .gray)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canGoBack)
                
                // Forward button
                Button(action: {
                    webViewStore.goForward()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                        .foregroundColor(viewModel.canGoForward ? .white : .gray)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canGoForward)
                
                // Reload button
                Button(action: {
                    webViewStore.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                
                // URL TextField
                TextField("Enter URL", text: $viewModel.urlText)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .onSubmit {
                        viewModel.loadURL(viewModel.urlText)
                    }
                
                // Go button
                Button(action: {
                    viewModel.loadURL(viewModel.urlText)
                }) {
                    Text("Go")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                // Clear data button (for login issues)
                Button(action: {
                    webViewStore.clearAllData()
                    // Reload current page after clearing data
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        webViewStore.reload()
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .help("Clear all data (cookies, login sessions)")
                
                // Close button
                Button(action: {
                    // Clear screenshots when closing browser
                    screenshotService.clearScreenshots()
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            
            // Linear progress bar (Chrome-style)
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 3)
                
                if viewModel.isLoading {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }
            }
            
            // Web content area
            WebViewWrapper(
                url: .constant(nil), // Don't use URL binding anymore
                isLoading: $viewModel.isLoading,
                canGoBack: $viewModel.canGoBack,
                canGoForward: $viewModel.canGoForward,
                webViewStore: webViewStore,
                onChatGPTReady: {
                    print("🎉 ChatGPT is ready for native input!")
                }
            )
            .background(Color.white)
            
            // Native ChatGPT Input (only show when ChatGPT is ready)
            if webViewStore.isChatGPTReady {
                VStack(spacing: 0) {
                    // Simple grey separator line
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    
                    // Native input area matching ChatGPT's design
                    HStack(spacing: 12) {
                        // Microphone button
                        Button(action: {
                            if speechRecognizer.isRecording {
                                // Stop recording and send immediately
                                let currentText = chatMessage.trimmingCharacters(in: .whitespaces)
                                speechRecognizer.stopRecording()
                                
                                // Send immediately without waiting for AI correction
                                if !currentText.isEmpty {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        sendMessageToChatGPT()
                                    }
                                }
                            } else {
                                // Clear any previous text and start recording
                                chatMessage = ""
                                webViewStore.duckAudio()
                                speechRecognizer.startRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(speechRecognizer.isRecording ? Color.red : Color.gray.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                
                                if speechRecognizer.isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                                        .font(.system(size: 16))
                                        .foregroundColor(speechRecognizer.isRecording ? .white : .primary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help(speechRecognizer.isRecording ? "Stop and send" : "Start voice input")
                        
                        // Single screenshot button (always visible)
                        Button(action: {
                            Task {
                                await screenshotService.takeScreenshot()
                                // Send the latest screenshot to ChatGPT
                                if let latestScreenshot = screenshotService.screenshots.last {
                                    webViewStore.sendImageToChatGPT(latestScreenshot)
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "camera")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Take screenshot and send to ChatGPT")
                        
                        // Input field container (matching ChatGPT's style)
                        HStack(spacing: 8) {
                            // Text input
                            TextField("Message ChatGPT", text: $chatMessage, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .lineLimit(1...6)
                                .padding(.vertical, 12)
                                .padding(.leading, 16)
                                .onSubmit {
                                    sendMessageToChatGPT()
                                }
                                .disabled(speechRecognizer.isRecording || speechRecognizer.isProcessing)
                            
                            // Send button (only show when there's text and not recording)
                            if !chatMessage.trimmingCharacters(in: .whitespaces).isEmpty && !speechRecognizer.isRecording && !speechRecognizer.isProcessing {
                                Button(action: {
                                    sendMessageToChatGPT()
                                }) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(
                                            Circle()
                                                .fill(Color.black)
                                        )
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 8)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(NSColor.windowBackgroundColor))
                    .animation(.easeInOut(duration: 0.2), value: speechRecognizer.isRecording)
                    .animation(.easeInOut(duration: 0.2), value: speechRecognizer.isProcessing)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: webViewStore.isChatGPTReady)
            }
        }
        .onAppear {
            // Connect WebViewStore to ViewModel
            viewModel.webViewStore = webViewStore
            
            // Auto-load ChatGPT
            if viewModel.urlText.isEmpty {
                viewModel.urlText = "chatgpt.com"
                viewModel.loadURL(viewModel.urlText)
            }
            
            // Setup speech recognizer callbacks
            speechRecognizer.onTranscriptUpdate = { transcript in
                chatMessage = transcript
            }
            
            // Don't use onCorrectedTranscript for auto-send in browser
            // User will manually click mic button to stop and send
            speechRecognizer.onCorrectedTranscript = nil
            
            speechRecognizer.onRecordingStop = {
                // When mic stops, restore audio
                webViewStore.restoreAudio()
            }
        }
        .onDisappear {
            // Clean up callbacks when leaving browser
            speechRecognizer.onTranscriptUpdate = nil
            speechRecognizer.onCorrectedTranscript = nil
            speechRecognizer.onRecordingStop = nil
        }
    }
    
    private func sendMessageToChatGPT() {
        let message = chatMessage.trimmingCharacters(in: .whitespaces)
        guard !message.isEmpty else { return }
        
        print("📤 Sending message directly to ChatGPT: \(message)")
        webViewStore.sendMessageToChatGPT(message)
        
        // Clear input immediately
        chatMessage = ""
    }
}
