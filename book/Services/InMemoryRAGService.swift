//
//  InMemoryRAGService.swift
//  book
//
//  In-Memory RAG System - No Database, No Persistence
//

import Foundation

@MainActor
class InMemoryRAGService: ObservableObject {
    // MARK: - Configuration
    private let maxSTMSize = 25 // Increased from 10 to 25 for better context
    private let maxSemanticMemories = 1000
    private let topKRetrieval = 5
    private let similarityThreshold: Float = 0.3
    private let duplicateThreshold: Float = 0.9
    
    // MARK: - In-Memory Storage
    @Published private(set) var shortTermMemory: [STMItem] = []
    @Published private(set) var semanticMemory: [MemoryItem] = []
    
    // MARK: - Topic Tracking (NEW)
    @Published private(set) var currentTopic: String? = nil
    @Published private(set) var topicHistory: [TopicItem] = []
    
    // MARK: - Custom AI Rules
    private var customRules: [String] = []
    
    private let openAIService = OpenAIService()
    
    // MARK: - Initialization
    init() {
        loadCustomRules()
    }
    
    // MARK: - Memory Ingestion (WRITE)
    
    func ingestMessage(role: String, content: String) async {
        // 1. Add to Short-Term Memory (always)
        addToSTM(role: role, content: content)
        
        // 2. Check if message contains useful knowledge
        if role == "user" && shouldExtractKnowledge(from: content) {
            await extractAndStoreKnowledge(from: content)
        }
    }
    
    private func addToSTM(role: String, content: String) {
        let item = STMItem(role: role, content: content)
        shortTermMemory.append(item)
        
        // FIFO: Remove oldest if exceeds limit
        if shortTermMemory.count > maxSTMSize {
            shortTermMemory.removeFirst()
        }
    }
    
    private func shouldExtractKnowledge(from text: String) -> Bool {
        let lowercased = text.lowercased()
        
        // Skip very short messages
        if text.count < 5 {
            return false
        }
        
        // Skip greetings and noise
        let greetings = ["hi", "hello", "hey", "thanks", "thank you", "bye", "goodbye", "ok", "okay", "yes", "no"]
        let words = lowercased.split(separator: " ").map(String.init)
        if words.count <= 2 && greetings.contains(where: { words.contains($0) }) {
            return false
        }
        
        // Check for knowledge indicators
        let knowledgeIndicators = [
            "i like", "i prefer", "i want", "i need", "i love", "i hate",
            "my name is", "i am", "i'm", "i work", "my job",
            "remember", "always", "never", "usually", "typically",
            "favorite", "favourite", "born", "birthday", "date of birth",
            "live in", "from", "age", "years old",
            "correct", "actually", "no it's", "it's actually"
        ]
        
        return knowledgeIndicators.contains(where: { lowercased.contains($0) }) || text.count > 50
    }
    
    private func extractAndStoreKnowledge(from text: String) async {
        do {
            // Check if this is a correction
            let isCorrection = text.lowercased().contains("correct") || 
                              text.lowercased().contains("actually") ||
                              text.lowercased().contains("no it's") ||
                              text.lowercased().contains("not ")
            
            // Extract ALL facts using improved prompt
            let extractionPrompt = """
            Extract ALL facts, preferences, or information from this message.
            Return each fact as a separate line.
            If this is a correction, extract the CORRECTED information only.
            If no useful facts exist, return "NONE".
            
            Examples:
            - "My name is John" → User's name is John
            - "I'm 28 years old and I work at Google" →
              User is 28 years old
              User works at Google
            - "I was born on October 25th 1997" → User's date of birth is October 25, 1997
            - "Actually, it's October 25th" → User's date of birth is October 25
            - "I like pizza" → User likes pizza
            
            Message: "\(text)"
            
            Facts (one per line):
            """
            
            let extracted = try await openAIService.getSingleResponse(extractionPrompt, model: .gpt35Turbo)
            
            guard extracted != "NONE" && !extracted.isEmpty else { return }
            
            // Parse multiple facts
            let facts = extracted.split(separator: "\n").map { 
                String($0).trimmingCharacters(in: .whitespaces) 
            }
            
            // Store each fact separately
            for fact in facts where !fact.isEmpty && fact.count > 5 && fact != "NONE" {
                // Generate embedding
                let embedding = try await generateEmbedding(for: fact)
                
                // If this is a correction, remove conflicting memories
                if isCorrection {
                    await removeConflictingMemories(for: fact, embedding: embedding)
                }
                
                // Check for duplicates or similar memories
                if let existingIndex = findSimilarMemory(embedding: embedding, threshold: 0.85) {
                    // Update existing memory with new information
                    semanticMemory[existingIndex] = MemoryItem(
                        text: fact,
                        embedding: embedding,
                        importanceScore: min(1.0, semanticMemory[existingIndex].importanceScore + 0.2)
                    )
                } else {
                    // Store new memory
                    let memory = MemoryItem(text: fact, embedding: embedding, importanceScore: 0.6)
                    semanticMemory.append(memory)
                    
                    // Evict if exceeds limit
                    if semanticMemory.count > maxSemanticMemories {
                        evictLowestImportance()
                    }
                }
            }
            
        } catch {
            print("Knowledge extraction error: \(error)")
        }
    }
    
