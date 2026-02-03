//
//  bookApp.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import SwiftUI

@main
struct bookApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().onAppear{
                NSApp.setActivationPolicy(.regular)
            }.frame(minWidth: 600, minHeight: 400)
                .background(WindowAccessor())
        }
        .windowStyle(.hiddenTitleBar)
        .windowBackgroundDragBehavior(.enabled)
    }
}

// Window accessor to make window transparent and always on top
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = true
                window.titlebarAppearsTransparent = true
                // Make window always on top
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                // Ensure window stays on top
                window.level = .floating
            }
        }
    }
}
