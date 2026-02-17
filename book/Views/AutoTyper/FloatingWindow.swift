//
//  FloatingWindow.swift
//  Clipboard Auto-Typer
//
//  Created for clipboard auto-typing feature
//

import SwiftUI

/// SwiftUI view that renders the auto-type overlay interface inside the chat window
struct AutoTypeOverlay: View {
    @ObservedObject var viewModel: AutoTyperViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            // Show AI processing state
            if viewModel.isProcessingAI {
                Text("Processing...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue)
                
                Button(action: {
                    viewModel.stop()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                switch viewModel.state {
                case .idle:
                    Text("Auto Type")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        viewModel.startAutoType()
                    }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                case .countdown(let count):
                    Text("\(count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.orange)
                        .frame(minWidth: 18)
                    
                    Button(action: {
                        viewModel.stop()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                case .typing(let mode):
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green)
                        .lineLimit(1)
                    
                    // Pause button
                    Button(action: {
                        viewModel.pause()
                    }) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Stop button
                    Button(action: {
                        viewModel.stop()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                case .paused(let mode):
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.yellow)
                        .lineLimit(1)
                    
                    // Resume button
                    Button(action: {
                        viewModel.resume()
                    }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Stop button
                    Button(action: {
                        viewModel.stop()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    AutoTypeOverlay(viewModel: AutoTyperViewModel())
        .frame(width: 300, height: 200)
        .background(Color.gray.opacity(0.3))
}
