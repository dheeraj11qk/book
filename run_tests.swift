#!/usr/bin/env swift

import Foundation

print("=== Book App Test Suite ===\n")

// Test 1: API Key Configuration
print("Test 1: API Key Configuration")
let apiKeyPath = "book/Config/APIKeys.swift"
if let content = try? String(contentsOfFile: apiKeyPath) {
    if content.contains("gsk_") && !content.contains("YOUR_GROQ_API_KEY_HERE") {
        print("✓ API key is configured")
    } else {
        print("✗ API key not properly configured")
    }
} else {
    print("✗ APIKeys.swift file not found")
}

// Test 2: Required Files
print("\nTest 2: Required Files")
let requiredFiles = [
    "book/bookApp.swift",
    "book/ContentView.swift",
    "book/ViewModels/ChatViewModel.swift",
    "book/Services/GroqAPIService.swift",
    "book/Services/SpeechRecognizer.swift",
    "book/Views/ChatView.swift",
    "book/Models/Message.swift"
]

var allFilesExist = true
for file in requiredFiles {
    let exists = FileManager.default.fileExists(atPath: file)
    print(exists ? "✓" : "✗", file)
    if !exists { allFilesExist = false }
}

// Test 3: Permissions
print("\nTest 3: Permissions in Info.plist")
if let plistContent = try? String(contentsOfFile: "book/Info.plist") {
    let hasMic = plistContent.contains("NSMicrophoneUsageDescription")
    let hasSpeech = plistContent.contains("NSSpeechRecognitionUsageDescription")
    print(hasMic ? "✓" : "✗", "Microphone permission")
    print(hasSpeech ? "✓" : "✗", "Speech recognition permission")
} else {
    print("✗ Info.plist not found")
}

// Test 4: Entitlements
print("\nTest 4: Entitlements")
if let entContent = try? String(contentsOfFile: "book/book.entitlements") {
    let hasAudio = entContent.contains("com.apple.security.device.audio-input")
    let hasNetwork = entContent.contains("com.apple.security.network.client")
    print(hasAudio ? "✓" : "✗", "Audio input entitlement")
    print(hasNetwork ? "✓" : "✗", "Network client entitlement")
} else {
    print("✗ Entitlements file not found")
}

print("\n=== Test Complete ===")
print("\nIf all tests pass, try:")
print("1. Open book.xcodeproj in Xcode")
print("2. Select your Mac as the target")
print("3. Press Cmd+R to build and run")
print("4. Grant microphone and speech recognition permissions when prompted")
