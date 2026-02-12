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
    private let ragService = InMemoryRAGService()
    private var streamingTask: Task<Void, Never>?
    
    func sendMessage(_ text: String, model: AIModel = .gpt4Turbo) {
        let userMessage = Message(text: text, isUser: true)
        messages.append(userMessage)
        
        isLoading = true
        currentStreamingMessage = ""
        
        streamingTask = Task {
            do {
                // Resolve pronouns BEFORE processing
                let resolvedText = await ragService.resolvePronoun(in: text)
                
                // Ingest user message into RAG
                await ragService.ingestMessage(role: "user", content: resolvedText)
                
                // Retrieve context
                let context = await ragService.retrieveContext(for: resolvedText)
                
                // Build system prompt (rules + instructions)
                let systemPrompt = ragService.buildSystemPrompt()
                
                // Build user prompt (context + question)
                let userPrompt = ragService.buildAugmentedPrompt(query: resolvedText, context: context)
                
                // Stream response with system and user messages
                try await apiService.streamMessageWithSystem(systemPrompt: systemPrompt, userPrompt: userPrompt, model: model) { [weak self] chunk in
                    self?.currentStreamingMessage = chunk
                }
                
                // Add final message - capture the text first, then clear streaming
                let finalText = currentStreamingMessage
                currentStreamingMessage = "" // Clear immediately to prevent duplicate display
                isLoading = false // Stop loading state
                
                if !finalText.isEmpty {
                    let aiMessage = Message(text: finalText, isUser: false)
                    messages.append(aiMessage)
                    
                    // Update topic tracking
                    await ragService.updateCurrentTopic(from: resolvedText, aiResponse: finalText)
                    
                    // Ingest assistant response
                    await ragService.ingestMessage(role: "assistant", content: finalText)
                }
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
                // Resolve pronouns BEFORE processing
                let resolvedText = await ragService.resolvePronoun(in: text)
                
                // Ingest user message
                await ragService.ingestMessage(role: "user", content: resolvedText)
                
                // Retrieve context
                let context = await ragService.retrieveContext(for: resolvedText)
                
                // Build system prompt (rules + instructions)
                let systemPrompt = ragService.buildSystemPrompt()
                
                // Build user prompt (context + question)
                let userPrompt = ragService.buildAugmentedPrompt(query: resolvedText, context: context)
                
                // Use GPT-4o Mini for vision tasks
                if let firstImage = images.first {
                    try await apiService.sendMessageWithImageAndSystem(systemPrompt: systemPrompt, userPrompt: userPrompt, image: firstImage, model: .gpt4oMini) { [weak self] chunk in
                        self?.currentStreamingMessage = chunk
                    }
                }
                
                // Add final message - capture the text first, then clear streaming
                let finalText = currentStreamingMessage
                currentStreamingMessage = "" // Clear immediately to prevent duplicate display
                isLoading = false // Stop loading state
                
                if !finalText.isEmpty {
                    let aiMessage = Message(text: finalText, isUser: false)
                    messages.append(aiMessage)
                    
                    // Update topic tracking
                    await ragService.updateCurrentTopic(from: resolvedText, aiResponse: finalText)
                    
                    // Ingest assistant response
                    await ragService.ingestMessage(role: "assistant", content: finalText)
                }
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
        
        // Clear RAG memory
        Task {
            await ragService.clearAllMemory()
        }
    }
    
    func getRAGStats() -> String {
        ragService.getMemoryStats()
    }
}
