//
//  OpenAIService.swift
//  book
//
//  Created by Dheeraj Gautam on 04/02/26.
//

import Foundation
import AppKit

enum AIModel: String {
    case whisperLargeV3Turbo = "whisper-large-v3-turbo"
    case gpt35Turbo = "gpt-3.5-turbo"
    case gpt4Turbo = "gpt-4-turbo"
    case gpt4oMini = "gpt-4o-mini"
}

class OpenAIService {
    private var apiKey: String {
        let userDefaultsKey = UserDefaults.standard.openAIAPIKey
        return !userDefaultsKey.isEmpty ? userDefaultsKey : APIKeys.groqAPIKey
    }
    
    private let baseURL = "https://api.openai.com/v1"
    
    // MARK: - Chat Completion (Text)
    
    func streamMessage(_ message: String, model: AIModel, onChunk: @escaping (String) -> Void) async throws {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = ChatRequest(
            model: model.rawValue,
            messages: [ChatMessage(role: "user", content: message)],
            stream: true
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        var buffer = ""
        
        for try await line in bytes.lines {
            if Task.isCancelled {
                break
            }
            
            if line.hasPrefix("data: ") {
                let data = line.dropFirst(6)
                
                if data == "[DONE]" {
                    break
                }
                
                if let jsonData = data.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    buffer += content
                    await MainActor.run {
                        onChunk(buffer)
                    }
                }
            }
        }
    }
    
    func getSingleResponse(_ message: String, model: AIModel) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = ChatRequest(
            model: model.rawValue,
            messages: [ChatMessage(role: "user", content: message)],
            stream: false
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Vision (Image + Text)
    
    func sendMessageWithImage(_ message: String, image: NSImage, model: AIModel, onChunk: @escaping (String) -> Void) async throws {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Convert image to base64
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw APIError.invalidResponse
        }
        
        let base64Image = pngData.base64EncodedString()
        
        let messageContent: [[String: Any]] = [
            ["type": "text", "text": message],
            ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(base64Image)"]]
        ]
        
        let requestBody: [String: Any] = [
            "model": model.rawValue,
            "messages": [
                ["role": "user", "content": messageContent]
            ],
            "stream": true,
            "max_tokens": 1000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        var buffer = ""
        
        for try await line in bytes.lines {
            if Task.isCancelled {
                break
            }
            
            if line.hasPrefix("data: ") {
                let data = line.dropFirst(6)
                
                if data == "[DONE]" {
                    break
                }
                
                if let jsonData = data.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    buffer += content
                    await MainActor.run {
                        onChunk(buffer)
                    }
                }
            }
        }
    }
    
    // MARK: - Whisper (Audio Transcription)
    
    func transcribeAudio(_ audioURL: URL) async throws -> String {
        let url = URL(string: "\(baseURL)/audio/transcriptions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        
        let audioData = try Data(contentsOf: audioURL)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw APIError.invalidResponse
        }
        
        return text
    }
}
