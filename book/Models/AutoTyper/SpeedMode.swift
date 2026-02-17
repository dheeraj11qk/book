//
//  SpeedMode.swift
//  Clipboard Auto-Typer
//
//  Created for clipboard auto-typing feature
//

import Foundation

/// Represents typing speed categories with associated delay ranges
enum SpeedMode: String, CaseIterable {
    case slow = "Slow typing"
    case normal = "Typing"
    case littleFast = "Little Fast Typing"
    case thinking = "Thinking"
    
    /// Returns the delay range for this speed mode in seconds
    var delayRange: ClosedRange<TimeInterval> {
        switch self {
        case .slow:
            return 0.15...0.30
        case .normal:
            return 0.08...0.15
        case .littleFast:
            return 0.04...0.08
        case .thinking:
            return 0.50...1.50
        }
    }
}
