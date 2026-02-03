//
//  SettingsView.swift
//  book
//
//  Created by Dheeraj Gautam on 03/02/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hideFromCapture: Bool = UserDefaults.standard.hideFromCapture
    @State private var apiKey: String = UserDefaults.standard.openAIAPIKey
    @State private var showingAPIKeyEditor = false
    @State private var showingFilePicker = false
    @State private var resumeFileName: String = UserDefaults.standard.resumeFileName
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
        .sheet(isPresented: $showingAPIKeyEditor) {
            APIKeyEditorView(apiKey: $apiKey)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
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
                privacySection
                apiConfigSection
                resumeSection
                Spacer(minLength: 50)
            }
            .padding()
        }
        .background(Color.black.opacity(0.8))
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
    
    private var apiConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("API Configuration")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OpenAI API Key")
                        .foregroundColor(.white)
                    Text(apiKey.isEmpty ? "Not configured" : "••••••••••••••••")
                        .font(.caption)
                        .foregroundColor(apiKey.isEmpty ? .red : .green)
                }
                
                Spacer()
                
                Button(action: {
                    showingAPIKeyEditor = true
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
    
    private var resumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resume")
                .font(.headline)
                .foregroundColor(.white)
            
            resumeFileRow
        }
    }
    
    private var resumeFileRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Resume File")
                    .foregroundColor(.white)
                Text(resumeFileName.isEmpty ? "No file added" : resumeFileName)
                    .font(.caption)
                    .foregroundColor(resumeFileName.isEmpty ? .gray : .green)
            }
            
            Spacer()
            
            Button(action: {
                showingFilePicker = true
            }) {
                Image(systemName: "plus.circle")
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
    
    private var resumePreview: some View {
        EmptyView()
    }
    
    private func saveSettings() {
        UserDefaults.standard.hideFromCapture = hideFromCapture
        UserDefaults.standard.openAIAPIKey = apiKey
        
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
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource")
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                // Get the file name
                let fileName = url.lastPathComponent
                
                // Copy file to app's documents directory
                let fileManager = FileManager.default
                let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let destinationURL = documentsURL.appendingPathComponent("resume.pdf")
                
                // Remove existing file if present
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                
                // Copy the file
                try fileManager.copyItem(at: url, to: destinationURL)
                
                // Save file name and path
                resumeFileName = fileName
                UserDefaults.standard.resumeFileName = fileName
                UserDefaults.standard.resumeFilePath = destinationURL.path
                
                print("Resume saved: \(fileName)")
            } catch {
                print("Error saving resume: \(error)")
            }
            
        case .failure(let error):
            print("File import error: \(error)")
        }
    }
}

struct APIKeyEditorView: View {
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
                
                Text("API Key")
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
                Text("Enter your Groq API Key")
                    .font(.headline)
                    .foregroundColor(.white)
                
                SecureField("API Key", text: $tempAPIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Text("You can get your API key from the Groq Console")
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