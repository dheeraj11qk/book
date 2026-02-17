# Clipboard Auto-Typer Feature Guide

## Overview

The Clipboard Auto-Typer is an integrated overlay feature that monitors your clipboard and automatically types copied text with human-like behavior. It appears inside your chat window at the top center.

## How It Works

1. **Copy Text**: Copy any text to your clipboard
2. **Overlay Appears**: A compact overlay appears at the top center inside your chat window
3. **Click Play**: Click the play button (▶) to start
4. **3-2-1 Countdown**: A countdown gives you time to position your cursor
5. **Auto-Type**: The text is automatically typed at your cursor position with natural human-like delays

## UI States

### Idle State
- Shows: `Auto Type |>` (white text with play button)
- Action: Click play to start countdown

### Countdown State
- Shows: `Auto Type 3`, `Auto Type 2`, `Auto Type 1` (orange countdown)
- Shows Stop button (⏹) to cancel
- Gives you 3 seconds to position your cursor

### Typing States
- Shows current typing mode in green:
  - `Slow typing` - Slower, deliberate typing
  - `Typing` - Normal typing speed
  - `Little Fast Typing` - Faster typing
  - `Thinking` - Includes longer pauses (simulating thinking)
- Shows Stop button (⏹) to immediately halt typing

## Features

✅ **Integrated Overlay**: Appears inside your chat window, not as a separate window
✅ **Human-Like Typing**: Random delays and speed variations make typing appear natural
✅ **Smooth Animations**: Slides in from top with spring animation
✅ **Dark Mode Support**: Matches your chat window theme
✅ **Instant Stop**: Cancel anytime during countdown or typing
✅ **Auto-Hide**: Disappears when clipboard is empty

## Requirements

### Accessibility Permission
The app requires Accessibility permissions to simulate keyboard input:

1. When you first try to auto-type, you'll see a permission prompt
2. Click "Open System Preferences"
3. Enable the app in: System Preferences > Security & Privacy > Privacy > Accessibility
4. Return to the app and try again

## Technical Details

- **Clipboard Monitoring**: Checks clipboard every 500ms
- **Speed Modes**:
  - Slow: 150-300ms between characters
  - Normal: 80-150ms between characters
  - Little Fast: 40-80ms between characters
  - Thinking: 500-1500ms pauses
- **Overlay Position**: Top center, 50px from top edge

## Tips

- Position your cursor before the countdown ends
- Use Stop button if you need to cancel
- The overlay only appears when text is in your clipboard
- Works with any text content from any application
- Automatically starts monitoring when chat view appears

## Implementation Files

All auto-typer files are organized in dedicated folders:
- Models: `book/Models/AutoTyper/`
- Services: `book/Services/AutoTyper/`
- ViewModels: `book/ViewModels/AutoTyper/`
- Views: `book/Views/AutoTyper/`

## Integration

The feature is seamlessly integrated into ChatView:
- Overlay appears as a ZStack layer on top of chat content
- Automatically starts/stops monitoring with view lifecycle
- No separate windows or external UI elements

## No Impact on Existing Code

This feature is completely standalone and doesn't modify any existing chat functionality.
