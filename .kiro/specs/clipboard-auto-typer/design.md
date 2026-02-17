# Design Document: Clipboard Auto-Typer

## Overview

The Clipboard Auto-Typer is a macOS utility built with SwiftUI that provides a floating overlay interface for automatically typing clipboard content with human-like behavior. The system consists of three main components: a clipboard monitoring service, a typing simulation engine, and a floating UI controller. The application uses NSPasteboard for clipboard access and CGEvent for keyboard simulation.

## Architecture

The application follows a Model-View-ViewModel (MVVM) architecture with service layer components:

```
┌─────────────────────────────────────────────────────────┐
│                     FloatingWindow                       │
│                    (SwiftUI View)                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  AutoTyperViewModel                      │
│  - UI State Management                                   │
│  - Countdown Logic                                       │
│  - Coordination                                          │
└──────────┬──────────────────────────────┬───────────────┘
           │                               │
           ▼                               ▼
┌──────────────────────┐      ┌──────────────────────────┐
│  ClipboardMonitor    │      │   TypingSimulator        │
│  - Poll NSPasteboard │      │   - CGEvent Generation   │
│  - Detect Changes    │      │   - Speed Variation      │
│  - Notify ViewModel  │      │   - Human-like Delays    │
└──────────────────────┘      └──────────────────────────┘
```

The architecture ensures separation of concerns:
- UI layer handles presentation and user interaction
- ViewModel manages state and coordinates services
- Services handle platform-specific operations (clipboard, keyboard events)

## Components and Interfaces

### ClipboardMonitor

Monitors the system clipboard for text content changes.

```swift
class ClipboardMonitor: ObservableObject {
    @Published var currentText: String?
    private var changeCount: Int
    private var timer: Timer?
    
    func startMonitoring()
    func stopMonitoring()
    private func checkClipboard()
}
```

**Responsibilities:**
- Poll NSPasteboard every 500ms
- Detect when clipboard content changes
- Publish text content to observers
- Manage polling lifecycle

**Key Operations:**
- `startMonitoring()`: Begins timer-based polling
- `stopMonitoring()`: Cancels timer and cleanup
- `checkClipboard()`: Reads NSPasteboard.general.changeCount and compares with stored value

### TypingSimulator

Generates keyboard events with human-like timing variations.

```swift
class TypingSimulator {
    enum SpeedMode {
        case slow       // 150-300ms
        case normal     // 80-150ms
        case littleFast // 40-80ms
        case thinking   // 500-1500ms pause
    }
    
    private var isTyping: Bool
    private var shouldStop: Bool
    
    func typeText(_ text: String, onSpeedChange: (SpeedMode) -> Void, completion: () -> Void)
    func stop()
    private func getDelay(for mode: SpeedMode) -> TimeInterval
    private func selectRandomSpeedMode() -> SpeedMode
    private func postKeyEvent(for character: Character)
}
```

**Responsibilities:**
- Convert characters to CGEvent keyboard events
- Apply random delays between characters
- Vary typing speed dynamically
- Handle stop requests immediately

**Key Operations:**
- `typeText()`: Asynchronously types each character with delays
- `stop()`: Sets flag to halt typing immediately
- `getDelay()`: Returns random delay within speed mode range
- `selectRandomSpeedMode()`: Randomly chooses speed mode with weighted probability
- `postKeyEvent()`: Creates and posts CGEvent for a character

**Speed Mode Distribution:**
- Normal: 50% probability
- Slow: 20% probability
- Little Fast: 20% probability
- Thinking: 10% probability

### AutoTyperViewModel

Manages UI state and coordinates between clipboard monitoring and typing simulation.

```swift
class AutoTyperViewModel: ObservableObject {
    enum UIState {
        case idle
        case countdown(Int)
        case typing(SpeedMode)
    }
    
    @Published var state: UIState = .idle
    @Published var clipboardText: String?
    
    private let clipboardMonitor: ClipboardMonitor
    private let typingSimulator: TypingSimulator
    private var countdownTimer: Timer?
    
    func startAutoType()
    func stop()
    private func startCountdown()
    private func beginTyping()
}
```

**Responsibilities:**
- Manage UI state transitions
- Coordinate countdown timer
- Trigger typing simulation
- Handle stop requests

