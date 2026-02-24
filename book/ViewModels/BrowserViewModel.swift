//
//  BrowserViewModel.swift
//  book
//
//  Created by Kiro AI
//

import Foundation
import Combine

class BrowserViewModel: ObservableObject {
    @Published var currentURL: URL?
    @Published var urlText: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var errorMessage: String?
    
    var webViewStore: WebViewStore?
    
    func loadURL(_ urlString: String) {
        var finalURLString = urlString.trimmingCharacters(in: .whitespaces)
        
        // Auto-prepend https:// if no protocol is specified
        if !finalURLString.isEmpty && !finalURLString.hasPrefix("http://") && !finalURLString.hasPrefix("https://") {
            finalURLString = "https://" + finalURLString
        }
        
        guard let url = URL(string: finalURLString), url.scheme != nil else {
            errorMessage = "Invalid URL format"
            return
        }
        
        print("✅ BrowserViewModel: Loading URL: \(url)")
        currentURL = url
        urlText = finalURLString
        errorMessage = nil
        
        // Load via WebViewStore instead of binding
        webViewStore?.loadURL(url)
    }
    
    func goBack() {
        // This will be called by the view, actual navigation handled by WKWebView
    }
    
    func goForward() {
        // This will be called by the view, actual navigation handled by WKWebView
    }
    
    func reload() {
        // This will be called by the view, actual navigation handled by WKWebView
    }
    
    func updateNavigationState(canGoBack: Bool, canGoForward: Bool) {
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
    }
}
