//
//  AIResponseProcessor.swift
//  book
//
//  Created by AI Assistant
//

import Foundation

struct TypingAnalysis {
    let formattedText: String
    let difficultWords: Set<String>  // Words that need thinking pauses
    let pausePoints: Set<Int>  // Character positions where pauses should occur
}

class AIResponseProcessor {
    private let apiService = OpenAIService()
    
    func processClipboardText(_ text: String) async throws -> TypingAnalysis {
        // Check text length to avoid excessive API costs
        guard text.count <= 2000 else {
            throw ProcessingError.textTooLong
        }
        
        // Build prompt for AI to analyze and format the text
        let prompt = """
        You are a coding assistant analyzing text for human-like typing simulation.
        
        Task 1: Format the text properly (fix syntax, indentation, etc.)
        Task 2: Identify difficult/complex words that need thinking pauses
        
        Analyze this text and respond in this EXACT format:
        
        FORMATTED_TEXT:
        [The formatted/improved text here]
        
        DIFFICULT_WORDS:
        [Comma-separated list of complex words that need thinking pauses]
        Examples: technical terms, long identifiers, complex keywords, unfamiliar words
        
        IMPORTANT: 
        - Return ONLY the formatted text and difficult words
        - No explanations, no markdown, no extra text
        - Difficult words should be actual words from the text that are complex/technical
        
        Text to analyze:
        \(text)
        """
        
        // Get AI response
        let response = try await apiService.getSingleResponse(prompt, model: .gpt4oMini)
        
        print("🔍 AI Response:")
        print(response)
        print("---")
        
        // Parse the response
        return parseAIResponse(response, originalText: text)
    }
    
    private func parseAIResponse(_ response: String, originalText: String) -> TypingAnalysis {
        var formattedText = originalText
        var difficultWords: Set<String> = []
        
        // Look for FORMATTED_TEXT section
        if let formattedRange = response.range(of: "FORMATTED_TEXT:") {
            let afterFormatted = response[formattedRange.upperBound...]
            
            // Extract text until DIFFICULT_WORDS section or end of response
            if let difficultRange = afterFormatted.range(of: "DIFFICULT_WORDS:") {
                formattedText = String(afterFormatted[..<difficultRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                formattedText = String(afterFormatted).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Look for DIFFICULT_WORDS section
        if let difficultRange = response.range(of: "DIFFICULT_WORDS:") {
            let afterDifficult = response[difficultRange.upperBound...]
            let wordsString = String(afterDifficult).trimmingCharacters(in: .whitespacesAndNewlines)
            let words = wordsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            difficultWords = Set(words.filter { !$0.isEmpty })
        }
        
        // Calculate pause points based on difficult words
        let pausePoints = calculatePausePoints(in: formattedText, difficultWords: difficultWords)
        
        return TypingAnalysis(
            formattedText: formattedText,
            difficultWords: difficultWords,
            pausePoints: pausePoints
        )
    }
    
    private func calculatePausePoints(in text: String, difficultWords: Set<String>) -> Set<Int> {
        var pausePoints: Set<Int> = []
        let lowercaseText = text.lowercased()
        
        for word in difficultWords {
            let lowercaseWord = word.lowercased()
            var searchRange = lowercaseText.startIndex..<lowercaseText.endIndex
            
            while let range = lowercaseText.range(of: lowercaseWord, range: searchRange) {
                // Add pause point at the start of the difficult word
                let position = lowercaseText.distance(from: lowercaseText.startIndex, to: range.lowerBound)
                pausePoints.insert(position)
                
                // Continue searching after this occurrence
                searchRange = range.upperBound..<lowercaseText.endIndex
            }
        }
        
        return pausePoints
    }
}

enum ProcessingError: Error {
    case textTooLong
    case apiError
    
    var localizedDescription: String {
        switch self {
        case .textTooLong:
            return "Text is too long (max 2000 characters)"
        case .apiError:
            return "Failed to process text with AI"
        }
    }
}
