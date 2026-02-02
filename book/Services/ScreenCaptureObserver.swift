//
//  ScreenCaptureObserver.swift
//  book
//
//  Created by Dheeraj Gautam on 03/02/26.
//

import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

final class ScreenCaptureObserver: ObservableObject {
    @Published var isCaptured: Bool = {
        #if canImport(UIKit)
        // Placeholder, will be immediately set in init via computeIsCaptured
        return UIScreen.screens.contains { $0.isCaptured }
        #else
        return false
        #endif
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    private func computeIsCaptured() -> Bool {
        #if canImport(UIKit)
        // Consider all connected screens for capture status
        return UIScreen.screens.contains { $0.isCaptured }
        #else
        return false
        #endif
    }
    
    init() {
        #if canImport(UIKit)
        NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)
            .sink { [weak self] _ in
                self?.isCaptured = self?.computeIsCaptured() ?? false
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.isCaptured = self?.computeIsCaptured() ?? false
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.isCaptured = self?.computeIsCaptured() ?? false
            }
            .store(in: &cancellables)
        #endif
    }
    
    #if canImport(AppKit)
    func updateWindowSharingType(isHidden: Bool) {
        for window in NSApplication.shared.windows {
            window.sharingType = isHidden ? .none : .readOnly
        }
    }
    #endif
}