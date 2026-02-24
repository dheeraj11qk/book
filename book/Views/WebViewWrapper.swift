//
//  WebViewWrapper.swift
//  book
//
//  Created by Kiro AI
//

import SwiftUI
import WebKit

struct WebViewWrapper: NSViewRepresentable {
    @Binding var url: URL?
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    var webViewStore: WebViewStore?
    
    init(url: Binding<URL?>, 
         isLoading: Binding<Bool>, 
         canGoBack: Binding<Bool>, 
         canGoForward: Binding<Bool>,
         webViewStore: WebViewStore? = nil) {
        self._url = url
        self._isLoading = isLoading
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self.webViewStore = webViewStore
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webViewStore?.webView = webView
        
        // Load initial URL if provided
        if let url = url {
            print("🚀 makeNSView: Loading initial URL: \(url)")
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Update coordinator reference
        context.coordinator.parent = self
        
        // DO NOT load URLs here - this causes the reload loop
        // URLs should only be loaded when explicitly requested via loadURL()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// Store to hold WKWebView reference
class WebViewStore: ObservableObject {
    var webView: WKWebView?
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func loadURL(_ url: URL) {
        print("🚀 WebViewStore: Loading URL: \(url)")
        let request = URLRequest(url: url)
        webView?.load(request)
    }
}

extension WebViewWrapper {
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewWrapper
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🔵 Navigation started")
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Navigation finished: \(webView.url?.absoluteString ?? "unknown")")
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                if (error as NSError).code != NSURLErrorCancelled {
                    print("❌ Navigation failed: \(error.localizedDescription)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                if (error as NSError).code != NSURLErrorCancelled {
                    print("❌ Provisional navigation failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
