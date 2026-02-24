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
    var onChatGPTReady: (() -> Void)?
    
    init(url: Binding<URL?>, 
         isLoading: Binding<Bool>, 
         canGoBack: Binding<Bool>, 
         canGoForward: Binding<Bool>,
         webViewStore: WebViewStore? = nil,
         onChatGPTReady: (() -> Void)? = nil) {
        self._url = url
        self._isLoading = isLoading
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self.webViewStore = webViewStore
        self.onChatGPTReady = onChatGPTReady
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Enable persistent data store for login sessions (like Chrome)
        let dataStore = WKWebsiteDataStore.default()
        config.websiteDataStore = dataStore
        
        // Enable JavaScript and other web features
        if #available(macOS 11.0, *) {
            // Use modern API for JavaScript control
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            #if compiler(>=5.5)
            // Fallback for older macOS versions
            #endif
        }
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Enable modern web features
        if #available(macOS 11.0, *) {
            config.preferences.isTextInteractionEnabled = true
        }
        
        // Enable media playback features (macOS specific)
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Set user agent to mimic a real browser (helps with OAuth)
        config.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        let contentController = WKUserContentController()
        
        // Add message handler for JavaScript communication
        contentController.add(context.coordinator, name: "chatGPTBridge")
        
        // Inject JavaScript to detect ChatGPT elements
        let chatGPTScript = """
        console.log('🚀 ChatGPT Bridge Script Loaded');
        
        // Multiple selector strategies for ChatGPT input detection
        function findChatGPTElements() {
            // Try multiple selectors for the input field
            const inputSelectors = [
                'textarea[data-id="root"]',
                'textarea[placeholder*="Message"]',
                'textarea[placeholder*="ChatGPT"]',
                '#prompt-textarea',
                'textarea[rows="1"]',
                'div[contenteditable="true"]',
                'textarea'
            ];
            
            // Try multiple selectors for the send button
            const sendButtonSelectors = [
                'button[data-testid="send-button"]',
                'button[aria-label*="Send"]',
                'button[type="submit"]',
                'button svg[data-icon="send"]',
                'button:has(svg)',
                '[data-testid="fruitjuice-send-button"]'
            ];
            
            let input = null;
            let sendButton = null;
            
            // Find input field
            for (const selector of inputSelectors) {
                try {
                    const element = document.querySelector(selector);
                    if (element && (element.offsetWidth > 0 || element.offsetHeight > 0)) {
                        input = element;
                        console.log('✅ Found input with selector:', selector);
                        break;
                    }
                } catch (e) {
                    console.log('❌ Selector failed:', selector, e);
                }
            }
            
            // Find send button
            for (const selector of sendButtonSelectors) {
                try {
                    const element = document.querySelector(selector);
                    if (element && (element.offsetWidth > 0 || element.offsetHeight > 0)) {
                        sendButton = element;
                        console.log('✅ Found send button with selector:', selector);
                        break;
                    }
                } catch (e) {
                    console.log('❌ Send button selector failed:', selector, e);
                }
            }
            
            return { input, sendButton };
        }
        
        // Wait for ChatGPT to load
        function waitForChatGPT() {
            const elements = findChatGPTElements();
            
            if (elements.input) {
                console.log('🎉 ChatGPT elements found!');
                window.webkit.messageHandlers.chatGPTBridge.postMessage({
                    type: 'ready',
                    message: 'ChatGPT interface is ready',
                    inputFound: !!elements.input,
                    sendButtonFound: !!elements.sendButton
                });
                return true;
            }
            return false;
        }
        
        // Function to inspect ChatGPT DOM elements
        function inspectChatGPTDOM() {
            console.log('� Inspecting ChatGPT DOM...');
            
            const report = {
                textareas: [],
                buttons: [],
                inputs: [],
                elementsWithIds: [],
                elementsWithDataTestId: []
            };
            
            // Find all textareas
            const textareas = document.querySelectorAll('textarea');
            textareas.forEach((textarea, index) => {
                report.textareas.push({
                    index: index,
                    id: textarea.id || 'no-id',
                    className: textarea.className || 'no-class',
                    placeholder: textarea.placeholder || 'no-placeholder',
                    name: textarea.name || 'no-name',
                    visible: textarea.offsetParent !== null,
                    tagName: textarea.tagName
                });
            });
            
            // Find all buttons
            const buttons = document.querySelectorAll('button');
            buttons.forEach((button, index) => {
                if (index < 20) { // Limit to first 20 buttons
                    report.buttons.push({
                        index: index,
                        id: button.id || 'no-id',
                        className: button.className || 'no-class',
                        ariaLabel: button.getAttribute('aria-label') || 'no-aria-label',
                        textContent: (button.textContent || '').trim().substring(0, 50),
                        visible: button.offsetParent !== null,
                        dataTestId: button.getAttribute('data-testid') || 'no-data-testid'
                    });
                }
            });
            
            // Find all input elements
            const inputs = document.querySelectorAll('input');
            inputs.forEach((input, index) => {
                report.inputs.push({
                    index: index,
                    id: input.id || 'no-id',
                    type: input.type || 'no-type',
                    className: input.className || 'no-class',
                    placeholder: input.placeholder || 'no-placeholder',
                    visible: input.offsetParent !== null
                });
            });
            
            // Find elements with IDs
            const elementsWithIds = document.querySelectorAll('[id]');
            elementsWithIds.forEach((element, index) => {
                if (index < 30) { // Limit to first 30
                    report.elementsWithIds.push({
                        id: element.id,
                        tagName: element.tagName,
                        className: element.className || 'no-class',
                        visible: element.offsetParent !== null
                    });
                }
            });
            
            // Find elements with data-testid
            const elementsWithDataTestId = document.querySelectorAll('[data-testid]');
            elementsWithDataTestId.forEach((element, index) => {
                if (index < 20) { // Limit to first 20
                    report.elementsWithDataTestId.push({
                        dataTestId: element.getAttribute('data-testid'),
                        tagName: element.tagName,
                        id: element.id || 'no-id',
                        className: element.className || 'no-class',
                        visible: element.offsetParent !== null
                    });
                }
            });
            
            console.log('📊 DOM Inspection Report:', report);
            return report;
        }
        
        // Function to send message to ChatGPT - ENHANCED KEYBOARD SIMULATION
        function sendToChatGPT(message) {
            console.log('📤 Attempting to send message:', message);
            
            // Strategy 1: Try ProseMirror editor (most reliable)
            const proseMirrorEditor = document.getElementById('prompt-textarea');
            
            if (proseMirrorEditor) {
                console.log('✅ Found ProseMirror editor');
                
                try {
                    // Focus the editor first
                    proseMirrorEditor.focus();
                    
                    // Clear any existing content
                    proseMirrorEditor.innerHTML = '<p><br></p>';
                    
                    // Wait a moment for focus to take effect
                    setTimeout(() => {
                        // Set the content directly
                        proseMirrorEditor.innerHTML = '<p>' + message + '</p>';
                        
                        // Trigger input events
                        proseMirrorEditor.dispatchEvent(new Event('input', { bubbles: true }));
                        proseMirrorEditor.dispatchEvent(new Event('change', { bubbles: true }));
                        
                        // Wait a moment, then simulate Enter key
                        setTimeout(() => {
                            // Create and dispatch Enter key events
                            const enterKeyDown = new KeyboardEvent('keydown', {
                                key: 'Enter',
                                code: 'Enter',
                                keyCode: 13,
                                which: 13,
                                bubbles: true,
                                cancelable: true
                            });
                            
                            const enterKeyUp = new KeyboardEvent('keyup', {
                                key: 'Enter',
                                code: 'Enter',
                                keyCode: 13,
                                which: 13,
                                bubbles: true
                            });
                            
                            proseMirrorEditor.dispatchEvent(enterKeyDown);
                            proseMirrorEditor.dispatchEvent(enterKeyUp);
                            
                            console.log('✅ Enter key events dispatched');
                            
                            // Clear the editor after a delay
                            setTimeout(() => {
                                proseMirrorEditor.innerHTML = '<p><br></p>';
                            }, 1000);
                            
                        }, 300);
                        
                    }, 100);
                    
                    return true;
                    
                } catch (error) {
                    console.error('❌ Error with ProseMirror approach:', error);
                }
            }
            
            // Strategy 2: Try to find and use regular textarea
            const textareas = document.querySelectorAll('textarea');
            for (const textarea of textareas) {
                if (textarea.offsetParent !== null && !textarea.disabled) {
                    console.log('✅ Found visible textarea, trying direct approach');
                    
                    try {
                        textarea.focus();
                        textarea.value = message;
                        
                        // Trigger events
                        textarea.dispatchEvent(new Event('input', { bubbles: true }));
                        textarea.dispatchEvent(new Event('change', { bubbles: true }));
                        
                        // Try to find and click send button
                        const sendButton = document.querySelector('button[data-testid*="send"], button[aria-label*="Send"], button[type="submit"]');
                        if (sendButton && sendButton.offsetParent !== null) {
                            setTimeout(() => {
                                sendButton.click();
                                console.log('✅ Send button clicked');
                            }, 200);
                            return true;
                        }
                        
                        // If no send button, try Enter key
                        setTimeout(() => {
                            const enterEvent = new KeyboardEvent('keydown', {
                                key: 'Enter',
                                code: 'Enter',
                                keyCode: 13,
                                bubbles: true
                            });
                            textarea.dispatchEvent(enterEvent);
                        }, 200);
                        
                        return true;
                        
                    } catch (error) {
                        console.error('❌ Error with textarea approach:', error);
                    }
                }
            }
            
            // Strategy 3: Try contenteditable elements
            const editableElements = document.querySelectorAll('[contenteditable="true"]');
            for (const element of editableElements) {
                if (element.offsetParent !== null) {
                    console.log('✅ Found contenteditable element');
                    
                    try {
                        element.focus();
                        element.textContent = message;
                        
                        // Trigger events
                        element.dispatchEvent(new Event('input', { bubbles: true }));
                        
                        // Try Enter key
                        setTimeout(() => {
                            const enterEvent = new KeyboardEvent('keydown', {
                                key: 'Enter',
                                code: 'Enter',
                                keyCode: 13,
                                bubbles: true
                            });
                            element.dispatchEvent(enterEvent);
                        }, 200);
                        
                        return true;
                        
                    } catch (error) {
                        console.error('❌ Error with contenteditable approach:', error);
                    }
                }
            }
            
            console.error('❌ Could not find suitable input method');
            return false;
        }
        
        // Function to get ChatGPT response
        function getChatGPTResponse() {
            const messageSelectors = [
                '[data-message-author-role="assistant"]',
                '.markdown',
                '[data-testid="conversation-turn-3"]',
                '.prose'
            ];
            
            for (const selector of messageSelectors) {
                try {
                    const messages = document.querySelectorAll(selector);
                    if (messages.length > 0) {
                        const lastMessage = messages[messages.length - 1];
                        return lastMessage.textContent || lastMessage.innerText || '';
                    }
                } catch (e) {
                    console.log('Response selector failed:', selector);
                }
            }
            return '';
        }
        
        // Monitor for DOM changes to detect when ChatGPT loads
        const observer = new MutationObserver((mutations) => {
            if (!window.chatGPTReady) {
                waitForChatGPT();
            }
        });
        
        // Start observing
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
        
        // Check immediately and then periodically
        setTimeout(() => {
            if (waitForChatGPT()) {
                window.chatGPTReady = true;
            }
        }, 1000);
        
        const checkInterval = setInterval(() => {
            if (!window.chatGPTReady && waitForChatGPT()) {
                window.chatGPTReady = true;
                clearInterval(checkInterval);
            }
        }, 2000);
        
        // Expose functions globally
        window.sendToChatGPT = sendToChatGPT;
        window.getChatGPTResponse = getChatGPTResponse;
        window.findChatGPTElements = findChatGPTElements;
        window.inspectChatGPTDOM = inspectChatGPTDOM;
        
        // Add drag and drop functionality for images
        window.setupImageDragDrop = function() {
            const dropZone = document.body;
            
            dropZone.addEventListener('dragover', function(e) {
                e.preventDefault();
                e.stopPropagation();
                console.log('🖱️ Drag over detected');
            });
            
            dropZone.addEventListener('drop', function(e) {
                e.preventDefault();
                e.stopPropagation();
                console.log('📎 Drop detected');
                
                const files = e.dataTransfer.files;
                if (files.length > 0) {
                    console.log('📁 Files dropped:', files.length);
                    
                    // Handle image files
                    for (let i = 0; i < files.length; i++) {
                        const file = files[i];
                        if (file.type.startsWith('image/')) {
                            console.log('🖼️ Image file detected:', file.name);
                            
                            // Try to find ChatGPT's file input or attachment button
                            const fileInputs = document.querySelectorAll('input[type="file"]');
                            const attachButtons = document.querySelectorAll('button[aria-label*="Attach"], button[data-testid*="attach"]');
                            
                            if (fileInputs.length > 0) {
                                // Use the file input directly
                                const fileInput = fileInputs[0];
                                const dataTransfer = new DataTransfer();
                                dataTransfer.items.add(file);
                                fileInput.files = dataTransfer.files;
                                
                                // Trigger change event
                                fileInput.dispatchEvent(new Event('change', { bubbles: true }));
                                console.log('✅ File added to input');
                            } else if (attachButtons.length > 0) {
                                // Click the attach button first
                                attachButtons[0].click();
                                console.log('📎 Attach button clicked');
                            }
                        }
                    }
                }
            });
            
            console.log('🎯 Image drag-drop setup complete');
        };
        
        // Setup drag-drop when page loads
        setTimeout(() => {
            window.setupImageDragDrop();
        }, 2000);
        
        // Audio ducking functions for YouTube
        window.duckAudio = function(volume = 0.1) {
            // Find YouTube video elements
            const videos = document.querySelectorAll('video');
            videos.forEach(video => {
                if (video.volume !== undefined) {
                    video.dataset.originalVolume = video.volume;
                    video.volume = volume;
                }
            });
            
            // Find YouTube player API
            if (window.ytplayer && window.ytplayer.setVolume) {
                window.ytplayer.dataset.originalVolume = window.ytplayer.getVolume();
                window.ytplayer.setVolume(volume * 100);
            }
            
            console.log('🔇 Audio ducked for speech recognition');
        };
        
        window.restoreAudio = function() {
            // Restore YouTube video elements
            const videos = document.querySelectorAll('video');
            videos.forEach(video => {
                if (video.dataset.originalVolume !== undefined) {
                    video.volume = parseFloat(video.dataset.originalVolume);
                    delete video.dataset.originalVolume;
                }
            });
            
            // Restore YouTube player API
            if (window.ytplayer && window.ytplayer.setVolume && window.ytplayer.dataset.originalVolume) {
                window.ytplayer.setVolume(parseFloat(window.ytplayer.dataset.originalVolume));
                delete window.ytplayer.dataset.originalVolume;
            }
            
            console.log('🔊 Audio restored after speech recognition');
        };
        """
        
        let userScript = WKUserScript(source: chatGPTScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(userScript)
        
        config.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator // Add UI delegate for popups
        
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
    @Published var isChatGPTReady = false
    
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
    
    func sendMessageToChatGPT(_ message: String) {
        let escapedMessage = message.replacingOccurrences(of: "'", with: "\\'")
                                   .replacingOccurrences(of: "\n", with: "\\n")
                                   .replacingOccurrences(of: "\r", with: "\\r")
        
        let script = "sendToChatGPT('\(escapedMessage)');"
        
        print("📤 Sending message to ChatGPT: \(message)")
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Error sending message to ChatGPT: \(error)")
                // If sending fails, inspect the DOM to understand the structure
                self.inspectDOM()
            } else if let success = result as? Bool, success {
                print("✅ Message sent successfully to ChatGPT")
            } else {
                print("⚠️ Message send result unclear: \(String(describing: result))")
                // Inspect DOM to understand what's available
                self.inspectDOM()
            }
        }
    }
    
    func inspectDOM() {
        let script = "inspectChatGPTDOM();"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Error inspecting DOM: \(error)")
            } else if let domReport = result {
                print("🔍 DOM Inspection Result:")
                print(domReport)
            }
        }
    }
    
    private func debugChatGPTElements() {
        let debugScript = """
        const elements = findChatGPTElements();
        console.log('🔍 Debug - Input found:', !!elements.input);
        console.log('🔍 Debug - Send button found:', !!elements.sendButton);
        if (elements.input) {
            console.log('🔍 Debug - Input tag:', elements.input.tagName);
            console.log('🔍 Debug - Input type:', elements.input.type);
        }
        return {
            inputFound: !!elements.input,
            sendButtonFound: !!elements.sendButton,
            inputTag: elements.input ? elements.input.tagName : null
        };
        """
        
        webView?.evaluateJavaScript(debugScript) { result, error in
            if let result = result {
                print("🔍 ChatGPT Debug Result: \(result)")
            }
        }
    }
    
    func getChatGPTResponse(completion: @escaping (String) -> Void) {
        let script = "getChatGPTResponse();"
        webView?.evaluateJavaScript(script) { result, error in
            if let response = result as? String {
                completion(response)
            } else {
                completion("")
            }
        }
    }
    
    func clearAllData() {
        // Clear all website data (cookies, local storage, etc.)
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        dataStore.removeData(ofTypes: dataTypes, modifiedSince: Date(timeIntervalSince1970: 0)) {
            print("🧹 All website data cleared")
        }
    }
    
    func checkLoginStatus() {
        // Check if user is logged in to ChatGPT
        let script = """
        // Check for login indicators
        const loginIndicators = [
            'button[aria-label*="User"]',
            '[data-testid="profile-button"]',
            '.user-avatar',
            '[aria-label*="Account"]'
        ];
        
        let isLoggedIn = false;
        for (const selector of loginIndicators) {
            if (document.querySelector(selector)) {
                isLoggedIn = true;
                break;
            }
        }
        
        return {
            loggedIn: isLoggedIn,
            url: window.location.href
        };
        """
        
        webView?.evaluateJavaScript(script) { result, error in
            if let result = result as? [String: Any] {
                let isLoggedIn = result["loggedIn"] as? Bool ?? false
                let currentURL = result["url"] as? String ?? ""
                
                print("🔐 Login Status - Logged in: \(isLoggedIn), URL: \(currentURL)")
            }
        }
    }
    
    func debugCurrentPage() {
        // Debug function to inspect current page elements
        let debugScript = """
        console.log('🔍 === DEBUGGING CURRENT PAGE ===');
        console.log('URL:', window.location.href);
        console.log('Title:', document.title);
        
        // Check for ChatGPT specific elements
        const promptTextarea = document.getElementById('prompt-textarea');
        console.log('prompt-textarea found:', !!promptTextarea);
        if (promptTextarea) {
            console.log('prompt-textarea visible:', promptTextarea.offsetParent !== null);
            console.log('prompt-textarea innerHTML:', promptTextarea.innerHTML.substring(0, 100));
        }
        
        // Check all textareas
        const allTextareas = document.querySelectorAll('textarea');
        console.log('Total textareas found:', allTextareas.length);
        allTextareas.forEach((ta, i) => {
            console.log(`Textarea ${i}:`, {
                id: ta.id,
                name: ta.name,
                placeholder: ta.placeholder,
                visible: ta.offsetParent !== null,
                value: ta.value.substring(0, 50)
            });
        });
        
        // Check for send buttons
        const sendButtons = document.querySelectorAll('button[data-testid*="send"], button[aria-label*="Send"], button[type="submit"]');
        console.log('Send buttons found:', sendButtons.length);
        sendButtons.forEach((btn, i) => {
            console.log(`Send button ${i}:`, {
                testId: btn.getAttribute('data-testid'),
                ariaLabel: btn.getAttribute('aria-label'),
                type: btn.type,
                visible: btn.offsetParent !== null,
                text: btn.textContent?.substring(0, 30)
            });
        });
        
        return {
            url: window.location.href,
            title: document.title,
            promptTextareaFound: !!promptTextarea,
            textareasCount: allTextareas.length,
            sendButtonsCount: sendButtons.length
        };
        """
        
        webView?.evaluateJavaScript(debugScript) { result, error in
            if let error = error {
                print("❌ Debug script error: \(error)")
            } else if let debugInfo = result as? [String: Any] {
                print("🔍 Debug Info: \(debugInfo)")
            }
        }
    }
    
    func duckAudio() {
        let script = "if (typeof duckAudio === 'function') { duckAudio(0.1); }"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Error ducking audio: \(error)")
            } else {
                print("🔇 Audio ducked successfully")
            }
        }
    }
    
    func sendImageToChatGPT(_ image: NSImage) {
        // Convert NSImage to base64
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            print("❌ Failed to convert image to PNG data")
            return
        }
        
        let base64String = pngData.base64EncodedString()
        
        // JavaScript to handle image upload to ChatGPT
        let script = """
        (function() {
            const base64Data = '\(base64String)';
            
            // Convert base64 to blob
            const byteCharacters = atob(base64Data);
            const byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            const byteArray = new Uint8Array(byteNumbers);
            const blob = new Blob([byteArray], {type: 'image/png'});
            
            // Create a file from the blob
            const file = new File([blob], 'screenshot.png', {type: 'image/png'});
            
            // Try to find file input
            const fileInputs = document.querySelectorAll('input[type="file"]');
            if (fileInputs.length > 0) {
                const fileInput = fileInputs[0];
                const dataTransfer = new DataTransfer();
                dataTransfer.items.add(file);
                fileInput.files = dataTransfer.files;
                
                // Trigger change event
                fileInput.dispatchEvent(new Event('change', { bubbles: true }));
                console.log('✅ Screenshot uploaded to ChatGPT');
                return true;
            }
            
            // Try to find attach button and click it
            const attachButtons = document.querySelectorAll('button[aria-label*="Attach"], button[data-testid*="attach"], button[title*="Attach"]');
            if (attachButtons.length > 0) {
                attachButtons[0].click();
                console.log('📎 Attach button clicked, waiting for file input...');
                
                // Wait for file input to appear
                setTimeout(() => {
                    const newFileInputs = document.querySelectorAll('input[type="file"]');
                    if (newFileInputs.length > 0) {
                        const fileInput = newFileInputs[newFileInputs.length - 1]; // Use the newest one
                        const dataTransfer = new DataTransfer();
                        dataTransfer.items.add(file);
                        fileInput.files = dataTransfer.files;
                        
                        fileInput.dispatchEvent(new Event('change', { bubbles: true }));
                        console.log('✅ Screenshot uploaded after clicking attach');
                        return true;
                    }
                }, 500);
            }
            
            console.log('❌ Could not find way to upload image');
            return false;
        })();
        """
        
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Error uploading image: \(error)")
            } else if let success = result as? Bool, success {
                print("✅ Image uploaded successfully")
            } else {
                print("⚠️ Image upload result unclear")
            }
        }
    }
    
    func restoreAudio() {
        let script = "if (typeof restoreAudio === 'function') { restoreAudio(); }"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Error restoring audio: \(error)")
            } else {
                print("🔊 Audio restored successfully")
            }
        }
    }
}

