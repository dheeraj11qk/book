# Design Document: Embedded Browser

## Overview

This design implements an embedded web browser within the ChatView of the macOS SwiftUI application. The solution adds a browser button to the top bar that toggles between the chat interface and an embedded browser view. The implementation uses WKWebView wrapped in SwiftUI for full web rendering capabilities while maintaining the existing chat functionality.

The design follows a view-switching pattern where the browser view replaces the chat messages area when active, with smooth transitions and proper state management.

## Architecture

### Component Structure

```
ChatView (Modified)
├── Top Bar (HStack)
│   ├── Settings Button (Existing)
│   ├── Browser Button (New)
│   ├── Auto Type Overlay (Existing)
│   └── Reset Button (Existing)
├── Content Area (Conditional)
│   ├── Chat Messages ScrollView (Existing, shown when browser closed)
│   └── BrowserView (New, shown when browser open)
└── Input Bar (Existing, hidden when browser open)
```

### New Components

1. **BrowserView**: Main browser interface component
   - URL input field with navigation controls
   - WebViewWrapper for content display
   - Close button to return to chat
   - Loading indicator

2. **WebViewWrapper**: SwiftUI wrapper for WKWebView
   - Implements UIViewRepresentable (via NSViewRepresentable on macOS)
   - Manages WKWebView lifecycle
   - Handles navigation delegate callbacks
   - Exposes loading state and navigation controls

3. **BrowserViewModel**: State management for browser
   - Current URL state
   - Loading state
   - Navigation history
   - Error handling

## Components and Interfaces

### ChatView Modifications

**New State Variables:**
```swift
@State private var showingBrowser = false
```

**Modified Body Structure:**
```swift
VStack(spacing: 0) {
    // Top bar with new browser button
    HStack {
        settingsButton
        browserButton  // NEW
        Spacer()
        autoTypeOverlay
        Spacer()
        resetButton
    }
    
    // Conditional content area
    if showingBrowser {
        BrowserView(isPresented: $showingBrowser)
    } else {
        chatMessagesScrollView
        Divider()
        inputBar
    }
}
```

### BrowserView Component

**Interface:**
```swift
struct BrowserView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = BrowserViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack {
                backButton
                forwardButton
                reloadButton
                urlTextField
                closeButton
            }
            
            // Web content
            WebViewWrapper(
                url: $viewModel.currentURL,
                isLoading: $viewModel.isLoading,
                canGoBack: $viewModel.canGoBack,
                canGoForward: $viewModel.canGoForward
            )
            
            // Loading indicator overlay
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

### WebViewWrapper Component

**Interface:**
```swift
struct WebViewWrapper: NSViewRepresentable {
    @Binding var url: URL?
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    func makeNSView(context: Context) -> WKWebView
    func updateNSView(_ nsView: WKWebView, context: Context)
    func makeCoordinator() -> Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)
    }
}
```

### BrowserViewModel

**Interface:**
```swift
class BrowserViewModel: ObservableObject {
    @Published var currentURL: URL?
    @Published var urlText: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var errorMessage: String?
    
