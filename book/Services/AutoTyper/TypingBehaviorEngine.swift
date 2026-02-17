//
//  TypingBehaviorEngine.swift
//  book
//
//  Created by AI Assistant
//

import Foundation

enum TypingEvent {
    case typeCharacter(Character)
    case typeBackspace
    case typeEnter
    case pause(TimeInterval)
}

class TypingBehaviorEngine {
    private var difficultWords: Set<String> = []
    private var pausePoints: Set<Int> = []
    
    /// Sets the AI-identified difficult words and pause points
    func setDifficultWords(_ words: Set<String>, pausePoints points: Set<Int>) {
        self.difficultWords = words
        self.pausePoints = points
    }
    
    // Nearby keyboard keys for typo simulation
    private let nearbyKeys: [Character: [Character]] = [
        "a": ["s", "q", "w", "z"],
        "b": ["v", "g", "h", "n"],
        "c": ["x", "d", "f", "v"],
        "d": ["s", "e", "r", "f", "c", "x"],
        "e": ["w", "r", "d", "s"],
        "f": ["d", "r", "t", "g", "v", "c"],
        "g": ["f", "t", "y", "h", "b", "v"],
        "h": ["g", "y", "u", "j", "n", "b"],
        "i": ["u", "o", "k", "j"],
        "j": ["h", "u", "i", "k", "n", "m"],
        "k": ["j", "i", "o", "l", "m"],
        "l": ["k", "o", "p"],
        "m": ["n", "j", "k"],
        "n": ["b", "h", "j", "m"],
        "o": ["i", "p", "l", "k"],
        "p": ["o", "l"],
        "q": ["w", "a"],
        "r": ["e", "t", "f", "d"],
        "s": ["a", "w", "e", "d", "x", "z"],
        "t": ["r", "y", "g", "f"],
        "u": ["y", "i", "j", "h"],
        "v": ["c", "f", "g", "b"],
        "w": ["q", "e", "s", "a"],
        "x": ["z", "s", "d", "c"],
        "y": ["t", "u", "h", "g"],
        "z": ["a", "s", "x"]
    ]
    
    func generateTypingEvents(for text: String) -> [TypingEvent] {
        var events: [TypingEvent] = []
        let words = tokenizeText(text)
        
        for (index, word) in words.enumerated() {
            // Handle whitespace tokens (spaces, tabs, newlines)
            if word.allSatisfy({ $0.isWhitespace }) {
                for char in word {
                    // Convert newline to Enter key event
                    if char == "\n" {
                        events.append(.typeEnter)
                    } else {
                        events.append(.typeCharacter(char))
                    }
                }
                continue
            }
            
            // Intelligent thinking pause based on AI-identified difficult words
            if shouldAddThinkingPause(for: word) {
                let thinkingTime = getThinkingTimeForWord(word)
                events.append(.pause(thinkingTime))
            }
            
            // Natural reading pause before new words (15% chance)
            // Longer pause for longer/complex words
            if index > 0 && Double.random(in: 0...1) < 0.15 {
                let pauseTime = word.count > 8 ? Double.random(in: 0.5...0.8) : Double.random(in: 0.3...0.6)
                events.append(.pause(pauseTime))
            }
            
            // Type the word with mid-word thinking pauses
            let wordEvents = generateWordEventsWithThinking(word)
            events.append(contentsOf: wordEvents)
            
            // Pause after punctuation (natural reading rhythm)
            if word.last == "," {
                events.append(.pause(Double.random(in: 0.3...0.5)))
            } else if word.last == "." || word.last == ";" {
                events.append(.pause(Double.random(in: 0.5...0.8)))
            }
        }
        
        return events
    }
    
