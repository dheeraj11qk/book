//
//  SettingsView.swift
//  book
//
//  Created by Dheeraj Gautam on 03/02/26.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hideFromCapture: Bool = UserDefaults.standard.hideFromCapture
    @State private var openAIAPIKey: String = UserDefaults.standard.openAIAPIKey
    @State private var groqAPIKey: String = UserDefaults.standard.groqAPIKey
    @State private var selectedAIProvider: String = UserDefaults.standard.selectedAIProvider
    @State private var voiceEnhancementEnabled: Bool = UserDefaults.standard.voiceEnhancementEnabled
    @State private var showingOpenAIKeyEditor = false
    @State private var showingGroqKeyEditor = false
    @State private var showingFilePicker = false
    @State private var resumeFileName: String = UserDefaults.standard.resumeFileName
    @State private var showingSaveAlert = false
    @State private var isGeneratingSummary = false
    
    private let openAIService = OpenAIService()
    
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
                voiceEnhancementSection
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
                if isGeneratingSummary {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        Text("Generating summary...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else {
                    Text(resumeFileName.isEmpty ? "No file added" : resumeFileName)
                        .font(.caption)
                        .foregroundColor(resumeFileName.isEmpty ? .gray : .green)
                }
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
            .disabled(isGeneratingSummary)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
    
    private func saveSettings() {
        UserDefaults.standard.hideFromCapture = hideFromCapture
        UserDefaults.standard.openAIAPIKey = openAIAPIKey
        UserDefaults.standard.groqAPIKey = groqAPIKey
        UserDefaults.standard.selectedAIProvider = selectedAIProvider
        UserDefaults.standard.voiceEnhancementEnabled = voiceEnhancementEnabled
        
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
                
                // Generate summary from resume
                generateResumeSummary(from: destinationURL)
                
            } catch {
                print("Error saving resume: \(error)")
            }
            
        case .failure(let error):
            print("File import error: \(error)")
        }
    }
    
    private func generateResumeSummary(from fileURL: URL) {
        isGeneratingSummary = true
        
        Task {
            do {
                // Read file content
                let fileContent: String
                if fileURL.pathExtension.lowercased() == "pdf" {
                    // Use PDFKit for PDF extraction
                    if let pdfDocument = PDFDocument(url: fileURL) {
                        var text = ""
                        for pageIndex in 0..<pdfDocument.pageCount {
                            if let page = pdfDocument.page(at: pageIndex) {
                                if let pageText = page.string {
                                    text += pageText + "\n"
                                }
                            }
                        }
                        fileContent = text
                    } else {
                        throw NSError(domain: "PDF", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read PDF"])
                    }
                } else {
                    fileContent = try String(contentsOf: fileURL, encoding: .utf8)
                }
                
                // Create summary prompt
                let summaryPrompt = """
                Please create a concise professional summary of this resume. Include:
                - Name and professional title
                - Key skills and expertise
                - Years of experience
                - Notable achievements or specializations
                - Education highlights
                
                Keep the summary under 150 words and focus on the most relevant professional information.
                
                Resume content:
                \(fileContent)
                
                Professional Summary:
                """
                
                // Generate summary using AI
                let summary = try await openAIService.getSingleResponse(summaryPrompt, model: .gpt35Turbo)
                
                // Save summary
                await MainActor.run {
                    UserDefaults.standard.resumeSummary = summary
                    isGeneratingSummary = false
                    print("Resume summary generated and saved")
                }
                
            } catch {
                await MainActor.run {
                    isGeneratingSummary = false
                    print("Error generating resume summary: \(error)")
                }
            }
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