    private func removeConflictingMemories(for newFact: String, embedding: [Float]) async {
        // Find memories that are similar but might conflict
        var indicesToRemove: [Int] = []
        
        for (index, memory) in semanticMemory.enumerated() {
            let similarity = cosineSimilarity(embedding, memory.embedding)
            // If very similar (same topic) but different text, it might be outdated
            if similarity > 0.7 && similarity < 0.95 {
                indicesToRemove.append(index)
            }
        }
        
        // Remove conflicting memories (in reverse to maintain indices)
        for index in indicesToRemove.reversed() {
            semanticMemory.remove(at: index)
        }
    }
    
    // MARK: - Memory Retrieval (READ)
    
    func retrieveContext(for query: String) async -> RetrievedContext {
        do {
            // Generate embedding for query
            let queryEmbedding = try await generateEmbedding(for: query)
            
            // Calculate similarities
            var scoredMemories: [(memory: MemoryItem, score: Float)] = []
            
            for memory in semanticMemory {
                let similarity = cosineSimilarity(queryEmbedding, memory.embedding)
                if similarity >= similarityThreshold {
                    scoredMemories.append((memory, similarity))
                }
            }
            
            // Sort by similarity (higher is better) and importance
            scoredMemories.sort { 
                ($0.score * 0.7 + $0.memory.importanceScore * 0.3) > 
                ($1.score * 0.7 + $1.memory.importanceScore * 0.3)
            }
            
            let topMemories = Array(scoredMemories.prefix(topKRetrieval))
            
            // Update importance scores for retrieved memories
            for (memory, _) in topMemories {
                if let index = semanticMemory.firstIndex(where: { $0.id == memory.id }) {
                    semanticMemory[index].importanceScore += 0.05
                    semanticMemory[index].importanceScore = min(1.0, semanticMemory[index].importanceScore)
                }
            }
            
            return RetrievedContext(
                memories: topMemories.map { $0.memory },
                recentMessages: Array(shortTermMemory.suffix(5)),
                relevanceScores: topMemories.map { $0.score }
            )
            
        } catch {
            print("Context retrieval error: \(error)")
            return RetrievedContext(memories: [], recentMessages: Array(shortTermMemory.suffix(5)), relevanceScores: [])
        }
    }
    
    // MARK: - Custom Rules Management
    
    private func loadCustomRules() {
        // Try to load custom rules from AIRules.txt
        if let rulesPath = Bundle.main.path(forResource: "AIRules", ofType: "txt"),
           let rulesContent = try? String(contentsOfFile: rulesPath, encoding: .utf8) {
            
            // Parse rules: ignore comments (#) and empty lines
            customRules = rulesContent
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            
            print("✅ Loaded \(customRules.count) custom AI rules")
        } else {
            print("ℹ️ No custom AI rules file found (AIRules.txt)")
        }
    }
    
    func reloadCustomRules() {
        loadCustomRules()
    }
    
    // MARK: - Prompt Augmentation (RAG)
    
