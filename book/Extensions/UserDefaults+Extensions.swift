//
//  UserDefaults+Extensions.swift
//  book
//
//  Created by Dheeraj Gautam on 03/02/26.
//

import Foundation

extension UserDefaults {
    // Settings Keys
    struct Keys {
        static let hideFromCapture = "hideFromCapture"
        static let openAIAPIKey = "openAIAPIKey"
        static let groqAPIKey = "groqAPIKey"
        static let selectedAIProvider = "selectedAIProvider"
        static let voiceEnhancementEnabled = "voiceEnhancementEnabled"
        static let resumeFileName = "resumeFileName"
        static let resumeFilePath = "resumeFilePath"
        static let resumeSummary = "resumeSummary"
    }
    
    // Convenience methods for settings
    var hideFromCapture: Bool {
        get { bool(forKey: Keys.hideFromCapture) }
        set { set(newValue, forKey: Keys.hideFromCapture) }
    }
    
    var openAIAPIKey: String {
        get { string(forKey: Keys.openAIAPIKey) ?? "" }
        set { set(newValue, forKey: Keys.openAIAPIKey) }
    }
    
    var groqAPIKey: String {
        get { string(forKey: Keys.groqAPIKey) ?? "" }
        set { set(newValue, forKey: Keys.groqAPIKey) }
    }
    
    var selectedAIProvider: String {
        get { string(forKey: Keys.selectedAIProvider) ?? "OpenAI" }
        set { set(newValue, forKey: Keys.selectedAIProvider) }
    }
    
    var voiceEnhancementEnabled: Bool {
        get { 
            // Default to true if not set
            if object(forKey: Keys.voiceEnhancementEnabled) == nil {
                return true
            }
            return bool(forKey: Keys.voiceEnhancementEnabled)
        }
        set { set(newValue, forKey: Keys.voiceEnhancementEnabled) }
    }
    
    var resumeFileName: String {
        get { string(forKey: Keys.resumeFileName) ?? "" }
        set { set(newValue, forKey: Keys.resumeFileName) }
    }
    
    var resumeFilePath: String {
        get { string(forKey: Keys.resumeFilePath) ?? "" }
        set { set(newValue, forKey: Keys.resumeFilePath) }
    }
    
    var resumeSummary: String {
        get { string(forKey: Keys.resumeSummary) ?? "" }
        set { set(newValue, forKey: Keys.resumeSummary) }
    }
}