    func loadURL(_ urlString: String)
    func goBack()
    func goForward()
    func reload()
    func updateNavigationState(canGoBack: Bool, canGoForward: Bool)
}
```

## Data Models

### Browser State

```swift
struct BrowserState {
    var isVisible: Bool = false
    var currentURL: URL?
    var navigationHistory: [URL] = []
    var isLoading: Bool = false
}
```

No persistent storage is required for this feature. All state is ephemeral and managed in memory during the session.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: View Toggle Behavior

*For any* ChatView state, clicking the browser button should toggle between displaying the chat view and the browser view, with only one visible at a time.

**Validates: Requirements 2.1, 4.2**

### Property 2: View Exclusivity Invariant

*For any* ChatView state, exactly one of the following should be visible: (chat messages + input bar) OR (browser view), never both simultaneously, and the top bar should always remain visible.

**Validates: Requirements 2.3, 2.4, 6.3, 6.4**

### Property 3: State Preservation Round-Trip

*For any* chat state (messages, scroll position, input text), opening the browser and then closing it should restore the exact same chat state without loss of data or position.

**Validates: Requirements 4.3, 4.4**

### Property 4: Top Bar Functionality Preservation

*For any* state where the browser is displayed, clicking the settings button or reset button should trigger their respective actions (showing settings sheet or clearing chat).

**Validates: Requirements 2.5**

### Property 5: URL Loading Trigger

*For any* valid URL string entered in the browser's URL field, submitting the URL should trigger the WebView to begin loading that URL.

**Validates: Requirements 3.2**

### Property 6: Loading Indicator Visibility

*For any* page load operation in the WebView, a loading indicator should be visible from the start of the load until the page finishes loading or fails.

**Validates: Requirements 3.4**

### Property 7: Error Message Display

*For any* navigation error (invalid URL, network failure, timeout), the browser view should display an error message describing the failure.

**Validates: Requirements 3.5**

### Property 8: Navigation Controls Functionality

*For any* WebView state, activating the back button should call WKWebView.goBack(), forward button should call goForward(), and reload button should call reload().

**Validates: Requirements 5.4**

### Property 9: Input Bar Restoration

*For any* state where the browser is closed, the input bar should become visible and functional in the chat view.

**Validates: Requirements 6.5**

### Property 10: Keyboard Shortcut Support

*For any* standard macOS navigation keyboard shortcut (Cmd+[, Cmd+], Cmd+R), the WebView should respond with the corresponding navigation action (back, forward, reload).

**Validates: Requirements 7.1**

### Property 11: Appearance Mode Adaptation

*For any* macOS appearance mode change (light to dark or dark to light), the browser view should update its styling to match the new appearance mode.

**Validates: Requirements 7.2**

## Error Handling

### URL Validation

- Invalid URL formats should be caught before attempting to load
- Display user-friendly error messages for common issues:
  - Missing protocol (auto-prepend "https://")
  - Malformed URLs (show "Invalid URL format")
  - Empty URL field (disable load button)

### Network Errors

- Handle WKWebView navigation errors through the WKNavigationDelegate
- Display appropriate messages for:
  - Network unreachable
  - DNS resolution failures
  - SSL certificate errors
  - Timeout errors
- Provide retry option for failed loads

### Memory Management

- Properly deallocate WKWebView when browser is closed
- Clear web cache if memory warnings occur
- Implement proper coordinator cleanup in WebViewWrapper

### State Consistency

- Ensure browser state is reset when closed
- Handle rapid toggling of browser button gracefully
- Prevent multiple simultaneous navigation requests

## Testing Strategy

This feature will use a dual testing approach combining unit tests for specific scenarios and property-based tests for universal behaviors.

### Unit Testing

Unit tests will focus on:
- Specific UI component presence (browser button exists, close button exists, URL field exists)
- Example state transitions (opening browser from empty chat, closing browser with loaded page)
- Edge cases (empty URL submission, rapid button clicking, invalid URL formats)
- Integration points (browser button action triggers state change, close button dismisses view)
- Error conditions (network failures, invalid URLs, timeout scenarios)

### Property-Based Testing

Property-based tests will verify universal properties across all inputs using the fast-check library for Swift (or similar PBT framework). Each test will run a minimum of 100 iterations with randomized inputs.

**Test Configuration:**
- Minimum 100 iterations per property test
- Random generation of: chat states, URLs, user actions, appearance modes
- Each test tagged with: **Feature: embedded-browser, Property N: [property text]**

**Properties to Test:**
1. View toggle behavior (Property 1)
2. View exclusivity invariant (Property 2)
3. State preservation round-trip (Property 3)
4. Top bar functionality preservation (Property 4)
5. URL loading trigger (Property 5)
6. Loading indicator visibility (Property 6)
7. Error message display (Property 7)
8. Navigation controls functionality (Property 8)
9. Input bar restoration (Property 9)
10. Keyboard shortcut support (Property 10)
11. Appearance mode adaptation (Property 11)

**Example Property Test Structure:**
```swift
// Feature: embedded-browser, Property 2: View Exclusivity Invariant
func testViewExclusivityInvariant() {
    // Generate 100+ random chat states
    // For each state:
    //   - Verify exactly one of (chat+input) or (browser) is visible
    //   - Verify top bar is always visible
    //   - Assert mutual exclusivity holds
}
```

### Testing Balance

- Property tests handle comprehensive input coverage through randomization
- Unit tests focus on specific examples, edge cases, and integration points
- Together they provide complete coverage: unit tests catch concrete bugs, property tests verify general correctness
- Avoid writing too many unit tests for scenarios already covered by properties