extension WebViewWrapper {
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewWrapper
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }
        
        // MARK: - WKUIDelegate (for OAuth popups)
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Handle OAuth popup windows by loading in the same webview
            if let url = navigationAction.request.url {
                print("🔗 Opening popup URL in same webview: \(url)")
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            // Handle JavaScript alerts
            let alert = NSAlert()
            alert.messageText = "Website Alert"
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.runModal()
            completionHandler()
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            // Handle JavaScript confirms
            let alert = NSAlert()
            alert.messageText = "Website Confirmation"
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            completionHandler(response == .alertFirstButtonReturn)
        }
        
        // MARK: - WKScriptMessageHandler
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow all navigation for OAuth flows
            if let url = navigationAction.request.url {
                print("🔗 Navigation to: \(url)")
                
                // Handle special OAuth URLs
                if url.absoluteString.contains("accounts.google.com") ||
                   url.absoluteString.contains("oauth") ||
                   url.absoluteString.contains("auth") ||
                   url.absoluteString.contains("login") {
                    print("🔐 OAuth/Login flow detected, allowing navigation")
                }
                
                // Handle ChatGPT OAuth callback
                if url.absoluteString.contains("chatgpt.com") && 
                   url.absoluteString.contains("auth") {
                    print("🎯 ChatGPT OAuth callback detected")
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            // Allow all responses
            decisionHandler(.allow)
        }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "chatGPTBridge" {
                if let body = message.body as? [String: Any],
                   let type = body["type"] as? String {
                    
                    switch type {
                    case "ready":
                        let inputFound = body["inputFound"] as? Bool ?? false
                        let sendButtonFound = body["sendButtonFound"] as? Bool ?? false
                        
                        print("🎉 ChatGPT is ready! Input: \(inputFound), Send Button: \(sendButtonFound)")
                        
                        DispatchQueue.main.async {
                            self.parent.webViewStore?.isChatGPTReady = true
                            self.parent.onChatGPTReady?()
                        }
                    default:
                        print("📨 Received message from ChatGPT: \(body)")
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🔵 Navigation started")
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.webViewStore?.isChatGPTReady = false
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Navigation finished: \(webView.url?.absoluteString ?? "unknown")")
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }
            
            // Check login status after navigation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.parent.webViewStore?.checkLoginStatus()
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
