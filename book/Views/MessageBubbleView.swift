//
//  MessageBubbleView.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.isUser {
                Spacer()
                
                // User message - right side
                VStack(alignment: .trailing, spacing: 8) {
                    // Show images if present
                    if !message.images.isEmpty {
                        ForEach(Array(message.images.enumerated()), id: \.offset) { _, image in
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: 200, maxHeight: 200)
                                .cornerRadius(8)
                                .clipped()
                        }
                    }
                    
                    Text(message.text)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(red: 0.3, green: 0.3, blue: 0.3).opacity(0.9))
                        .cornerRadius(12)
                }
                .frame(maxWidth: 400, alignment: .trailing)
            } else {
                // AI message - left side full width with code formatting
                FormattedTextView(text: message.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .id(message.id)
    }
}

struct FormattedTextView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let parts = parseText(text)
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                if part.isCode {
                    CodeBlockView(code: part.content, language: part.language)
                } else {
                    FormattedMarkdownText(text: part.content)
                        .padding(.horizontal, 12)
                }
            }
        }
    }
    
    private func parseText(_ text: String) -> [TextPart] {
        var parts: [TextPart] = []
        let pattern = "```(\\w+)?\\n([\\s\\S]*?)```"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [TextPart(content: text, isCode: false, language: nil)]
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var lastIndex = 0
        
        for match in matches {
            // Add text before code block
            if match.range.location > lastIndex {
                let textRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                let textContent = nsString.substring(with: textRange)
                if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    parts.append(TextPart(content: textContent, isCode: false, language: nil))
                }
            }
            
            // Add code block
            let languageRange = match.range(at: 1)
            let codeRange = match.range(at: 2)
            
            let language = languageRange.location != NSNotFound ? nsString.substring(with: languageRange) : nil
            let code = nsString.substring(with: codeRange)
            
            parts.append(TextPart(content: code, isCode: true, language: language))
            
            lastIndex = match.range.location + match.range.length
        }
        
        // Add remaining text
        if lastIndex < nsString.length {
            let textRange = NSRange(location: lastIndex, length: nsString.length - lastIndex)
            let textContent = nsString.substring(with: textRange)
            if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append(TextPart(content: textContent, isCode: false, language: nil))
            }
        }
        
        return parts.isEmpty ? [TextPart(content: text, isCode: false, language: nil)] : parts
    }
}

struct FormattedMarkdownText: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let lines = text.components(separatedBy: "\n")
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                formatLine(line)
            }
        }
    }
    
    @ViewBuilder
    private func formatLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.isEmpty {
            Spacer().frame(height: 4)
        } else if trimmed.hasPrefix("# ") {
            // H1
            Text(trimmed.dropFirst(2))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        } else if trimmed.hasPrefix("## ") {
            // H2
            Text(trimmed.dropFirst(3))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        } else if trimmed.hasPrefix("### ") {
            // H3
            Text(trimmed.dropFirst(4))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        } else if let match = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
            // Numbered list
            HStack(alignment: .top, spacing: 8) {
                Text(String(trimmed[match]))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(formatInlineStyles(String(trimmed[match.upperBound...])))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            // Bullet list
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(formatInlineStyles(String(trimmed.dropFirst(2))))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        } else {
            // Regular text
            Text(formatInlineStyles(trimmed))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func formatInlineStyles(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        
        // Bold **text**
        if let boldRegex = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: []) {
            let nsString = text as NSString
            let matches = boldRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: text) {
                    let boldText = String(text[range])
                    if let attrRange = attributed.range(of: "**\(boldText)**") {
                        attributed.replaceSubrange(attrRange, with: AttributedString(boldText))
                        if let newRange = attributed.range(of: boldText) {
                            attributed[newRange].font = .system(size: 16, weight: .bold)
                        }
                    }
                }
            }
        }
        
        // Italic *text*
        if let italicRegex = try? NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", options: []) {
            let nsString = text as NSString
            let matches = italicRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: text) {
                    let italicText = String(text[range])
                    if let attrRange = attributed.range(of: "*\(italicText)*") {
                        attributed.replaceSubrange(attrRange, with: AttributedString(italicText))
                        if let newRange = attributed.range(of: italicText) {
                            attributed[newRange].font = .system(size: 16).italic()
                        }
                    }
                }
            }
        }
        
        return attributed
    }
}

struct TextPart {
    let content: String
    let isCode: Bool
    let language: String?
}

struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language and copy button
            HStack {
                Text(language ?? "code")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(copied ? "Copied" : "Copy code")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            
            // Code content with syntax highlighting
            ScrollView(.horizontal, showsIndicators: false) {
                SyntaxHighlightedText(code: code, language: language ?? "")
                    .padding(12)
            }
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
        .cornerRadius(8)
        .padding(.horizontal, 12)
    }
}

struct SyntaxHighlightedText: View {
    let code: String
    let language: String
    
    var body: some View {
        Text(highlightedCode())
            .font(.system(size: 14, design: .monospaced))
    }
    
    private func highlightedCode() -> AttributedString {
        var attributedString = AttributedString(code)
        
        // Keywords
        let keywords = ["func", "var", "let", "if", "else", "for", "while", "return", "class", "struct", "enum", "import", "private", "public", "static", "override", "init", "self", "true", "false", "nil", "guard", "switch", "case", "break", "continue", "in", "as", "is", "try", "catch", "throw", "async", "await", "def", "print", "from"]
        
        for keyword in keywords {
            if let range = attributedString.range(of: "\\b\(keyword)\\b", options: .regularExpression) {
                attributedString[range].foregroundColor = Color(red: 1.0, green: 0.4, blue: 0.7) // Pink
            }
        }
        
        // Strings
        if let range = attributedString.range(of: "\"[^\"]*\"", options: .regularExpression) {
            attributedString[range].foregroundColor = Color(red: 0.8, green: 0.9, blue: 0.5) // Green
        }
        
        // Numbers
        if let range = attributedString.range(of: "\\b\\d+\\b", options: .regularExpression) {
            attributedString[range].foregroundColor = Color(red: 0.7, green: 0.8, blue: 1.0) // Light blue
        }
        
        // Comments
        if let range = attributedString.range(of: "//.*", options: .regularExpression) {
            attributedString[range].foregroundColor = Color.gray
        }
        
        // Default color for rest
        attributedString.foregroundColor = .white
        
        return attributedString
    }
}
