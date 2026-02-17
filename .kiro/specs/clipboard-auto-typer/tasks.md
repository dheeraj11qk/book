# Implementation Plan: Clipboard Auto-Typer

## Overview

This implementation plan breaks down the Clipboard Auto-Typer feature into discrete coding tasks. The feature will be built as a standalone macOS application using SwiftUI, with services for clipboard monitoring and keyboard event simulation. Tasks are ordered to build incrementally, with testing integrated throughout.

## Tasks

- [x] 1. Set up project structure and core models
  - Create new SwiftUI macOS app target or add to existing project
  - Define SpeedMode enum with delay ranges
  - Define UIState enum with associated values
  - Add Info.plist entry for NSAppleEventsUsageDescription (Accessibility permission)
  - _Requirements: 6.2, 6.3, 6.4, 6.5, 6.6, 7.3_

- [ ] 2. Implement ClipboardMonitor service
  - [x] 2.1 Create ClipboardMonitor class with NSPasteboard integration
    - Implement ObservableObject with @Published currentText property
    - Implement startMonitoring() with Timer that fires every 500ms
    - Implement checkClipboard() to read NSPasteboard.general
    - Track changeCount to detect clipboard changes
    - Publish text content when changes detected
    - Filter out non-text clipboard content
    - Implement stopMonitoring() to invalidate timer
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 7.3_

  - [ ]* 2.2 Write property test for clipboard change detection
    - **Property 1: Clipboard Change Detection**
    - **Validates: Requirements 1.1, 1.2, 1.4**

  - [ ]* 2.3 Write property test for non-text filtering
    - **Property 2: Non-Text Clipboard Filtering**
    - **Validates: Requirements 1.3**

- [ ] 3. Implement TypingSimulator service
  - [x] 3.1 Create TypingSimulator class with CGEvent integration
    - Implement typeText() method that accepts text and callbacks
    - Implement character-to-CGEvent conversion using CGEvent.keyCode mapping
    - Implement getDelay(for:) that returns random delay within SpeedMode range
    - Implement selectRandomSpeedMode() with weighted probability (Normal 50%, Slow 20%, Little Fast 20%, Thinking 10%)
    - Use DispatchQueue.global() for async typing with delays
    - Implement stop() method that sets shouldStop flag
    - Check shouldStop flag between each character
    - Call onSpeedChange callback when speed mode changes
    - Call completion callback when typing finishes
    - _Requirements: 4.2, 4.3, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 7.4_

  - [ ]* 3.2 Write property test for delay range compliance
    - **Property 7: Delay Range Compliance**
    - **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5, 6.6**

  - [ ]* 3.3 Write property test for complete text typing
    - **Property 6: Complete Text Typing**
    - **Validates: Requirements 4.2, 4.4**

  - [ ]* 3.4 Write property test for stop halts typing
    - **Property 5: Stop Halts Typing**
    - **Validates: Requirements 5.3, 5.4, 5.5**

- [ ] 4. Implement AutoTyperViewModel
  - [x] 4.1 Create AutoTyperViewModel class with state management
    - Implement ObservableObject with @Published state property
    - Initialize ClipboardMonitor and TypingSimulator instances
    - Subscribe to ClipboardMonitor.currentText changes
    - Implement startAutoType() that initiates countdown
    - Implement startCountdown() with Timer that counts 3, 2, 1
    - Update state to .countdown(n) on each tick
    - Implement beginTyping() that captures clipboard text and calls TypingSimulator
    - Update state to .typing(mode) when speed mode changes
    - Return to .idle state when typing completes
    - Implement stop() that cancels countdown or stops typing
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 4.1, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5_

  - [ ]* 4.2 Write property test for countdown sequence integrity
    - **Property 3: Countdown Sequence Integrity**
    - **Validates: Requirements 3.3**

  - [ ]* 4.3 Write property test for stop cancels countdown
    - **Property 4: Stop Cancels Countdown**
    - **Validates: Requirements 5.1, 5.2**

  - [ ]* 4.4 Write property test for typing uses captured content
    - **Property 10: Typing Uses Captured Content**
    - **Validates: Requirements 4.5**

  - [ ]* 4.5 Write unit tests for state transitions
    - Test idle → countdown → typing → idle flow
    - Test stop during countdown returns to idle
    - Test stop during typing returns to idle
    - _Requirements: 3.1, 3.2, 3.8, 5.1, 5.2, 5.3, 5.4_

