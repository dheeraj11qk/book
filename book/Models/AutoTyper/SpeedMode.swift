//
//  SpeedMode.swift
//  Clipboard Auto-Typer
//
//  Created for clipboard auto-typing feature
//

import Foundation

/// Represents typing speed categories with associated delay ranges
/// Target: 40-50 WPM (realistic human typing speed)
enum SpeedMode: String, CaseIterable {
    case slow = "Slow typing"
    case normal = "Typing"
    case littleFast = "Little Fast Typing"
    case thinking = "Thinking"
    
    /// Returns the delay range for this speed mode in seconds
    /// Calibrated for realistic 40-50 WPM typing speed
    var delayRange: ClosedRange<TimeInterval> {
        switch self {
        case .slow:
            return 0.35...0.50  // Careful, deliberate typing
        case .normal:
            return 0.20...0.35  // Target 40-50 WPM (0.25s average)
        case .littleFast:
            return 0.12...0.20  // Faster, confident bursts
        case .thinking:
            return 0.80...1.50  // Reading/thinking pauses
        }
    }
}
