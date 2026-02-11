# RAG System Analysis & Required Fixes

## Test Suite Overview
- **Total Tests**: 20 comprehensive test cases
- **Goal**: Make RAG work like ChatGPT memory
- **Focus Areas**: Context continuation, pronoun resolution, corrections, semantic understanding

---

## Identified Issues in Current RAG Implementation

### ❌ ISSUE 1: Pronoun Resolution Not Implemented
**Problem**: System doesn't track conversation topics for pronoun resolution

**Failing Tests**:
- Test #7: "Now write 500 words about it" (doesn't know "it" = Go)
- Test #9: "What are its main advantages?" (doesn't know "its" = Go)
- Test #18: "Can you give me an example of using them?" (doesn't know "them" = hooks)

**Current Behavior**:
```swift
// InMemoryRAGService only stores extracted facts
// It doesn't track "current topic" or "last discussed subject"
```

**Required Fix**:
- Add `currentTopic` tracking
- Store last discussed subject
- Resolve pronouns before sending to AI

---

### ❌ ISSUE 2: Context Window Too Small
**Problem**: Short-term memory only keeps 10 messages

**Failing Tests**:
- Test #19: "Is React similar to what I use at work?" (needs to recall test #3 about Google)
- Test #20: "What have we discussed today?" (needs full conversation summary)

**Current Code**:
```swift
private let maxSTMSize = 10 // Only 10 messages
```

**Required Fix**:
- Increase STM to 20-30 messages for better context
- OR implement conversation summarization

---

### ❌ ISSUE 3: No Conversation Topic Tracking
**Problem**: System doesn't maintain "what we're talking about"

**Failing Tests**:
- Test #8: "What was I asking about before?"
- Test #10: Topic shift from Go to Python

**Current Behavior**:
- Only stores extracted facts
- No topic/subject tracking
- Can't answer "what were we discussing?"

**Required Fix**:
- Add topic tracking system
- Store conversation subjects
- Maintain topic history

---

### ❌ ISSUE 4: Multiple Facts Extraction Limitation
**Problem**: Extraction prompt says "Extract a single, concise fact"

**Failing Tests**:
- Test #3: "I'm 28 years old and I work at Google as a software engineer"
  - Current: Extracts only ONE fact
  - Required: Extract BOTH age AND job

**Current Code**:
```swift
let extractionPrompt = """
Extract a single, concise fact or preference from this message.
...
"""
```

**Required Fix**:
- Change to extract ALL facts from message
- Return multiple facts as array
- Store each fact separately

---

### ❌ ISSUE 5: No Cross-Message Context Linking
**Problem**: Can't connect information across different parts of conversation

**Failing Tests**:
- Test #19: Needs to connect "React" (test #17) with "work at Google" (test #3)

**Current Behavior**:
- Facts stored independently
- No relationships between facts
- Can't make connections

**Required Fix**:
- Add relationship tracking
- Link related facts
- Enable cross-reference queries

---

## ✅ What's Working Well

1. ✅ **Natural Responses**: Prompt correctly instructs AI to avoid technical terms
2. ✅ **Correction Detection**: Detects "actually", "correct" keywords
3. ✅ **Conflict Removal**: Removes old memories when corrected
4. ✅ **Semantic Memory**: Stores facts with embeddings
5. ✅ **Duplicate Detection**: Merges similar memories
6. ✅ **Unknown Handling**: Should say "I don't know" (if prompt followed)

---

## Required Code Changes

### FIX 1: Add Pronoun Resolution System

