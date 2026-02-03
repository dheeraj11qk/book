//
//  GroqAPIService.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import Foundation

class GroqAPIService {
    private var apiKey: String {
        // Use OpenAI API key from UserDefaults (shared preference)
        let userDefaultsKey = UserDefaults.standard.openAIAPIKey
        return !userDefaultsKey.isEmpty ? userDefaultsKey : APIKeys.groqAPIKey
    }
    private let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    
    private var currentTask: URLSessionDataTask?
    
    func streamMessage(_ message: String, onChunk: @escaping (String) -> Void) async throws {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = ChatRequest(
            model: "openai/gpt-oss-120b",
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
            // Check if task was cancelled
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
    
    func getSingleResponse(_ message: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = ChatRequest(
            model: "openai/gpt-oss-120b",
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
    
    func cancelStreaming() {
        currentTask?.cancel()
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case serverError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .serverError:
            return "Server error"
        case .invalidResponse:
            return "Invalid response format"
        }
    }
}
