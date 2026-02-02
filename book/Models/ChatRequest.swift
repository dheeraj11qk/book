//
//  ChatRequest.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import Foundation

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let stream: Bool
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}