```swift
// Add to InMemoryRAGService
@Published private(set) var currentTopic: String? = nil
@Published private(set) var topicHistory: [TopicItem] = []

struct TopicItem {
    let topic: String
    let timestamp: Date
    let relatedKeywords: [String]
}

func updateCurrentTopic(from message: String, aiResponse: String) async {
    // Extract topic from conversation
    let topicPrompt = """
    What is the main topic/subject being discussed in this conversation?
    Return ONLY the topic name (e.g., "Go programming", "React hooks", "Italian food")
    
    User: \(message)
    Assistant: \(aiResponse)
    
    Topic:
    """
    
    let topic = try? await openAIService.getSingleResponse(topicPrompt, model: .gpt35Turbo)
    if let topic = topic, !topic.isEmpty {
        currentTopic = topic
        topicHistory.append(TopicItem(
            topic: topic,
            timestamp: Date(),
            relatedKeywords: extractKeywords(from: message)
        ))
    }
}

func resolvePronoun(in message: String) -> String {
    let lowercased = message.lowercased()
    
    // Check for pronouns
    if lowercased.contains(" it ") || lowercased.starts(with: "it ") {
        if let topic = currentTopic {
            return message.replacingOccurrences(of: " it ", with: " \(topic) ")
                         .replacingOccurrences(of: "It ", with: "\(topic) ")
        }
    }
    
    if lowercased.contains(" them ") || lowercased.contains(" they ") {
        if let topic = currentTopic {
            return message.replacingOccurrences(of: " them ", with: " \(topic) ")
                         .replacingOccurrences(of: " they ", with: " \(topic) ")
        }
    }
    
    if lowercased.contains(" its ") {
        if let topic = currentTopic {
            return message.replacingOccurrences(of: " its ", with: " \(topic)'s ")
        }
    }
    
    return message
}
```

### FIX 2: Increase Context Window

```swift
// Change in InMemoryRAGService
private let maxSTMSize = 25 // Increased from 10 to 25
```

### FIX 3: Extract Multiple Facts

```swift
// Update extraction prompt
let extractionPrompt = """
Extract ALL facts, preferences, or information from this message.
Return each fact as a separate line.
If no useful facts exist, return "NONE".

Examples:
- "I'm 28 years old and I work at Google" →
  User is 28 years old
  User works at Google

- "My name is John and I like pizza" →
  User's name is John
  User likes pizza

Message: "\(text)"

Facts (one per line):
"""

// Parse multiple facts
let extracted = try await openAIService.getSingleResponse(extractionPrompt, model: .gpt35Turbo)
let facts = extracted.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }

for fact in facts where fact != "NONE" && !fact.isEmpty && fact.count > 5 {
    let embedding = try await generateEmbedding(for: fact)
    // Store each fact separately
    let memory = MemoryItem(text: fact, embedding: embedding, importanceScore: 0.6)
    semanticMemory.append(memory)
}
```

### FIX 4: Add Topic Tracking to Prompt

```swift
func buildAugmentedPrompt(query: String, context: RetrievedContext) -> String {
    var prompt = ""
    
    // System context
    prompt += "SYSTEM CONTEXT:\n"
    prompt += "You are a helpful AI assistant having a natural conversation.\n"
    prompt += "You have knowledge from previous parts of this conversation.\n\n"
    
    // Current topic context (NEW)
    if let topic = currentTopic {
        prompt += "CURRENT TOPIC: \(topic)\n\n"
    }
    
    // Recent topics (NEW)
    if !topicHistory.isEmpty {
        prompt += "RECENT TOPICS DISCUSSED:\n"
        for topic in topicHistory.suffix(5) {
            prompt += "- \(topic.topic)\n"
        }
        prompt += "\n"
    }
    
    // Retrieved memories
    if !context.memories.isEmpty {
        prompt += "FACTS YOU KNOW:\n"
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
    prompt += "USER: \(query)\n\n"
    prompt += "CRITICAL INSTRUCTIONS:\n"
    prompt += "- Answer NATURALLY like a human would\n"
    prompt += "- Use the CURRENT TOPIC context to understand pronouns (it, them, that)\n"
    prompt += "- If you know the answer from the facts above, state it directly\n"
    prompt += "- NEVER say 'based on retrieved memory' or mention memory systems\n"
    prompt += "- If you DON'T know something, simply say 'I don't know'\n"
    prompt += "- Be conversational and natural\n\n"
    prompt += "ASSISTANT:"
    
    return prompt
}
```

