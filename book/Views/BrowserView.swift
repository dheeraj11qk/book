//
//  BrowserView.swift
//  book
//
//  Created by Kiro AI
//

import SwiftUI
import WebKit

struct BrowserView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var webViewStore: WebViewStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack(spacing: 12) {
                // Back button
                Button(action: {
                    webViewStore.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16))
                        .foregroundColor(viewModel.canGoBack ? .white : .gray)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canGoBack)
                
                // Forward button
                Button(action: {
                    webViewStore.goForward()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                        .foregroundColor(viewModel.canGoForward ? .white : .gray)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canGoForward)
                
                // Reload button
                Button(action: {
                    webViewStore.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                
                // URL TextField
                TextField("Enter URL", text: $viewModel.urlText)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .onSubmit {
                        viewModel.loadURL(viewModel.urlText)
                    }
                
                // Go button
                Button(action: {
                    viewModel.loadURL(viewModel.urlText)
                }) {
                    Text("Go")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                // Close button
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            
            // Linear progress bar (Chrome-style)
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 3)
                
                if viewModel.isLoading {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }
            }
            
            // Web content area
            WebViewWrapper(
                url: .constant(nil), // Don't use URL binding anymore
                isLoading: $viewModel.isLoading,
                canGoBack: $viewModel.canGoBack,
                canGoForward: $viewModel.canGoForward,
                webViewStore: webViewStore
            )
            .background(Color.white)
        }
        .onAppear {
            // Connect WebViewStore to ViewModel
            viewModel.webViewStore = webViewStore
            
            // Only set the default URL text, don't auto-load
            if viewModel.urlText.isEmpty {
                viewModel.urlText = "chatgpt.com"
            }
        }
    }
}
