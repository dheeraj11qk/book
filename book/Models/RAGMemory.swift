//
//  RAGMemory.swift
//  book
//
//  In-Memory RAG System
//

import Foundation

// MARK: - Memory Item (Semantic Memory)
struct MemoryItem: Identifiable {
    let id: UUID
    let text: String
    let embedding: [Float]
    let timestamp: Date
    var importanceScore: Float
    
    init(text: String, embedding: [Float], importanceScore: Float = 0.5) {
        self.id = UUID()
        self.text = text
        self.embedding = embedding
        self.timestamp = Date()
        self.importanceScore = importanceScore
    }
}

// MARK: - Short-Term Memory Item
struct STMItem: Identifiable {
    let id: UUID
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date
    
    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - Retrieved Context
struct RetrievedContext {
    let memories: [MemoryItem]
    let recentMessages: [STMItem]
    let relevanceScores: [Float]
}

// MARK: - Topic Item (Topic Tracking)
struct TopicItem: Identifiable {
    let id: UUID
    let topic: String
    let timestamp: Date
    let relatedKeywords: [String]
    
    init(topic: String, timestamp: Date, relatedKeywords: [String]) {
        self.id = UUID()
        self.topic = topic
        self.timestamp = timestamp
        self.relatedKeywords = relatedKeywords
    }
}
