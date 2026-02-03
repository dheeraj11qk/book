//
//  ChatViewModel.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import Foundation
import Combine
import AppKit

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var currentStreamingMessage = ""
    
    private let apiService = OpenAIService()
    private var streamingTask: Task<Void, Never>?
    
    func sendMessage(_ text: String, model: AIModel = .gpt35Turbo) {
        let userMessage = Message(text: text, isUser: true)
        messages.append(userMessage)
        
        isLoading = true
        currentStreamingMessage = ""
        
        streamingTask = Task {
            do {
                try await apiService.streamMessage(text, model: model) { [weak self] chunk in
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
    
    func sendMessageWithPrompt(_ compiledPrompt: String, model: AIModel) {
        // Don't add user message here, it's already added in ChatView
        isLoading = true
        currentStreamingMessage = ""
        
        streamingTask = Task {
            do {
                try await apiService.streamMessage(compiledPrompt, model: model) { [weak self] chunk in
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
    
    func sendMessageWithImages(_ text: String, images: [NSImage]) {
        let userMessage = Message(text: text, isUser: true, images: images)
        messages.append(userMessage)
        
        isLoading = true
        currentStreamingMessage = ""
        
        streamingTask = Task {
            do {
                // Use GPT-4o Mini for vision tasks
                if let firstImage = images.first {
                    try await apiService.sendMessageWithImage(text, image: firstImage, model: .gpt4oMini) { [weak self] chunk in
                        self?.currentStreamingMessage = chunk
                    }
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
    
    func sendMessageWithImagesAndPrompt(_ compiledPrompt: String, images: [NSImage]) {
        // Show user message with images
        let userMessage = Message(text: compiledPrompt.components(separatedBy: "User question/problem:").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Analyze this image", isUser: true, images: images)
        messages.append(userMessage)
        
        isLoading = true
        currentStreamingMessage = ""
        
        streamingTask = Task {
            do {
                // Use GPT-4o Mini for vision tasks with compiled prompt
                if let firstImage = images.first {
                    try await apiService.sendMessageWithImage(compiledPrompt, image: firstImage, model: .gpt4oMini) { [weak self] chunk in
                        self?.currentStreamingMessage = chunk
                    }
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
