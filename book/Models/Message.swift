//
//  Message.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import Foundation
import AppKit

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    let images: [NSImage]
    
    init(text: String, isUser: Bool, images: [NSImage] = []) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.images = images
    }
}
