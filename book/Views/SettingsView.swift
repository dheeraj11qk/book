//
//  SettingsView.swift
//  book
//
//  Created by Dheeraj Gautam on 03/02/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hideFromCapture: Bool = UserDefaults.standard.hideFromCapture
    @State private var openAIAPIKey: String = UserDefaults.standard.openAIAPIKey
    @State private var groqAPIKey: String = UserDefaults.standard.groqAPIKey
    @State private var selectedAIProvider: String = UserDefaults.standard.selectedAIProvider
    @State private var voiceEnhancementEnabled: Bool = UserDefaults.standard.voiceEnhancementEnabled
    @State private var userSummary: String = UserDefaults.standard.userSummary
    @State private var showingOpenAIKeyEditor = false
    @State private var showingGroqKeyEditor = false
    @State private var showingSaveAlert = false
    
    private var shouldHideFromCapture: Bool {
        UserDefaults.standard.hideFromCapture
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            settingsContentView
        }
        .background(Color.black.opacity(0.9))
        .privacySensitive(shouldHideFromCapture)
        .sheet(isPresented: $showingOpenAIKeyEditor) {
            APIKeyEditorView(title: "OpenAI API Key", apiKey: $openAIAPIKey)
        }
        .sheet(isPresented: $showingGroqKeyEditor) {
            APIKeyEditorView(title: "Groq API Key", apiKey: $groqAPIKey)
        }
        .alert("Settings Saved", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text("Your settings have been saved successfully.")
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Text("Settings")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Save") {
                saveSettings()
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    private var settingsContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                userSummarySection
                privacySection
                voiceEnhancementSection
                apiConfigSection
                Spacer(minLength: 50)
            }
            .padding()
        }
        .background(Color.black.opacity(0.8))
    }
    
    private var userSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Summary")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Resume / Profile Summary")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextEditor(text: $userSummary)
                    .frame(minHeight: 120, maxHeight: 200)
                    .padding(8)
                    .background(Color.black)
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .scrollContentBackground(.hidden)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                
                Text("Add your resume summary, skills, experience, or any personal context you want the AI to know about you.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
    }
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hide from Screen Capture")
                        .foregroundColor(.white)
                    Text("Hide content when screen recording or sharing")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: $hideFromCapture)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
    }
    
    private var voiceEnhancementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice Input")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Voice Enhancement")
                        .foregroundColor(.white)
                    Text(voiceEnhancementEnabled ? "AI enhances speech-to-text" : "Simple voice-to-text only")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: $voiceEnhancementEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
    }
    
    private var apiConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("API Configuration")
                .font(.headline)
                .foregroundColor(.white)
            
            // AI Provider Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Provider")
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                Picker("", selection: $selectedAIProvider) {
                    Text("OpenAI").tag("OpenAI")
                    Text("Groq").tag("Groq")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            
            // OpenAI API Key
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OpenAI API Key")
                        .foregroundColor(.white)
                    Text(openAIAPIKey.isEmpty ? "Not configured" : "••••••••••••••••")
                        .font(.caption)
                        .foregroundColor(openAIAPIKey.isEmpty ? .red : .green)
                }
                
                Spacer()
                
                Button(action: {
                    showingOpenAIKeyEditor = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            
            // Groq API Key
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Groq API Key")
                        .foregroundColor(.white)
                    Text(groqAPIKey.isEmpty ? "Not configured" : "••••••••••••••••")
                        .font(.caption)
                        .foregroundColor(groqAPIKey.isEmpty ? .red : .green)
                }
                
                Spacer()
                
                Button(action: {
                    showingGroqKeyEditor = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.hideFromCapture = hideFromCapture
        UserDefaults.standard.openAIAPIKey = openAIAPIKey
        UserDefaults.standard.groqAPIKey = groqAPIKey
        UserDefaults.standard.selectedAIProvider = selectedAIProvider
        UserDefaults.standard.voiceEnhancementEnabled = voiceEnhancementEnabled
        UserDefaults.standard.userSummary = userSummary
        
        showingSaveAlert = true
        
        // Update window sharing type
        #if canImport(AppKit)
        for window in NSApplication.shared.windows {
            window.sharingType = hideFromCapture ? .none : .readOnly
        }
        #endif
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

struct APIKeyEditorView: View {
    let title: String
    @Binding var apiKey: String
    @Environment(\.dismiss) private var dismiss
    @State private var tempAPIKey: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Save") {
                    apiKey = tempAPIKey
                    dismiss()
                }
                .foregroundColor(.blue)
                .disabled(tempAPIKey.isEmpty)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            
            // Content
            VStack(spacing: 20) {
                Text("Enter your \(title)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                SecureField("API Key", text: $tempAPIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Text("You can get your API key from the provider's console")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.8))
        }
        .background(Color.black.opacity(0.9))
        .onAppear {
            tempAPIKey = apiKey
        }
    }
}

#Preview {
    SettingsView()
}
