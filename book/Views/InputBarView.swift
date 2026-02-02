//
//  InputBarView.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import SwiftUI

struct InputBarView: View {
    @Binding var inputText: String
    @Binding var selectedPrompt: PromptTemplate
    let isRecording: Bool
    let isProcessing: Bool
    let isLoading: Bool
    let screenshots: [NSImage]
    let systemAudioOnly: Bool
    let onMicTap: () -> Void
    let onScreenshotTap: () -> Void
    let onRemoveScreenshot: (Int) -> Void
    let onSend: () -> Void
    let onStop: () -> Void
    
    private var canSend: Bool {
        !isRecording && !isProcessing && (!inputText.trimmingCharacters(in: .whitespaces).isEmpty || !screenshots.isEmpty)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Screenshot preview
            if !screenshots.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(screenshots.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                                    .clipped()
                                
                                Button(action: {
                                    onRemoveScreenshot(index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: 90)
            }
            
            HStack(spacing: 12) {
                // Prompt dropdown
                Menu {
                    ForEach(PromptTemplate.allCases, id: \.self) { template in
                        Button(action: {
                            selectedPrompt = template
                        }) {
                            HStack {
                                Text(template.rawValue)
                                if selectedPrompt == template {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPrompt.rawValue)
                            .font(.system(size: 14))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.4, green: 0.4, blue: 0.4).opacity(0.9))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help(selectedPrompt.description)
                
                // Screenshot button
                Button(action: onScreenshotTap) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.9))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // Mic button - always enabled, captures based on toggle state
                Button(action: onMicTap) {
                    if isProcessing {
                        // Show processing indicator
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .frame(width: 44, height: 44)
                            .background(Color.orange.opacity(0.9))
                            .cornerRadius(8)
                    } else {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(isRecording ? Color.red.opacity(0.9) : Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.9))
                            .cornerRadius(8)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                
                // Input text field
                TextField("Type here you questions...", text: $inputText)
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.45, green: 0.45, blue: 0.45).opacity(0.9))
                    .cornerRadius(8)
                    .disabled(isRecording)
                    .onSubmit {
                        if canSend {
                            onSend()
                        }
                    }
                
                // Send/Stop button
                Button(action: {
                    if isLoading {
                        onStop()
                    } else {
                        onSend()
                    }
                }) {
                    Image(systemName: isLoading ? "stop.fill" : "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(isLoading ? Color.red.opacity(0.9) : (canSend ? Color.blue.opacity(0.9) : Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.5)))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(!isLoading && !canSend)
            }
            .padding(12)
        }
    }
}
