//
//  FloatingWindowController.swift
//  Clipboard Auto-Typer
//
//  Created for clipboard auto-typing feature
//

import SwiftUI
import AppKit

/// Manages the floating window configuration and lifecycle
class FloatingWindowController {
    private var window: NSWindow?
    private let viewModel: AutoTyperViewModel
    
    init(viewModel: AutoTyperViewModel) {
        self.viewModel = viewModel
    }
    
    /// Shows the floating window
    func show() {
        if window == nil {
            configureWindow()
        }
        
        window?.orderFrontRegardless()
        positionWindow()
    }
    
    /// Hides the floating window
    func hide() {
        window?.orderOut(nil)
    }
    
    /// Configures the floating window with required properties
    private func configureWindow() {
        // Create the SwiftUI content view
        let contentView = AutoTypeOverlay(viewModel: viewModel)
        
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 250, height: 50),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties with error handling
        window.contentView = NSHostingView(rootView: contentView)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        
        // Try to set window level, fallback if it fails
        do {
            window.level = .floating
        } catch {
            print("Failed to set window level to floating, using statusBar")
            window.level = .statusBar
        }
        
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isMovable = false
        
        // Prevent window from stealing focus
        window.styleMask.insert(.nonactivatingPanel)
        
        self.window = window
    }
    
    /// Positions the window at the top center of the screen
    private func positionWindow() {
        guard let window = window,
              let screen = NSScreen.main else {
            return
        }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        
        // Calculate center X position
        let x = screenFrame.midX - (windowFrame.width / 2)
        
        // Position at top with padding
        let y = screenFrame.maxY - windowFrame.height - 20
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
