//
//  AutoTyperViewModel.swift
//  Clipboard Auto-Typer
//
//  Created for clipboard auto-typing feature
//

import Foundation
import Combine

/// Manages UI state and coordinates between clipboard monitoring and typing simulation
class AutoTyperViewModel: ObservableObject {
    @Published var state: UIState = .idle
    @Published var clipboardText: String?
    @Published var isProcessingAI: Bool = false
    
    private let clipboardMonitor: ClipboardMonitor
    private let typingSimulator: TypingSimulator
    private let aiProcessor: AIResponseProcessor
    private var countdownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var capturedText: String?
    private var processedText: String?
    private var lastAICallTime: Date?
    
    init(clipboardMonitor: ClipboardMonitor = ClipboardMonitor(),
         typingSimulator: TypingSimulator = TypingSimulator(),
         aiProcessor: AIResponseProcessor = AIResponseProcessor()) {
        self.clipboardMonitor = clipboardMonitor
        self.typingSimulator = typingSimulator
        self.aiProcessor = aiProcessor
        
        // Subscribe to clipboard changes
        clipboardMonitor.$currentText
            .sink { [weak self] text in
                self?.clipboardText = text
            }
            .store(in: &cancellables)
    }
    
    /// Starts the auto-type operation with AI processing and countdown
    func startAutoType() {
        guard state == .idle, let text = clipboardText, !text.isEmpty else {
            return
        }
        
        // Check rate limiting (minimum 2 seconds between AI calls)
        if let lastCall = lastAICallTime, Date().timeIntervalSince(lastCall) < 2.0 {
            print("⚠️ Rate limit: Please wait before starting another auto-type")
            return
        }
        
        // Check text length
        if text.count > 2000 {
            print("⚠️ Text too long (max 2000 characters)")
            return
        }
        
        // Capture the current clipboard text
        capturedText = text
        
        // Process with AI first
        processWithAI()
    }
    /// Pauses the current typing operation
    func pause() {
        guard case .typing(let mode) = state else { return }
        typingSimulator.pause()
        state = .paused(mode)
    }
    
    /// Resumes the paused typing operation
    func resume() {
        guard case .paused(let mode) = state else { return }
        typingSimulator.resume()
        state = .typing(mode)
    }
    
    /// Processes clipboard text with AI before typing
    private func processWithAI() {
        guard let text = capturedText else { return }
        
        isProcessingAI = true
        lastAICallTime = Date()
        
        Task { @MainActor in
            do {
                print("🤖 Processing text with AI...")
                let analysis = try await aiProcessor.processClipboardText(text)
                processedText = analysis.formattedText
                
                // Pass AI analysis to typing behavior engine
                typingSimulator.setDifficultWords(analysis.difficultWords, pausePoints: analysis.pausePoints)
                
                print("✅ AI processing complete")
                print("📝 Difficult words identified: \(analysis.difficultWords.joined(separator: ", "))")
                print("📄 Formatted text length: \(analysis.formattedText.count) characters")
                print("📄 First 100 chars: \(String(analysis.formattedText.prefix(100)))")
                
                isProcessingAI = false
                startCountdown()
            } catch {
                print("❌ AI processing failed: \(error.localizedDescription)")
                isProcessingAI = false
                
                // Fall back to original text
                processedText = text
                startCountdown()
            }
        }
    }
    
    /// Stops the current operation (AI processing, countdown, or typing)
    func stop() {
        // Cancel AI processing
        if isProcessingAI {
            isProcessingAI = false
            state = .idle
            clearClipboard()
            return
        }
        
        switch state {
        case .countdown:
            countdownTimer?.invalidate()
            countdownTimer = nil
            state = .idle
            clearClipboard()
            
        case .typing, .paused:
            typingSimulator.stop()
            state = .idle
            clearClipboard()
            
        case .idle:
            break
        }
    }
    
    /// Clears the clipboard and hides the overlay
    private func clearClipboard() {
        clipboardText = nil
        capturedText = nil
        processedText = nil
        // Don't clear system clipboard, just clear our internal state
    }
    
    /// Starts the countdown from 3 to 1
    private func startCountdown() {
        var count = 3
        state = .countdown(count)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            count -= 1
            
            if count > 0 {
                self.state = .countdown(count)
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                self.beginTyping()
            }
        }
    }
    
    /// Begins the typing operation with AI-enhanced human behavior
    private func beginTyping() {
        guard let text = processedText, !text.isEmpty else {
            state = .idle
            return
        }
        
        // Check accessibility permissions before typing
        guard AccessibilityPermissionManager.hasAccessibilityPermission() else {
            state = .idle
            DispatchQueue.main.async {
                AccessibilityPermissionManager.promptForAccessibilityPermission()
            }
            return
        }
        
        // Start with initial speed mode
        state = .typing(.normal)
        
        // Use AI-enhanced behavior (typos, thinking pauses, etc.)
        typingSimulator.typeText(text,
                                useAIBehavior: true,
                                onSpeedChange: { [weak self] mode in
            DispatchQueue.main.async {
                self?.state = .typing(mode)
            }
        },
                                completion: { [weak self] in
            DispatchQueue.main.async {
                self?.state = .idle
                self?.capturedText = nil
                self?.processedText = nil
            }
        })
    }
    
    /// Starts clipboard monitoring
    func startMonitoring() {
        clipboardMonitor.startMonitoring()
    }
    
    /// Stops clipboard monitoring
    func stopMonitoring() {
        clipboardMonitor.stopMonitoring()
    }
}