- [x] 5. Checkpoint - Ensure core services work correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement FloatingWindow SwiftUI view
  - [x] 6.1 Create FloatingWindow view with state-based rendering
    - Create SwiftUI View that observes AutoTyperViewModel
    - Implement conditional rendering based on viewModel.state
    - For .idle state: Show "Auto Type |>" button
    - For .countdown(n) state: Show countdown number and Stop button
    - For .typing(mode) state: Show mode.rawValue text and Stop button
    - Wire "Auto Type |>" button to viewModel.startAutoType()
    - Wire Stop button to viewModel.stop()
    - Apply semi-transparent background with blur effect
    - Apply rounded corners and padding
    - Support dark mode with adaptive colors
    - _Requirements: 2.6, 2.7, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

  - [ ]* 6.2 Write unit tests for UI rendering
    - Test correct view rendered for each state
    - Test button actions trigger correct ViewModel methods
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 7. Implement FloatingWindowController
  - [x] 7.1 Create NSWindow configuration and management
    - Create NSWindow with .borderless style mask
    - Set window level to .floating or .statusBar
    - Set collectionBehavior to [.canJoinAllSpaces, .stationary]
    - Set isMovable to false
    - Set backgroundColor to .clear
    - Set isOpaque to false
    - Set hasShadow to true
    - Implement show() method that makes window visible
    - Implement hide() method that hides window
    - Position window at top center of screen in show()
    - Ensure window does not activate (no focus steal)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 7.5, 7.6, 7.7_

  - [ ]* 7.2 Write property test for window always on top
    - **Property 8: Window Always On Top**
    - **Validates: Requirements 2.3**

  - [ ]* 7.3 Write property test for no focus steal
    - **Property 9: No Focus Steal**
    - **Validates: Requirements 2.5, 8.3**

- [ ] 8. Implement accessibility permission handling
  - [x] 8.1 Add permission checking and prompting
    - Check AXIsProcessTrusted() before typing
    - If false, show alert with instructions
    - Add "Open System Preferences" button that opens Security & Privacy pane
    - Disable Start button in UI when permissions not granted
    - Re-check permissions when app becomes active
    - _Requirements: 7.1, 7.2_

  - [ ]* 8.2 Write unit tests for permission handling
    - Test permission check before typing
    - Test UI disabled state when permissions denied
    - _Requirements: 7.1, 7.2_

- [ ] 9. Wire application lifecycle
  - [x] 9.1 Create App entry point and coordinate components
    - Create @main App struct with WindowGroup or custom scene
    - Initialize AutoTyperViewModel
    - Start ClipboardMonitor on app launch
    - Show/hide FloatingWindow based on clipboardText changes
    - Ensure window only appears when clipboard has text
    - Stop ClipboardMonitor on app termination
    - Configure app to not show in Dock (LSUIElement in Info.plist)
    - _Requirements: 1.1, 1.2, 1.3, 8.1, 8.2, 8.3, 8.4, 8.5, 2.4_

  - [ ]* 9.2 Write integration tests for end-to-end flow
    - Test clipboard change → UI appears → start → countdown → type → complete
    - Test stop during countdown
    - Test stop during typing
    - _Requirements: 1.1, 1.2, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 5.1, 5.3_

- [ ] 10. Add error handling and robustness
  - [x] 10.1 Implement error handling for edge cases
    - Add try-catch around NSPasteboard access
    - Log errors for CGEvent creation failures
    - Skip characters that fail to convert to CGEvent
    - Handle timer invalidation gracefully
    - Add fallback window configuration if properties fail to set
    - Display user-friendly error messages for critical failures
    - _Requirements: 7.3, 7.4_

  - [ ]* 10.2 Write unit tests for error scenarios
    - Test clipboard access failure handling
    - Test CGEvent creation failure handling
    - Test timer failure recovery

- [x] 11. Final checkpoint - Complete testing and validation
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties with minimum 100 iterations
- Unit tests validate specific examples and edge cases
- Integration tests verify end-to-end workflows
- The implementation builds incrementally: services → view model → UI → integration
- Accessibility permissions are critical for CGEvent posting to work
