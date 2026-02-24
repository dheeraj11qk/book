# Implementation Plan: Embedded Browser

## Overview

This implementation adds an embedded web browser to the ChatView using WKWebView wrapped in SwiftUI. The approach follows a view-switching pattern where the browser replaces the chat interface when active, with proper state management and smooth transitions.

## Tasks

- [x] 1. Create BrowserViewModel for state management
  - Create new file `book/ViewModels/BrowserViewModel.swift`
  - Implement ObservableObject with published properties for URL, loading state, navigation state
  - Add methods for loadURL, goBack, goForward, reload, updateNavigationState
  - _Requirements: 6.1, 3.2_

- [ ] 2. Implement WebViewWrapper component
  - [x] 2.1 Create WebViewWrapper with NSViewRepresentable
    - Create new file `book/Views/WebViewWrapper.swift`
    - Implement NSViewRepresentable protocol for WKWebView
    - Add bindings for url, isLoading, canGoBack, canGoForward
    - _Requirements: 5.1, 5.2_
  
  - [x] 2.2 Implement Coordinator for WKNavigationDelegate
    - Create Coordinator class conforming to WKNavigationDelegate
    - Implement didStartProvisionalNavigation, didFinish, didFail callbacks
    - Update parent bindings based on navigation events
    - _Requirements: 5.3, 3.5_
  
  - [ ]* 2.3 Write property test for navigation controls
    - **Property 8: Navigation Controls Functionality**
    - **Validates: Requirements 5.4**
  
  - [ ]* 2.4 Write unit tests for WebViewWrapper
    - Test WKWebView initialization
    - Test coordinator delegate callbacks
    - Test error handling for failed navigation
    - _Requirements: 5.1, 3.5_

- [ ] 3. Create BrowserView component
  - [x] 3.1 Implement BrowserView with navigation bar
    - Create new file `book/Views/BrowserView.swift`
    - Add HStack with back, forward, reload buttons
    - Add TextField for URL input
    - Add close button
    - _Requirements: 3.1, 4.1, 5.4_
  
  - [x] 3.2 Integrate WebViewWrapper into BrowserView
    - Add WebViewWrapper to view body
    - Connect viewModel bindings to WebViewWrapper
    - Add loading indicator overlay
    - _Requirements: 3.2, 3.4_
  
  - [x] 3.3 Implement URL input handling
    - Add TextField with onSubmit action
    - Validate and format URL input (auto-prepend https://)
    - Call viewModel.loadURL on submission
    - _Requirements: 3.1, 3.2_
  
  - [ ]* 3.4 Write property test for URL loading
    - **Property 5: URL Loading Trigger**
    - **Validates: Requirements 3.2**
  
  - [ ]* 3.5 Write property test for loading indicator
    - **Property 6: Loading Indicator Visibility**
    - **Validates: Requirements 3.4**
  
  - [ ]* 3.6 Write unit tests for BrowserView
    - Test URL field presence
    - Test close button presence
    - Test navigation button states
    - _Requirements: 3.1, 4.1_

- [ ] 4. Checkpoint - Ensure browser components work independently
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Modify ChatView to integrate browser
  - [x] 5.1 Add browser state and button to ChatView
    - Add `@State private var showingBrowser = false` to ChatView
    - Add browser button to top bar HStack between settings and reset
    - Use SF Symbol "safari" or "globe" with consistent styling
    - _Requirements: 1.1, 1.2, 1.3, 6.1_
  
  - [x] 5.2 Implement conditional view switching
    - Wrap chat messages ScrollView and input bar in conditional
    - Add BrowserView in else branch with isPresented binding
    - Ensure top bar remains visible in both states
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [x] 5.3 Add browser toggle action
    - Connect browser button action to toggle showingBrowser
    - Add smooth animation for view transitions
    - _Requirements: 2.1, 6.2_
  
  - [ ]* 5.4 Write property test for view toggle behavior
    - **Property 1: View Toggle Behavior**
    - **Validates: Requirements 2.1, 4.2**
  
  - [ ]* 5.5 Write property test for view exclusivity
    - **Property 2: View Exclusivity Invariant**
    - **Validates: Requirements 2.3, 2.4, 6.3, 6.4**
  
  - [ ]* 5.6 Write unit tests for ChatView integration
    - Test browser button presence and positioning
    - Test browser button styling matches other buttons
    - Test view switching on button click
    - _Requirements: 1.1, 1.2, 1.3, 2.1_

- [ ] 6. Implement state preservation
  - [x] 6.1 Ensure chat state persists when browser opens
    - Verify messages array is not cleared when showingBrowser toggles
    - Verify scroll position is maintained (ScrollViewReader proxy)
    - Verify input text is preserved
    - _Requirements: 4.4_
  
  - [ ]* 6.2 Write property test for state preservation
    - **Property 3: State Preservation Round-Trip**
    - **Validates: Requirements 4.3, 4.4**
  
  - [ ]* 6.3 Write unit tests for state preservation
    - Test messages persist after browser toggle
    - Test input text persists after browser toggle
    - _Requirements: 4.4_

- [ ] 7. Implement error handling
  - [ ] 7.1 Add error display to BrowserView
    - Add @Published errorMessage to BrowserViewModel
    - Display error alert or banner when errorMessage is set
    - Handle common error cases (invalid URL, network failure, timeout)
    - _Requirements: 3.5_
  
  - [ ] 7.2 Add URL validation
    - Validate URL format before loading
    - Auto-prepend "https://" if protocol missing
    - Show error for malformed URLs
    - _Requirements: 3.2, 3.5_
  
  - [ ]* 7.3 Write property test for error display
    - **Property 7: Error Message Display**
    - **Validates: Requirements 3.5**
  
  - [ ]* 7.4 Write unit tests for error handling
    - Test invalid URL format handling
    - Test network error display
    - Test empty URL submission
    - _Requirements: 3.5_

- [ ] 8. Add macOS-specific features
  - [ ] 8.1 Implement keyboard shortcuts
    - Add .onKeyPress or key event handling to WebViewWrapper
    - Map Cmd+[ to goBack, Cmd+] to goForward, Cmd+R to reload
    - _Requirements: 7.1_
  
  - [ ] 8.2 Ensure appearance mode support
    - Verify BrowserView respects @Environment(\.colorScheme)
    - Test browser styling in light and dark modes
    - _Requirements: 7.2_
  
  - [ ]* 8.3 Write property test for keyboard shortcuts
    - **Property 10: Keyboard Shortcut Support**
    - **Validates: Requirements 7.1**
  
  - [ ]* 8.4 Write property test for appearance adaptation
    - **Property 11: Appearance Mode Adaptation**
    - **Validates: Requirements 7.2**

- [ ] 9. Verify top bar functionality preservation
  - [ ]* 9.1 Write property test for top bar functionality
    - **Property 4: Top Bar Functionality Preservation**
    - **Validates: Requirements 2.5**
  
  - [ ]* 9.2 Write unit tests for top bar buttons
    - Test settings button works when browser is open
    - Test reset button works when browser is open
    - _Requirements: 2.5_

- [ ] 10. Verify input bar restoration
  - [ ]* 10.1 Write property test for input bar restoration
    - **Property 9: Input Bar Restoration**
    - **Validates: Requirements 6.5**
  
  - [ ]* 10.2 Write unit tests for input bar visibility
    - Test input bar hidden when browser open
    - Test input bar visible when browser closed
    - _Requirements: 6.4, 6.5_

- [ ] 11. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties with 100+ iterations
- Unit tests validate specific examples and edge cases
- The implementation uses Swift and SwiftUI for macOS
- WKWebView is the underlying web rendering engine
