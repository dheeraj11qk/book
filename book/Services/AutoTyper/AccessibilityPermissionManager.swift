//
//  AccessibilityPermissionManager.swift
//  Clipboard Auto-Typer
//
//  Created for clipboard auto-typing feature
//

import Foundation
import AppKit

/// Manages accessibility permission checking and prompting
class AccessibilityPermissionManager {
    
    /// Checks if accessibility permissions are granted
    static func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Prompts the user to grant accessibility permissions
    static func promptForAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "The Auto-Type feature requires accessibility permissions to simulate keyboard input. Please enable it in System Preferences > Security & Privacy > Privacy > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            openAccessibilityPreferences()
        }
    }
    
    /// Opens the Accessibility preferences pane in System Preferences
    private static func openAccessibilityPreferences() {
        let prefpaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(prefpaneURL)
    }
    
    /// Requests accessibility permission with prompt
    static func requestAccessibilityPermission() {
        // This will trigger the system prompt if not already granted
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
}
