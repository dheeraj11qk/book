//
//  ScreenshotService.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import Foundation
import AppKit
import ScreenCaptureKit

class ScreenshotService: ObservableObject {
    @Published var screenshots: [NSImage] = []
    
    func takeScreenshot() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            guard let display = content.displays.first else { return }
            
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            configuration.width = Int(display.width)
            configuration.height = Int(display.height)
            
            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
            
            // Convert CGImage to NSImage
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            
            await MainActor.run {
                screenshots.append(nsImage)
            }
        } catch {
            print("Screenshot error: \(error)")
        }
    }
    
    func removeScreenshot(at index: Int) {
        guard index < screenshots.count else { return }
        screenshots.remove(at: index)
    }
    
    func clearScreenshots() {
        screenshots.removeAll()
    }
}
