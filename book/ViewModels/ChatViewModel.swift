//
//  ChatViewModel.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var currentStreamingMessage = ""
    
    private let apiService = GroqAPIService()
    private var streamingTask: Task<Void, Never>?
    
    func sendMessage(_ text: String) {
        let userMessage = Message(text: text, isUser: true)
        messages.append(userMessage)
        
        isLoading = true
        currentStreamingMessage = ""
        
        streamingTask = Task {
            do {
                try await apiService.streamMessage(text) { [weak self] chunk in
                    self?.currentStreamingMessage = chunk
                }
                
                // Add final message
                if !currentStreamingMessage.isEmpty {
                    let aiMessage = Message(text: currentStreamingMessage, isUser: false)
                    messages.append(aiMessage)
                    currentStreamingMessage = ""
                }
                
                isLoading = false
            } catch {
                let errorMessage = Message(text: "Error: \(error.localizedDescription)", isUser: false)
                messages.append(errorMessage)
                currentStreamingMessage = ""
                isLoading = false
            }
        }
    }
    
    func sendMessageWithPrompt(_ compiledPrompt: String) {
        // Don't add user message here, it's already added in ChatView
        isLoading = true
        currentStreamingMessage = ""
        
        streamingTask = Task {
            do {
                try await apiService.streamMessage(compiledPrompt) { [weak self] chunk in
                    self?.currentStreamingMessage = chunk
                }
                
                // Add final message
                if !currentStreamingMessage.isEmpty {
                    let aiMessage = Message(text: currentStreamingMessage, isUser: false)
                    messages.append(aiMessage)
                    currentStreamingMessage = ""
                }
                
                isLoading = false
            } catch {
                let errorMessage = Message(text: "Error: \(error.localizedDescription)", isUser: false)
                messages.append(errorMessage)
                currentStreamingMessage = ""
                isLoading = false
            }
        }
    }
    
    func stopStreaming() {
        streamingTask?.cancel()
        
        // Save current streaming message if any
        if !currentStreamingMessage.isEmpty {
            let aiMessage = Message(text: currentStreamingMessage, isUser: false)
            messages.append(aiMessage)
            currentStreamingMessage = ""
        }
        
        isLoading = false
    }
    
    func clearChat() {
        messages.removeAll()
        currentStreamingMessage = ""
        isLoading = false
        streamingTask?.cancel()
    }
}
