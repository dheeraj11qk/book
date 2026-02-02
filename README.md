# book

A macOS voice-to-text chat application with AI-powered speech correction and screen capture privacy features.

## Features

- **Voice Recognition**: Real-time speech-to-text with Apple's Speech Recognition
- **AI Speech Correction**: Automatic grammar and punctuation correction using Groq API
- **Chat Interface**: Clean chat UI with message bubbles and streaming responses
- **Screenshot Integration**: Take and send screenshots with your messages
- **Screen Capture Privacy**: Hide content from screen recordings/sharing
- **Prompt Templates**: Short, Long, and Solution prompt options
- **Markdown Support**: Rich text formatting in chat messages
- **Transparent Background**: Glass-like transparent window design

## Requirements

- macOS 15.2+
- Xcode 16+
- Groq API key

## Setup

1. Clone the repository
2. Copy `book/Config/APIKeys.swift.template` to `book/Config/APIKeys.swift`
3. Replace `"YOUR_GROQ_API_KEY_HERE"` with your actual Groq API key
4. Open `book.xcodeproj` in Xcode
5. Build and run the project

**Note**: The `APIKeys.swift` file is ignored by Git to keep your API key secure.

## Architecture

- **MVC Pattern**: Clean separation of Models, Views, and ViewModels
- **Services**: Modular services for API, Speech Recognition, Screenshots, etc.
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for state management

## Privacy

The app includes screen capture detection and privacy controls to protect sensitive information during screen sharing or recording.