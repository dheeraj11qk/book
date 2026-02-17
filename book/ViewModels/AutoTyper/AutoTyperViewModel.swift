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
    
    private let clipboardMonitor: ClipboardMonitor
    private let typingSimulator: TypingSimulator
    private var countdownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var capturedText: String?
    
    init(clipboardMonitor: ClipboardMonitor = ClipboardMonitor(),
         typingSimulator: TypingSimulator = TypingSimulator()) {
        self.clipboardMonitor = clipboardMonitor
        self.typingSimulator = typingSimulator
        
        // Subscribe to clipboard changes
        clipboardMonitor.$currentText
            .sink { [weak self] text in
                self?.clipboardText = text
            }
            .store(in: &cancellables)
    }
    
    /// Starts the auto-type operation with countdown
    func startAutoType() {
        guard state == .idle, let text = clipboardText, !text.isEmpty else {
            return
        }
        
        // Capture the current clipboard text
        capturedText = text
        startCountdown()
    }
    
    /// Stops the current operation (countdown or typing)
    func stop() {
        switch state {
        case .countdown:
            countdownTimer?.invalidate()
            countdownTimer = nil
            state = .idle
            
        case .typing:
            typingSimulator.stop()
            state = .idle
            
        case .idle:
            break
        }
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
    
    /// Begins the typing operation
    private func beginTyping() {
        guard let text = capturedText, !text.isEmpty else {
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
        
        typingSimulator.typeText(text,
                                onSpeedChange: { [weak self] mode in
            DispatchQueue.main.async {
                self?.state = .typing(mode)
            }
        },
                                completion: { [weak self] in
            DispatchQueue.main.async {
                self?.state = .idle
                self?.capturedText = nil
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
