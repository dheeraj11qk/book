//
//  UIState.swift
//  Clipboard Auto-Typer
//
//  Created for clipboard auto-typing feature
//

import Foundation

/// Represents the current state of the floating UI
enum UIState: Equatable {
    case idle
    case countdown(Int)  // Associated value: remaining seconds
    case typing(SpeedMode)  // Associated value: current speed mode
    case paused(SpeedMode)  // Associated value: speed mode when paused
    
    static func == (lhs: UIState, rhs: UIState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.countdown(let a), .countdown(let b)):
            return a == b
        case (.typing(let a), .typing(let b)):
            return a.rawValue == b.rawValue
        case (.paused(let a), .paused(let b)):
            return a.rawValue == b.rawValue
        default:
            return false
        }
    }
}