    /// Generates typing events for a word with mid-word thinking pauses
    private func generateWordEventsWithThinking(_ word: String) -> [TypingEvent] {
        var events: [TypingEvent] = []
        
        // If it's just whitespace, type it directly
        if word.allSatisfy({ $0.isWhitespace }) {
            for char in word {
                events.append(.typeCharacter(char))
            }
            return events
        }
        
        let wordLength = word.count
        
        // For longer/complex words, add mid-word thinking pause
        // Longer words = higher chance of mid-word pause
        let pauseChance: Double = wordLength > 10 ? 0.40 : (wordLength > 6 ? 0.25 : 0.10)
        let shouldPauseMidWord = Double.random(in: 0...1) < pauseChance
        // Only add mid-word pause if word is long enough (at least 5 characters)
        let pausePosition = (shouldPauseMidWord && wordLength >= 5) ? Int.random(in: 2...(wordLength - 2)) : -1
        
        // Calculate mid-word pause duration based on word length
        let midWordPauseDuration: ClosedRange<TimeInterval> = wordLength > 10 ? (0.4...0.7) : (0.3...0.6)
        
        // Decide if this word will have a typo (6% chance - realistic rate)
        let shouldTypo = Double.random(in: 0...1) < 0.06
        let typoPosition = shouldTypo ? Int.random(in: 0..<wordLength) : -1
        
        for (index, char) in word.enumerated() {
            // Mid-word thinking pause (like reading ahead)
            // Longer pause for complex words
            if index == pausePosition {
                events.append(.pause(Double.random(in: midWordPauseDuration)))
            }
            
            // Make a typo at this position
            if index == typoPosition {
                if let wrongChar = getTypoCharacter(for: char) {
                    // Type wrong character
                    events.append(.typeCharacter(wrongChar))
                    // Notice the mistake (0.3-0.5s)
                    events.append(.pause(Double.random(in: 0.3...0.5)))
                    // Backspace to remove wrong character
                    events.append(.typeBackspace)
                    // Brief pause before typing correct character
                    events.append(.pause(Double.random(in: 0.15...0.25)))
                }
            }
            
            // Type correct character (convert newline to Enter event)
            if char == "\n" {
                events.append(.typeEnter)
            } else {
                events.append(.typeCharacter(char))
            }
            
            // Micro-variation in typing rhythm (5% chance)
            if index < wordLength - 1 && Double.random(in: 0...1) < 0.05 {
                events.append(.pause(Double.random(in: 0.1...0.2)))
            }
        }
        
        return events
    }
    
    private func tokenizeText(_ text: String) -> [String] {
        // Split by whitespace but preserve the whitespace
        var tokens: [String] = []
        var currentToken = ""
        
        for char in text {
            if char.isWhitespace {
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
                tokens.append(String(char))
            } else {
                currentToken.append(char)
            }
        }
        
        if !currentToken.isEmpty {
            tokens.append(currentToken)
        }
        
        return tokens
    }
    
    private func generateWordEvents(_ word: String) -> [TypingEvent] {
        var events: [TypingEvent] = []
        
        // If it's just whitespace, handle newlines specially
        if word.allSatisfy({ $0.isWhitespace }) {
            for char in word {
                if char == "\n" {
                    events.append(.typeEnter)
                } else {
                    events.append(.typeCharacter(char))
                }
            }
            return events
        }
        
        // Check if we should add a typo (8% chance per word, increased from 7%)
        let shouldTypo = Double.random(in: 0...1) < 0.08
        let typoPosition = shouldTypo ? Int.random(in: 0..<word.count) : -1
        
        for (index, char) in word.enumerated() {
            if index == typoPosition {
                // Type wrong character
                if let wrongChar = getTypoCharacter(for: char) {
                    events.append(.typeCharacter(wrongChar))
                    events.append(.pause(Double.random(in: 0.3...0.5)))  // Notice the typo
                    events.append(.typeBackspace)
                    events.append(.pause(Double.random(in: 0.15...0.25)))  // Brief pause before correction
                }
            }
            
            // Type correct character (convert newline to Enter event)
            if char == "\n" {
                events.append(.typeEnter)
            } else {
                events.append(.typeCharacter(char))
            }
            
            // Random micro-pause within word (3% chance)
            if index < word.count - 1 && Double.random(in: 0...1) < 0.03 {
                events.append(.pause(Double.random(in: 0.2...0.4)))
            }
        }
        
        return events
    }
    
    /// Check if word is AI-identified as difficult and needs thinking pause
    private func shouldAddThinkingPause(for word: String) -> Bool {
        let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
        return difficultWords.contains(cleanWord) || difficultWords.contains(cleanWord.lowercased())
    }
    
    /// Get thinking time for difficult words (AI-identified)
    private func getThinkingTimeForWord(_ word: String) -> TimeInterval {
        let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
        
        // If AI identified this as difficult, give it a longer thinking pause
        if difficultWords.contains(cleanWord) || difficultWords.contains(cleanWord.lowercased()) {
            return Double.random(in: 1.0...1.6)  // Longer pause for AI-identified difficult words
        }
        
        // Default thinking pause for other words
        return Double.random(in: 0.4...0.7)
    }
    
    private func getTypoCharacter(for char: Character) -> Character? {
        let lowerChar = Character(char.lowercased())
        guard let nearby = nearbyKeys[lowerChar], !nearby.isEmpty else {
            return nil
        }
        
        let wrongChar = nearby.randomElement()!
        
        // Preserve case
        if char.isUppercase {
            return Character(wrongChar.uppercased())
        } else {
            return wrongChar
        }
    }
}