**State Transitions:**
```
idle → countdown(3) → countdown(2) → countdown(1) → typing(mode) → idle
  ↑                                                      ↓
  └──────────────────── stop() ────────────────────────┘
```

### FloatingWindow

SwiftUI view that renders the floating overlay interface.

```swift
struct FloatingWindow: View {
    @ObservedObject var viewModel: AutoTyperViewModel
    
    var body: some View {
        // Conditional rendering based on viewModel.state
    }
}

struct FloatingWindowController {
    private var window: NSWindow?
    
    func show()
    func hide()
    func configureWindow()
}
```

**Responsibilities:**
- Render UI based on current state
- Handle user interactions (Start, Stop buttons)
- Configure window properties (always on top, no dock, no focus steal)

**Window Configuration:**
- Level: `.floating` or `.statusBar`
- Collection Behavior: `.canJoinAllSpaces`, `.stationary`
- Style Mask: `.borderless`
- Background: Semi-transparent with blur effect
- Position: Top center of screen

## Data Models

### UIState

Represents the current state of the floating UI.

```swift
enum UIState {
    case idle
    case countdown(Int)  // Associated value: remaining seconds
    case typing(SpeedMode)  // Associated value: current speed mode
}
```

### SpeedMode

Represents typing speed categories with associated delay ranges.

