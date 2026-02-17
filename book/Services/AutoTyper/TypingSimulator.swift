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
    
    /// Types the given text with human-like delays and speed variations
    /// - Parameters:
    ///   - text: The text to type
    ///   - onSpeedChange: Callback when speed mode changes
    ///   - completion: Callback when typing completes or stops
    func typeText(_ text: String, onSpeedChange: @escaping (SpeedMode) -> Void, completion: @escaping () -> Void) {
        guard !isTyping else { return }
        
        isTyping = true
        shouldStop = false
        
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
}