    func buildSystemPrompt() -> String {
        var systemPrompt = ""
        
        // Base system instructions
        systemPrompt += "You are a helpful AI assistant having a natural conversation.\n"
        systemPrompt += "You have knowledge from previous parts of this conversation.\n\n"
        
        systemPrompt += "CRITICAL INSTRUCTIONS:\n"
        systemPrompt += "- Answer NATURALLY like a human would\n"
        systemPrompt += "- Use the CURRENT TOPIC and RECENT CONVERSATION to understand pronouns (it, them, that, its)\n"
        systemPrompt += "- If you know the answer from the facts provided, state it directly and confidently\n"
        systemPrompt += "- NEVER say 'based on retrieved memory' or 'according to memory' or similar phrases\n"
        systemPrompt += "- NEVER mention 'memory', 'storage', 'database', 'embeddings', or technical terms\n"
        systemPrompt += "- If you DON'T know something, simply say 'I don't know' or 'I don't have that information'\n"
        systemPrompt += "- Be conversational and natural\n"
        systemPrompt += "- Answer as if you naturally remember things from earlier in the conversation\n"
        
        // Add custom rules if any
        if !customRules.isEmpty {
            systemPrompt += "\n"
            systemPrompt += "ADDITIONAL CUSTOM RULES:\n"
            for rule in customRules {
                systemPrompt += "- \(rule)\n"
            }
        }
        
        return systemPrompt
    }
    
    func buildAugmentedPrompt(query: String, context: RetrievedContext) -> String {
        var prompt = ""
        
        // User summary (from settings)
        let userSummary = UserDefaults.standard.userSummary
        if !userSummary.isEmpty {
            prompt += "USER SUMMARY:\n"
            prompt += "\(userSummary)\n\n"
        }
        
        // Current topic context
        if let topic = currentTopic {
            prompt += "CURRENT TOPIC:\n"
            prompt += "\(topic)\n\n"
        }
        
        // Retrieved memories (most important)
        if !context.memories.isEmpty {
            prompt += "KNOWN FACTS:\n"
            for memory in context.memories {
                prompt += "- \(memory.text)\n"
            }
            prompt += "\n"
        }
        
        // Recent chat history
        if !context.recentMessages.isEmpty {
            prompt += "RECENT CONVERSATION:\n"
            for msg in context.recentMessages {
                prompt += "\(msg.role.capitalized): \(msg.content)\n"
            }
            prompt += "\n"
        }
        
        // Current question
        prompt += "USER QUESTION:\n"
        prompt += "\(query)"
        
        return prompt
    }
    
    // MARK: - Topic Tracking (NEW)
    
    func updateCurrentTopic(from userMessage: String, aiResponse: String) async {
        // Extract topic from conversation
        let topicPrompt = """
        What is the main topic/subject being discussed in this conversation?
        Return ONLY the topic name in 2-4 words (e.g., "Go programming", "React hooks", "Italian food", "birthday date").
        If no clear topic, return "general conversation".
        
        User: \(userMessage)
        Assistant: \(aiResponse)
        
        Topic:
        """
        
        do {
            let topic = try await openAIService.getSingleResponse(topicPrompt, model: .gpt35Turbo)
            let cleanTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !cleanTopic.isEmpty && cleanTopic.lowercased() != "general conversation" {
                currentTopic = cleanTopic
                
                // Add to history if it's a new topic
                if topicHistory.isEmpty || topicHistory.last?.topic != cleanTopic {
                    topicHistory.append(TopicItem(
                        topic: cleanTopic,
                        timestamp: Date(),
                        relatedKeywords: extractKeywords(from: userMessage)
                    ))
                    
                    // Keep only last 10 topics
                    if topicHistory.count > 10 {
                        topicHistory.removeFirst()
                    }
                }
            }
        } catch {
            print("Topic extraction error: \(error)")
        }
    }
    