### FIX 5: Update ChatViewModel Integration

```swift
// In ChatViewModel.sendMessage
func sendMessage(_ text: String, model: AIModel = .gpt35Turbo) {
    let userMessage = Message(text: text, isUser: true)
    messages.append(userMessage)
    
    isLoading = true
    currentStreamingMessage = ""
    
    streamingTask = Task {
        do {
            // Resolve pronouns BEFORE ingesting (NEW)
            let resolvedText = await ragService.resolvePronoun(in: text)
            
            // Ingest user message into RAG
            await ragService.ingestMessage(role: "user", content: resolvedText)
            
            // Retrieve context
            let context = await ragService.retrieveContext(for: resolvedText)
            
            // Build augmented prompt
            let augmentedPrompt = ragService.buildAugmentedPrompt(query: resolvedText, context: context)
            
            // Stream response
            try await apiService.streamMessage(augmentedPrompt, model: model) { [weak self] chunk in
                self?.currentStreamingMessage = chunk
            }
            
            // Add final message
            if !currentStreamingMessage.isEmpty {
                let aiMessage = Message(text: currentStreamingMessage, isUser: false)
                messages.append(aiMessage)
                
                // Update topic tracking (NEW)
                await ragService.updateCurrentTopic(from: resolvedText, aiResponse: currentStreamingMessage)
                
                // Ingest assistant response
                await ragService.ingestMessage(role: "assistant", content: currentStreamingMessage)
                
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
```

---

## Implementation Priority

### HIGH PRIORITY (Must Fix)
1. ✅ **Multiple Facts Extraction** - Critical for test #3
2. ✅ **Pronoun Resolution** - Critical for tests #7, #9, #18
3. ✅ **Increase STM Size** - Critical for test #19, #20

### MEDIUM PRIORITY (Should Fix)
4. ✅ **Topic Tracking** - Important for test #8, #10
5. ✅ **Cross-Context Linking** - Important for test #19

### LOW PRIORITY (Nice to Have)
6. ⚪ **Conversation Summarization** - For very long conversations
7. ⚪ **Relationship Graphs** - Advanced feature

---

## Testing Strategy

1. **Implement fixes one by one**
2. **Test after each fix**:
   - Run relevant test cases
   - Verify no regressions
   - Document results

3. **Final validation**:
   - Run all 20 tests
   - Document pass/fail rate
   - Identify remaining issues

---

## Expected Results After Fixes

### Before Fixes:
- ❌ Test #3: Fails (only extracts one fact)
- ❌ Test #7: Fails (doesn't understand "it")
- ❌ Test #8: Fails (no topic tracking)
- ❌ Test #9: Fails (doesn't understand "its")
- ❌ Test #18: Fails (doesn't understand "them")
- ❌ Test #19: Fails (can't connect contexts)
- ❌ Test #20: Fails (limited context window)

### After Fixes:
- ✅ Test #3: Pass (extracts both age and job)
- ✅ Test #7: Pass (resolves "it" to "Go")
- ✅ Test #8: Pass (tracks topics)
- ✅ Test #9: Pass (resolves "its" to "Go's")
- ✅ Test #18: Pass (resolves "them" to "hooks")
- ✅ Test #19: Pass (connects React to Google)
- ✅ Test #20: Pass (larger context window)

---

## Next Steps

1. Review this analysis
2. Decide which fixes to implement
3. Implement fixes in order of priority
4. Test each fix individually
5. Run full test suite
6. Document final results

---

## Summary

Your RAG system has a solid foundation but needs these key improvements to work like ChatGPT:

1. **Pronoun resolution** - Understand "it", "them", "that"
2. **Multiple fact extraction** - Extract all facts from one message
3. **Larger context window** - Remember more of the conversation
4. **Topic tracking** - Know what we're discussing
5. **Cross-context linking** - Connect related information

These changes will make your RAG system behave much more like ChatGPT's memory!
