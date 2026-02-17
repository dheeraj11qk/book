//
//  TypingSimulator.swift
//  Clipboard Auto-Typer
//
//  Created for clipboard auto-typing feature
//

import Foundation
import CoreGraphics
import Carbon

/// Generates keyboard events with human-like timing variations
class TypingSimulator {
    private var isTyping: Bool = false
    private var shouldStop: Bool = false
    private var isPaused: Bool = false
    private let behaviorEngine = TypingBehaviorEngine()
    
    /// Types the given text with AI-enhanced human-like behavior
    /// - Parameters:
    ///   - text: The text to type
    ///   - useAIBehavior: Whether to use AI-enhanced human behavior (typos, pauses, etc.)
    ///   - onSpeedChange: Callback when speed mode changes
    ///   - completion: Callback when typing completes or stops
    func typeText(_ text: String, useAIBehavior: Bool = true, onSpeedChange: @escaping (SpeedMode) -> Void, completion: @escaping () -> Void) {
        guard !isTyping else { return }
        
        isTyping = true
        shouldStop = false
        
        if useAIBehavior {
            typeWithAIBehavior(text, onSpeedChange: onSpeedChange, completion: completion)
        } else {
            typeWithBasicBehavior(text, onSpeedChange: onSpeedChange, completion: completion)
        }
    }
    
    /// Types text with AI-enhanced human behavior (typos, thinking pauses, etc.)
    private func typeWithAIBehavior(_ text: String, onSpeedChange: @escaping (SpeedMode) -> Void, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Generate typing events with human imperfections
            let events = self.behaviorEngine.generateTypingEvents(for: text)
            
            var currentMode = SpeedMode.normal
            DispatchQueue.main.async {
                onSpeedChange(currentMode)
            }
            
            for event in events {
                if self.shouldStop {
                    break
                }
                
                // Wait while paused
                while self.isPaused && !self.shouldStop {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                
                if self.shouldStop {
                    break
                }
                
                switch event {
                case .typeCharacter(let char):
                    _ = self.postKeyEvent(for: char)
                    let delay = self.getDelay(for: currentMode)
                    Thread.sleep(forTimeInterval: delay)
                    
                case .typeBackspace:
                    self.postBackspaceEvent()
                    Thread.sleep(forTimeInterval: 0.1)
                    
                case .typeEnter:
                    self.postEnterEvent()
                    Thread.sleep(forTimeInterval: 0.1)
                    
                case .pause(let duration):
                    // Update speed mode to "thinking" during long pauses
                    if duration > 0.3 {
                        currentMode = .thinking
                        DispatchQueue.main.async {
                            onSpeedChange(currentMode)
                        }
                    }
                    Thread.sleep(forTimeInterval: duration)
                    
                    // Return to normal speed after thinking
                    if duration > 0.3 {
                        currentMode = .normal
                        DispatchQueue.main.async {
                            onSpeedChange(currentMode)
                        }
                    }
                }
            }
            
            self.isTyping = false
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    /// Sets the AI-identified difficult words for the behavior engine
    func setDifficultWords(_ words: Set<String>, pausePoints: Set<Int>) {
        behaviorEngine.setDifficultWords(words, pausePoints: pausePoints)
    }
    
    /// Types text with basic human-like behavior (original implementation)
    private func typeWithBasicBehavior(_ text: String, onSpeedChange: @escaping (SpeedMode) -> Void, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var currentMode = self.selectRandomSpeedMode()
            onSpeedChange(currentMode)
            
            var charactersSinceLastModeChange = 0
            let charactersBeforeModeChange = Int.random(in: 5...15)
            var failedCharacters = 0
            let totalCharacters = text.count
            
            for character in text {
                // Check if stop was requested
                if self.shouldStop {
                    break
                }
                
                // Wait while paused
                while self.isPaused && !self.shouldStop {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                
                if self.shouldStop {
                    break
                }
                
                // Post key event for character with error handling
                let success = self.postKeyEvent(for: character)
                if !success {
                    failedCharacters += 1
                    print("Failed to type character: \(character)")
                    
                    // If too many failures, stop typing
                    if failedCharacters > totalCharacters / 10 {
                        print("Too many failed characters, stopping typing")
                        break
                    }
                }
                
                // Get delay for current mode
                let delay = self.getDelay(for: currentMode)
                Thread.sleep(forTimeInterval: delay)
                
                // Randomly change speed mode to simulate natural variation
                charactersSinceLastModeChange += 1
                if charactersSinceLastModeChange >= charactersBeforeModeChange {
                    currentMode = self.selectRandomSpeedMode()
                    DispatchQueue.main.async {
                        onSpeedChange(currentMode)
                    }
                    charactersSinceLastModeChange = 0
                }
            }
            
            self.isTyping = false
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    /// Stops the current typing operation immediately
    func stop() {
        shouldStop = true
        isPaused = false
    }
    
    /// Pauses the current typing operation
    func pause() {
        isPaused = true
    }
    
    /// Resumes the paused typing operation
    func resume() {
        isPaused = false
    }
    
    /// Returns a random delay within the speed mode's range
    private func getDelay(for mode: SpeedMode) -> TimeInterval {
        let range = mode.delayRange
        return TimeInterval.random(in: range)
    }
    
    /// Randomly selects a speed mode with weighted probability
    private func selectRandomSpeedMode() -> SpeedMode {
        let random = Int.random(in: 1...100)
        
        switch random {
        case 1...50:  // 50% probability
            return .normal
        case 51...70:  // 20% probability
            return .slow
        case 71...90:  // 20% probability
            return .littleFast
        default:  // 10% probability
            return .thinking
        }
    }
    
    /// Posts a keyboard event for the given character
    /// - Returns: True if successful, false otherwise
    private func postKeyEvent(for character: Character) -> Bool {
        let string = String(character)
        
        // Create key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            return false
        }
        
        keyDownEvent.keyboardSetUnicodeString(stringLength: string.utf16.count, unicodeString: Array(string.utf16))
        keyDownEvent.post(tap: .cghidEventTap)
        
        // Small delay between key down and key up
        Thread.sleep(forTimeInterval: 0.01)
        
        // Create key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            return false
        }
        
        keyUpEvent.keyboardSetUnicodeString(stringLength: string.utf16.count, unicodeString: Array(string.utf16))
        keyUpEvent.post(tap: .cghidEventTap)
        
        return true
    }
    
    /// Posts a backspace key event
    private func postBackspaceEvent() {
        let keyCode: CGKeyCode = 51 // Backspace key code
        
        if let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) {
            keyDownEvent.post(tap: .cghidEventTap)
        }
        
        Thread.sleep(forTimeInterval: 0.01)
        
        if let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) {
            keyUpEvent.post(tap: .cghidEventTap)
        }
    }
    
    /// Posts an enter/return key event
    private func postEnterEvent() {
        let keyCode: CGKeyCode = 36 // Return key code
        
        if let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) {
            keyDownEvent.post(tap: .cghidEventTap)
        }
        
        Thread.sleep(forTimeInterval: 0.01)
        
        if let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) {
            keyUpEvent.post(tap: .cghidEventTap)
        }
    }
}
