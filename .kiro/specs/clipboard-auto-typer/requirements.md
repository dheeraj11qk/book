# Requirements Document

## Introduction

The Clipboard Auto-Typer is a macOS utility that monitors the system clipboard and provides an auto-typing feature with human-like typing simulation. The application presents a floating UI overlay that allows users to automatically type clipboard content at any cursor position with natural typing behavior.

## Glossary

- **Auto_Typer**: The system that simulates keyboard input to type clipboard content
- **Floating_UI**: The always-on-top window that displays controls and status
- **Clipboard_Monitor**: The component that continuously checks for clipboard changes
- **Typing_Simulator**: The component that generates keyboard events with human-like timing
- **Countdown_Timer**: The 3-second delay before typing begins
- **Speed_Mode**: The typing speed category (Slow, Normal, Little Fast, Thinking)

## Requirements

### Requirement 1: Clipboard Monitoring

**User Story:** As a user, I want the application to monitor my clipboard continuously, so that the auto-typing feature is available whenever I copy text.

#### Acceptance Criteria

1. WHEN the application starts, THE Clipboard_Monitor SHALL begin polling the system clipboard for changes
2. WHEN new text content is detected in the clipboard, THE Clipboard_Monitor SHALL notify the Floating_UI to become visible
3. WHEN the clipboard contains non-text content, THE Floating_UI SHALL remain hidden
4. WHILE the application is running, THE Clipboard_Monitor SHALL check for clipboard changes at regular intervals not exceeding 500 milliseconds
5. WHEN the clipboard content changes to empty, THE Floating_UI SHALL hide itself

### Requirement 2: Floating UI Positioning and Appearance

**User Story:** As a user, I want a minimal floating UI at the top center of my screen, so that I can access auto-typing controls without disrupting my workflow.

#### Acceptance Criteria

1. WHEN the Floating_UI is displayed, THE Floating_UI SHALL position itself at the horizontal center of the primary screen
2. WHEN the Floating_UI is displayed, THE Floating_UI SHALL position itself at the top edge of the primary screen with appropriate padding
3. THE Floating_UI SHALL remain above all other windows at all times
4. THE Floating_UI SHALL NOT appear in the macOS Dock
5. WHEN the Floating_UI appears, THE Floating_UI SHALL NOT steal keyboard focus from the active application
6. THE Floating_UI SHALL render with semi-transparent background and rounded corners
7. WHEN the system is in dark mode, THE Floating_UI SHALL adapt its appearance to dark mode styling

### Requirement 3: UI State Management

**User Story:** As a user, I want clear visual feedback about the auto-typing state, so that I know when to position my cursor and when typing will occur.

#### Acceptance Criteria

1. WHEN the Floating_UI first appears with new clipboard content, THE Floating_UI SHALL display the Idle State showing "Auto Type |>" button
2. WHEN the user clicks the "Auto Type |>" button, THE Floating_UI SHALL transition to Countdown State
3. WHILE in Countdown State, THE Floating_UI SHALL display a countdown from 3 to 1 with one-second intervals
4. WHILE in Countdown State, THE Floating_UI SHALL display a Stop button
5. WHEN the countdown reaches zero, THE Floating_UI SHALL transition to Typing State
6. WHILE in Typing State, THE Floating_UI SHALL display the current Speed_Mode status text
7. WHILE in Typing State, THE Floating_UI SHALL display a Stop button
8. WHEN typing completes, THE Floating_UI SHALL return to Idle State

### Requirement 4: Auto-Typing Operation

**User Story:** As a user, I want the application to automatically type my clipboard content at my cursor position after a countdown, so that I have time to position my cursor where I need the text.

#### Acceptance Criteria

1. WHEN the Countdown_Timer completes, THE Auto_Typer SHALL read the current clipboard text content
2. WHEN the Auto_Typer begins typing, THE Typing_Simulator SHALL generate keyboard events for each character in the clipboard text
3. WHEN a keyboard event is generated, THE Typing_Simulator SHALL send it to the currently focused application
4. WHEN all characters have been typed, THE Auto_Typer SHALL signal completion
5. IF the clipboard content changes during typing, THE Auto_Typer SHALL continue typing the original content that was captured at countdown completion

### Requirement 5: Stop Functionality

**User Story:** As a user, I want to cancel the countdown or stop typing in progress, so that I can abort the operation if I change my mind or position my cursor incorrectly.

#### Acceptance Criteria

1. WHEN the user clicks Stop during Countdown State, THE Countdown_Timer SHALL immediately cancel
2. WHEN the user clicks Stop during Countdown State, THE Floating_UI SHALL return to Idle State
3. WHEN the user clicks Stop during Typing State, THE Typing_Simulator SHALL immediately cease generating keyboard events
4. WHEN the user clicks Stop during Typing State, THE Floating_UI SHALL return to Idle State
5. WHEN Stop is triggered, THE Auto_Typer SHALL discard any remaining untyped characters

### Requirement 6: Human Typing Simulation

**User Story:** As a user, I want the auto-typing to simulate natural human typing behavior, so that the typed text appears more realistic and less robotic.

#### Acceptance Criteria

1. WHEN typing a character, THE Typing_Simulator SHALL introduce a random delay before the next character
2. THE Typing_Simulator SHALL vary delays according to the current Speed_Mode
3. WHEN in Slow mode, THE Typing_Simulator SHALL use delays between 150 and 300 milliseconds
4. WHEN in Normal mode, THE Typing_Simulator SHALL use delays between 80 and 150 milliseconds
5. WHEN in Little Fast mode, THE Typing_Simulator SHALL use delays between 40 and 80 milliseconds
6. WHEN in Thinking mode, THE Typing_Simulator SHALL occasionally introduce longer pauses between 500 and 1500 milliseconds
7. THE Typing_Simulator SHALL randomly select Speed_Mode during typing to create natural variation
8. THE Typing_Simulator SHALL transition between Speed_Modes smoothly during a single typing session

### Requirement 7: System Permissions and Integration

**User Story:** As a user, I want the application to request necessary permissions and integrate properly with macOS, so that the auto-typing functionality works reliably.

#### Acceptance Criteria

1. WHEN the application first attempts to generate keyboard events, THE Auto_Typer SHALL check for Accessibility permissions
2. IF Accessibility permissions are not granted, THEN THE Auto_Typer SHALL display a prompt directing the user to System Preferences
3. THE Clipboard_Monitor SHALL use NSPasteboard API to access clipboard content
4. THE Typing_Simulator SHALL use CGEvent API to generate keyboard events
5. THE Floating_UI SHALL configure its window to prevent Dock appearance
6. THE Floating_UI SHALL configure its window level to remain always on top
7. THE Floating_UI SHALL configure its window to not steal focus when appearing

### Requirement 8: Application Lifecycle

**User Story:** As a user, I want the application to run smoothly in the background without interfering with my other work, so that I can use it whenever needed without disruption.

#### Acceptance Criteria

1. WHEN the application launches, THE Clipboard_Monitor SHALL start automatically
2. THE Floating_UI SHALL only appear when clipboard contains text content
3. WHEN the application is running, THE Floating_UI SHALL NOT prevent other applications from receiving input
4. THE Auto_Typer SHALL operate independently without blocking the main UI thread
5. WHEN the application quits, THE Clipboard_Monitor SHALL stop polling
