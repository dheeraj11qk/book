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
                // Build system prompt for image analysis
                let systemPrompt = ragService.buildSystemPrompt()
                
                // Build user prompt - direct image analysis request
                let imageAnalysisPrompt: String
                if text.isEmpty || text == "Analyze this image" {
                    imageAnalysisPrompt = """
                    Look at the image provided and analyze it carefully.
                    
                    Find any:
                    - Coding problems, errors, or bugs
                    - Code snippets that need explanation
                    - Technical questions or interview questions
                    - SQL queries or database problems
                    - Any other programming or technical questions
                    
                    Then provide your answer in this EXACT format:
                    
                    Short Answer:
                    [1-2 sentences summarizing the problem and solution]
                    
                    Full Answer:
                    [3-5 sentences with detailed explanation using <keyword> tags for important terms]
                    
                    Code:
                    [Complete, working code example that solves the problem]
                    
                    IMPORTANT: You MUST analyze the actual image content and provide a real solution.
                    """
                } else {
                    imageAnalysisPrompt = """
                    Look at the image provided and answer this question: \(text)
                    
                    Analyze the image content and provide your answer in this EXACT format:
                    
                    Short Answer:
                    [1-2 sentences summarizing the answer]
                    
                    Full Answer:
                    [3-5 sentences with detailed explanation using <keyword> tags for important terms]
                    
                    Code:
                    [Complete, working code example if applicable]
                    
                    IMPORTANT: You MUST analyze the actual image content and provide a real solution.
                    """
                }
                
                // Check if OpenAI API key is configured
                let openAIKey = UserDefaults.standard.openAIAPIKey
                if openAIKey.isEmpty {
                    let errorMessage = Message(text: "Error: OpenAI API key is required for image analysis. Please add your OpenAI API key in Settings.", isUser: false)
                    messages.append(errorMessage)
                    currentStreamingMessage = ""
                    isLoading = false
                    return
                }
                
                print("🖼️ Sending image analysis request with model: gpt-4o-mini")
                
                // Use GPT-4o Mini for vision tasks
                if let firstImage = images.first {
                    try await apiService.sendMessageWithImageAndSystem(systemPrompt: systemPrompt, userPrompt: imageAnalysisPrompt, image: firstImage, model: .gpt4oMini) { [weak self] chunk in
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
                    
                    // Ingest into RAG for future context
                    await ragService.ingestMessage(role: "user", content: text.isEmpty ? "Analyze this image" : text)
                    await ragService.ingestMessage(role: "assistant", content: finalText)
                    await ragService.updateCurrentTopic(from: text, aiResponse: finalText)
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
