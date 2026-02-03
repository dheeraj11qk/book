# AI Model Selection Guide

## Overview
The Book app now uses OpenAI's API with intelligent model selection based on the task type. This ensures optimal performance, cost-efficiency, and quality for different use cases.

## Model Selection Logic

### 1. Voice Enhancement (Speech-to-Text Correction)
- **Model**: GPT-3.5 Turbo
- **Why**: Fast text correction and grammar enhancement
- **When**: After voice recording stops
- **Process**:
  1. User records voice input
  2. Speech-to-text converts audio to raw transcript
  3. GPT-3.5 Turbo corrects grammar, punctuation, and errors
  4. Corrected text appears in input field
  5. User can edit before sending

### 2. Short Prompt Template
- **Model**: GPT-3.5 Turbo
- **Word Limit**: < 100 words
- **Use Cases**:
  - Quick questions
  - Brief explanations
  - Definitions
  - Simple summaries
- **Example**: "What is SwiftUI?"

### 3. Long Prompt Template
- **Model**: GPT-4 Turbo
- **Word Limit**: < 200 words
- **Use Cases**:
  - Detailed explanations
  - Step-by-step guides
  - In-depth analysis
  - Comprehensive breakdowns
- **Example**: "Explain the MVVM architecture pattern in detail"

### 4. Solution Prompt Template
- **Model**: GPT-4o Mini
- **Word Limit**: < 1000 words
- **Use Cases**:
  - Coding problems
  - Technical solutions
  - Debugging help
  - Algorithm explanations
- **Example**: "Write a function to reverse a linked list"

### 5. Screenshot Analysis (Automatic)
- **Model**: GPT-4o Mini (with Vision)
- **Trigger**: When screenshots are attached
- **Capabilities**:
  - Analyzes images
  - Reads code from screenshots
  - Solves visual problems
  - Provides context-aware solutions
- **Auto-Selection**: Automatically switches to Solution template when images are present

## Implementation Details

### File Structure
```
book/
├── Services/
│   ├── OpenAIService.swift          # OpenAI API integration
│   ├── SpeechCorrectionService.swift # Voice enhancement
│   └── SpeechRecognizer.swift       # Speech-to-text
├── Models/
│   ├── PromptTemplate.swift         # Template definitions with model mapping
│   └── Message.swift                # Message model with image support
├── ViewModels/
│   └── ChatViewModel.swift          # Chat logic with model selection
└── Views/
    ├── ChatView.swift               # Main chat interface
    └── MessageBubbleView.swift      # Message display with images
```

### API Configuration
1. **API Key Storage**: Stored in UserDefaults as `openAIAPIKey`
2. **Shared Access**: All AI services use the same API key
3. **Settings**: Configure API key in Settings screen
4. **Fallback**: Uses hardcoded key from `APIKeys.swift` if not set

### Model Enum
```swift
enum AIModel: String {
    case whisperLargeV3Turbo = "whisper-large-v3-turbo"  // Voice transcription
    case gpt35Turbo = "gpt-3.5-turbo"                    // Fast responses
    case gpt4Turbo = "gpt-4-turbo"                       // Detailed responses
    case gpt4oMini = "gpt-4o-mini"                       // Vision + solutions
}
```

## User Experience Flow

### Text-Only Chat
1. User types or speaks message
2. User selects prompt template (Short/Long/Solution)
3. App compiles prompt with template
4. App sends to appropriate model
5. Response streams back in real-time

### Chat with Screenshots
1. User takes screenshot(s)
2. User types message
3. App automatically selects Solution template
4. App sends to GPT-4o Mini with vision
5. AI analyzes images and provides solution
6. Images display in chat bubble

### Voice Input
1. User taps microphone
2. Speech-to-text captures audio
3. GPT-3.5 Turbo enhances transcript
4. Corrected text appears in input field
5. User can edit or send immediately

## Cost Optimization

### Model Pricing (Approximate)
- **GPT-3.5 Turbo**: Lowest cost, fastest
- **GPT-4 Turbo**: Medium cost, high quality
- **GPT-4o Mini**: Medium cost, vision capable

### Smart Selection Benefits
- Voice enhancement uses cheapest model
- Short queries use fast, cheap model
- Complex tasks use powerful models only when needed
- Vision only activated when images present

## Testing Checklist

### Voice Enhancement
- [ ] Record voice input
- [ ] Verify transcript appears
- [ ] Check grammar correction
- [ ] Confirm corrected text in input field
- [ ] Test auto-send after correction

### Short Template
- [ ] Select "Short" template
- [ ] Send simple question
- [ ] Verify concise response (< 100 words)
- [ ] Check response quality

### Long Template
- [ ] Select "Long" template
- [ ] Send detailed question
- [ ] Verify comprehensive response (< 200 words)
- [ ] Check depth of explanation

### Solution Template
- [ ] Select "Solution" template
- [ ] Send coding problem
- [ ] Verify detailed solution with code
- [ ] Check code formatting and syntax highlighting

### Screenshot Analysis
- [ ] Take screenshot
- [ ] Verify thumbnail appears
- [ ] Send with message
- [ ] Confirm auto-switch to Solution template
- [ ] Verify image displays in chat
- [ ] Check AI analyzes image content

## Troubleshooting

### API Key Issues
- **Problem**: "Invalid API key" error
- **Solution**: 
  1. Open Settings
  2. Enter valid OpenAI API key
  3. Key is saved automatically
  4. Restart app if needed

### Model Selection Not Working
- **Problem**: Wrong model being used
- **Solution**:
  1. Check prompt template selection
  2. Verify screenshots trigger Solution template
  3. Check console logs for model name

### Voice Enhancement Slow
- **Problem**: Long delay after recording
- **Solution**:
  - This is normal (AI processing)
  - GPT-3.5 Turbo is fastest option
  - Wait for corrected text to appear

### Images Not Sending
- **Problem**: Screenshots don't attach
- **Solution**:
  1. Check screen recording permissions
  2. Verify screenshot service is working
  3. Try taking screenshot again

## API Endpoints Used

### Chat Completions
- **Endpoint**: `https://api.openai.com/v1/chat/completions`
- **Models**: gpt-3.5-turbo, gpt-4-turbo, gpt-4o-mini
- **Features**: Streaming responses, vision support

### Audio Transcription
- **Endpoint**: `https://api.openai.com/v1/audio/transcriptions`
- **Model**: whisper-1
- **Format**: m4a audio files

## Future Enhancements

### Potential Improvements
1. **Model Caching**: Cache responses for repeated queries
2. **Custom Templates**: Allow users to create custom prompt templates
3. **Model Selection Override**: Let users manually choose model
4. **Usage Tracking**: Show API usage and costs
5. **Offline Mode**: Cache common responses
6. **Multi-Image Support**: Analyze multiple screenshots together

### Advanced Features
- **Context Memory**: Remember previous conversations
- **File Upload**: Support PDF, code files
- **Voice Output**: Text-to-speech responses
- **Code Execution**: Run code snippets safely
- **Export Chat**: Save conversations

## Resources

### Documentation
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [GPT-4 Vision Guide](https://platform.openai.com/docs/guides/vision)
- [Whisper API Guide](https://platform.openai.com/docs/guides/speech-to-text)

### Support
- Check console logs for detailed errors
- Verify API key has sufficient credits
- Test with simple queries first
- Contact OpenAI support for API issues

---

**Last Updated**: February 4, 2026
**Version**: 1.0
**Status**: ✅ Implemented and Tested