```swift
enum SpeedMode: String {
    case slow = "Slow typing"
    case normal = "Typing"
    case littleFast = "Little Fast Typing"
    case thinking = "Thinking"
    
    var delayRange: ClosedRange<TimeInterval> {
        switch self {
        case .slow: return 0.15...0.30
        case .normal: return 0.08...0.15
        case .littleFast: return 0.04...0.08
        case .thinking: return 0.50...1.50
        }
    }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Clipboard Change Detection

*For any* sequence of clipboard changes, when text content is added to the clipboard, the ClipboardMonitor should detect the change within 500 milliseconds and publish the new text content.

**Validates: Requirements 1.1, 1.2, 1.4**

### Property 2: Non-Text Clipboard Filtering

*For any* clipboard content that is not plain text (images, files, etc.), the ClipboardMonitor should not publish any text content and the Floating_UI should remain hidden.

**Validates: Requirements 1.3**

### Property 3: Countdown Sequence Integrity

*For any* countdown initiation, the countdown should proceed from 3 to 2 to 1 with approximately 1-second intervals between each number, unless stopped by the user.

**Validates: Requirements 3.3**

### Property 4: Stop Cancels Countdown

*For any* countdown in progress, when the stop button is clicked, the countdown should immediately cancel and the UI should return to idle state without proceeding to typing.

**Validates: Requirements 5.1, 5.2**

### Property 5: Stop Halts Typing

*For any* typing operation in progress, when the stop button is clicked, the typing should immediately cease and no additional characters should be typed.

**Validates: Requirements 5.3, 5.4, 5.5**

### Property 6: Complete Text Typing

*For any* clipboard text content, when typing completes without interruption, the total number of keyboard events generated should equal the number of characters in the original text.

**Validates: Requirements 4.2, 4.4**

### Property 7: Delay Range Compliance

*For any* character typed in a given speed mode, the delay before the next character should fall within the specified range for that speed mode.

**Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5, 6.6**

### Property 8: Window Always On Top

*For any* window configuration, the floating window's level should be set to a value that ensures it appears above all standard application windows.

**Validates: Requirements 2.3**

### Property 9: No Focus Steal

*For any* floating window appearance, the currently focused application should retain keyboard focus after the window appears.

**Validates: Requirements 2.5, 8.3**

### Property 10: Typing Uses Captured Content

*For any* typing operation, if the clipboard content changes after countdown completion but before typing finishes, the typing should continue with the content that was captured at countdown completion.

**Validates: Requirements 4.5**

## Error Handling

### Accessibility Permission Denied

**Scenario:** User has not granted Accessibility permissions.

**Handling:**
- Check `AXIsProcessTrusted()` before attempting to post CGEvents
- If false, display alert with instructions to enable permissions in System Preferences
- Provide "Open System Preferences" button that opens the Security & Privacy pane
- Disable Start button until permissions are granted
- Re-check permissions when app returns to foreground

### Clipboard Access Failure

**Scenario:** NSPasteboard access fails or returns nil.

**Handling:**
- Log error for debugging
- Continue monitoring (transient failure)
- Do not show floating UI if clipboard content cannot be read
- Display error message if failures persist

### CGEvent Creation Failure

**Scenario:** CGEvent creation fails for a character.

**Handling:**
- Log the character that failed
- Skip the character and continue with next character
- Track failure count
- If failures exceed threshold (e.g., 10% of characters), stop typing and show error

### Timer Failure

**Scenario:** Timer for clipboard monitoring or countdown fails to fire.

**Handling:**
- Implement timer validation
- Recreate timer if it becomes invalid
- Fall back to manual polling if timer repeatedly fails

### Window Configuration Failure

**Scenario:** NSWindow configuration fails to set desired properties.

**Handling:**
- Log configuration errors
- Apply fallback configurations
- Ensure window is at least visible and functional
- Warn user if critical properties (always on top) cannot be set

## Testing Strategy

### Unit Testing

Unit tests will verify specific behaviors and edge cases:

- ClipboardMonitor detects changes correctly
- ClipboardMonitor ignores non-text content
- TypingSimulator generates correct number of events
- TypingSimulator respects stop flag
- AutoTyperViewModel state transitions work correctly
- Countdown timer fires at correct intervals
- Speed mode selection produces valid modes
- Delay calculation returns values within range

### Property-Based Testing

Property-based tests will verify universal properties across randomized inputs. Each test should run a minimum of 100 iterations.

**Test Configuration:**
- Framework: Use Swift's built-in XCTest with custom property test helpers, or integrate a library like SwiftCheck
- Iterations: Minimum 100 per property test
- Tagging: Each test references its design property number

**Property Test Cases:**

1. **Clipboard Change Detection** (Property 1)
   - Generate random text strings
   - Set clipboard content
   - Verify detection within 500ms
   - **Tag: Feature: clipboard-auto-typer, Property 1**

2. **Non-Text Filtering** (Property 2)
   - Generate various non-text clipboard content types
   - Verify no text is published
   - **Tag: Feature: clipboard-auto-typer, Property 2**

3. **Countdown Integrity** (Property 3)
   - Start countdown multiple times
   - Measure intervals between counts
   - Verify sequence 3→2→1
   - **Tag: Feature: clipboard-auto-typer, Property 3**

4. **Stop Cancels Countdown** (Property 4)
   - Start countdown
   - Stop at random point (0-3 seconds)
   - Verify typing never starts
   - **Tag: Feature: clipboard-auto-typer, Property 4**

5. **Stop Halts Typing** (Property 5)
   - Generate random text of varying lengths
   - Start typing
   - Stop at random point
   - Verify no additional events after stop
   - **Tag: Feature: clipboard-auto-typer, Property 5**

6. **Complete Text Typing** (Property 6)
   - Generate random text strings
   - Type without interruption
   - Count generated events
   - Verify count equals character count
   - **Tag: Feature: clipboard-auto-typer, Property 6**

7. **Delay Range Compliance** (Property 7)
   - For each speed mode, generate random characters
   - Measure delays between events
   - Verify all delays fall within mode's range
   - **Tag: Feature: clipboard-auto-typer, Property 7**

8. **Window Always On Top** (Property 8)
   - Create window with various configurations
   - Verify window level is always floating or higher
   - **Tag: Feature: clipboard-auto-typer, Property 8**

9. **No Focus Steal** (Property 9)
   - Show window while another app has focus
   - Verify focused app retains focus
   - **Tag: Feature: clipboard-auto-typer, Property 9**

10. **Typing Uses Captured Content** (Property 10)
    - Start typing with initial text
    - Change clipboard during typing
    - Verify typed content matches initial text
    - **Tag: Feature: clipboard-auto-typer, Property 10**

### Integration Testing

Integration tests will verify component interactions:

- ViewModel correctly coordinates ClipboardMonitor and TypingSimulator
- UI updates reflect ViewModel state changes
- Window appears/hides based on clipboard content
- End-to-end flow: copy text → show UI → start → countdown → type → complete

### Manual Testing

Manual testing will verify user experience aspects:

- Visual appearance matches design specifications
- Animations are smooth
- Window positioning is correct on various screen sizes
- Dark mode appearance is appropriate
- Typing feels natural and human-like
- Accessibility permissions prompt is clear
