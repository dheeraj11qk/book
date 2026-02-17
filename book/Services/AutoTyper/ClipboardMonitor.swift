//
//  ClipboardMonitor.swift
//  Clipboard Auto-Typer
//
//  Created for clipboard auto-typing feature
//

import Foundation
import AppKit

/// Monitors the system clipboard for text content changes
class ClipboardMonitor: ObservableObject {
    @Published var currentText: String?
    
    private var changeCount: Int = 0
    private var timer: Timer?
    private let pollingInterval: TimeInterval = 0.5 // 500ms
    
    /// Starts monitoring the clipboard for changes
    func startMonitoring() {
        // Initialize with current clipboard state
        changeCount = NSPasteboard.general.changeCount
        checkClipboard()
        
        // Start timer to poll clipboard every 500ms
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    /// Stops monitoring the clipboard
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Clears the current clipboard text
    func clearClipboard() {
        currentText = nil
        NSPasteboard.general.clearContents()
    }
    
    /// Checks the clipboard for changes and publishes text content
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        // Check if clipboard content has changed
        guard pasteboard.changeCount != changeCount else {
            return
        }
        
        changeCount = pasteboard.changeCount
        
        // Try to read text content from clipboard with error handling
        do {
            if let text = pasteboard.string(forType: .string), !text.isEmpty {
                currentText = text
            } else {
                // Non-text content or empty clipboard
                currentText = nil
            }
        } catch {
            // Log error but continue monitoring
            print("Error reading clipboard: \(error.localizedDescription)")
            currentText = nil
        }
    }
}
