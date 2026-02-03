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
        static let resumeFileName = "resumeFileName"
        static let resumeFilePath = "resumeFilePath"
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
    
    var resumeFileName: String {
        get { string(forKey: Keys.resumeFileName) ?? "" }
        set { set(newValue, forKey: Keys.resumeFileName) }
    }
    
    var resumeFilePath: String {
        get { string(forKey: Keys.resumeFilePath) ?? "" }
        set { set(newValue, forKey: Keys.resumeFilePath) }
    }
}