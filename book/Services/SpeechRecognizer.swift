//
//  SpeechRecognizer.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var isProcessing = false // New state for AI correction
    
    var onTranscriptUpdate: ((String) -> Void)?
    var onRecordingStop: (() -> Void)?
    var onCorrectedTranscript: ((String) -> Void)? // New callback for corrected text
    
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioTapInstalled = false
    private let correctionService = SpeechCorrectionService()
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.errorMessage = nil
                case .denied:
                    self.errorMessage = "Speech recognition access denied"
                case .restricted:
                    self.errorMessage = "Speech recognition restricted"
                case .notDetermined:
                    self.errorMessage = "Speech recognition not determined"
                @unknown default:
                    self.errorMessage = "Unknown authorization status"
                }
            }
        }
    }
    
    func startRecording() {
        // Clean up any existing recording
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Reset audio engine if needed
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        if audioTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioTapInstalled = false
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let rawTranscript = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcript = rawTranscript
                    self.onTranscriptUpdate?(rawTranscript)
                }
                
                // If this is the final result, process it through AI correction
                if result.isFinal {
                    Task {
                        await self.processTranscriptCorrection(rawTranscript)
                    }
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.cleanup()
            }
        }
        
        do {
            try setupMicrophoneCapture()
            
            audioEngine.prepare()
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.errorMessage = nil
            }
        } catch {
            errorMessage = "Audio setup error: \(error.localizedDescription)"
            cleanup()
        }
    }
    
    private func processTranscriptCorrection(_ rawTranscript: String) async {
        guard !rawTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Check if voice enhancement is enabled
        let enhancementEnabled = UserDefaults.standard.voiceEnhancementEnabled
        
        if !enhancementEnabled {
            // Skip AI enhancement, use raw transcript
            await MainActor.run {
                self.transcript = rawTranscript
                self.onCorrectedTranscript?(rawTranscript)
            }
            return
        }
        
        await MainActor.run {
            self.isProcessing = true
        }
        
        do {
            let correctedText = try await correctionService.correctTranscript(rawTranscript)
            
            await MainActor.run {
                self.transcript = correctedText
                self.isProcessing = false
                self.onCorrectedTranscript?(correctedText)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to correct transcript: \(error.localizedDescription)"
                self.isProcessing = false
                // Fall back to raw transcript
                self.onCorrectedTranscript?(rawTranscript)
            }
        }
    }
    
    private func setupMicrophoneCapture() throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            throw NSError(domain: "SpeechRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid audio format"])
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        audioTapInstalled = true
    }
    
    func stopRecording() {
        cleanup()
        onRecordingStop?()
    }
    
    private func cleanup() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        if audioTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioTapInstalled = false
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}
