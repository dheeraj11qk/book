//
//  SpeechCorrectionService.swift
//  book
//
//  Created by Dheeraj Gautam on 03/02/26.
//

import Foundation

class SpeechCorrectionService {
    private let apiService = GroqAPIService()
    
    func correctTranscript(_ rawTranscript: String) async throws -> String {
        let correctionPrompt = """
        Please correct the following speech-to-text transcript. Fix grammar, punctuation, capitalization, and any obvious transcription errors. Keep the meaning and intent intact. Return only the corrected text without any additional commentary.
        
        Raw transcript: "\(rawTranscript)"
        
        Corrected text:
        """
        
        return try await apiService.getSingleResponse(correctionPrompt)
    }
}