    func resolvePronoun(in message: String) -> String {
        var resolved = message
        let lowercased = message.lowercased()
        
        guard let topic = currentTopic else { return message }
        
        // Resolve "it" and "It"
        if lowercased.contains(" it ") || lowercased.starts(with: "it ") || lowercased.hasSuffix(" it") {
            resolved = resolved.replacingOccurrences(of: " it ", with: " \(topic) ", options: .caseInsensitive)
            if resolved.lowercased().starts(with: "it ") {
                resolved = topic + resolved.dropFirst(2)
            }
            if resolved.lowercased().hasSuffix(" it") {
                resolved = String(resolved.dropLast(3)) + " \(topic)"
            }
        }
        
        // Resolve "them" and "they"
        if lowercased.contains(" them ") || lowercased.contains(" they ") {
            resolved = resolved.replacingOccurrences(of: " them ", with: " \(topic) ", options: .caseInsensitive)
            resolved = resolved.replacingOccurrences(of: " they ", with: " \(topic) ", options: .caseInsensitive)
        }
        
        // Resolve "its" and "their"
        if lowercased.contains(" its ") || lowercased.contains(" their ") {
            resolved = resolved.replacingOccurrences(of: " its ", with: " \(topic)'s ", options: .caseInsensitive)
            resolved = resolved.replacingOccurrences(of: " their ", with: " \(topic)'s ", options: .caseInsensitive)
        }
        
        // Resolve "that" when it refers to the topic
        if lowercased.contains(" that ") && !lowercased.contains("that is") && !lowercased.contains("that was") {
            // Only replace if "that" seems to refer to the topic
            if lowercased.contains("about that") || lowercased.contains("with that") || lowercased.contains("using that") {
                resolved = resolved.replacingOccurrences(of: " that ", with: " \(topic) ", options: .caseInsensitive)
            }
        }
        
        return resolved
    }
    
    private func extractKeywords(from text: String) -> [String] {
        // Simple keyword extraction - split by spaces and filter
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 } // Only words longer than 3 characters
            .filter { !["that", "this", "with", "from", "have", "been", "were", "what", "when", "where"].contains($0) }
        
        return Array(Set(words)).prefix(5).map { $0 }
    }
    
    // MARK: - Memory Management
    
    func forgetMemory(containing keyword: String) {
        semanticMemory.removeAll { memory in
            memory.text.lowercased().contains(keyword.lowercased())
        }
    }
    
    func clearAllMemory() {
        shortTermMemory.removeAll()
        semanticMemory.removeAll()
        currentTopic = nil
        topicHistory.removeAll()
    }
    
    private func findSimilarMemory(embedding: [Float], threshold: Float) -> Int? {
        for (index, memory) in semanticMemory.enumerated() {
            let similarity = cosineSimilarity(embedding, memory.embedding)
            if similarity >= threshold {
                return index
            }
        }
        return nil
    }
    
    private func findDuplicate(embedding: [Float]) -> Int? {
        return findSimilarMemory(embedding: embedding, threshold: duplicateThreshold)
    }
    
    private func evictLowestImportance() {
        guard let minIndex = semanticMemory.indices.min(by: {
            semanticMemory[$0].importanceScore < semanticMemory[$1].importanceScore
        }) else { return }
        
        semanticMemory.remove(at: minIndex)
    }
    
    // MARK: - Embedding Generation
    
    private func generateEmbedding(for text: String) async throws -> [Float] {
        // Use OpenAI embeddings API
        let url = URL(string: "https://api.openai.com/v1/embeddings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(UserDefaults.standard.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": "text-embedding-3-small",
            "input": text
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "RAG", code: -1, userInfo: [NSLocalizedDescriptionKey: "Embedding API error"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let firstItem = dataArray.first,
              let embedding = firstItem["embedding"] as? [Double] else {
            throw NSError(domain: "RAG", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid embedding response"])
        }
        
        return embedding.map { Float($0) }
    }
    
    // MARK: - Vector Math
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    // MARK: - Debug Info
    
    func getMemoryStats() -> String {
        """
        Short-Term Memory: \(shortTermMemory.count)/\(maxSTMSize)
        Semantic Memory: \(semanticMemory.count)/\(maxSemanticMemories)
        Avg Importance: \(semanticMemory.isEmpty ? 0 : semanticMemory.map { $0.importanceScore }.reduce(0, +) / Float(semanticMemory.count))
        """
    }
}
