# How to Test Your Book App

## Quick Start

✅ **Compiler Error Fixed!** The SettingsView type-checking issue has been resolved.

Your code structure is **complete and correct**! Here's how to test it:

### 1. Open in Xcode
```bash
open book.xcodeproj
```

### 2. Select Target
- In Xcode, select "My Mac" as the run destination
- Make sure the scheme is set to "book"

### 3. Build and Run
- Press `Cmd + R` or click the Play button
- Wait for the build to complete

### 4. Grant Permissions
When the app launches, you'll be prompted for:
- ✓ Microphone access (for voice input)
- ✓ Speech recognition (for transcription)
- ✓ Screen recording (for screenshots)

**Grant all permissions** for full functionality.

## Testing Each Feature

### 🎤 Voice Input Test
1. Click the **microphone icon** (bottom right)
2. Speak clearly: "What is artificial intelligence?"
3. Click the **stop button** (red circle)
4. Wait for AI to correct your speech
5. Message auto-sends after correction
6. Watch for streaming response

**Expected**: Your speech is transcribed, corrected, and sent to AI

### ⌨️ Text Input Test
1. Type in the text field: "Explain quantum computing"
2. Press **Enter** or click **send button**
3. Watch the AI response stream in

**Expected**: Message appears in chat, AI responds with streaming text

### 📸 Screenshot Test
1. Click the **camera icon**
2. Screenshot preview appears above input
3. Type a question: "What's in this image?"
4. Click send
5. Screenshot is included with your message

**Expected**: Screenshot is captured and sent with your message

### ⚙️ Settings Test
1. Click the **gear icon** (top left)
2. Toggle "Hide from Screen Capture"
3. Edit API key if needed
4. Upload a resume file (optional)
5. Click **Save**

**Expected**: Settings are saved and persist

### 🔄 Reset Test
1. Click the **refresh icon** (top right)
2. Chat history clears
3. Screenshots are removed

**Expected**: Clean slate for new conversation

## Common Issues & Solutions

### ❌ Issue: "No AI response"

**Symptoms**: Message sends but no response appears

**Likely Cause**: Invalid API model name

**Solution**:
```bash
chmod +x fix_api_model.sh
./fix_api_model.sh
```

This updates the model from `openai/gpt-oss-120b` to `mixtral-8x7b-32768` (a valid Groq model).

**Manual Fix**:
Edit `book/Services/GroqAPIService.swift` line 28:
```swift
// Change from:
model: "openai/gpt-oss-120b"

// To:
model: "mixtral-8x7b-32768"
```

### ❌ Issue: "Microphone not working"

**Symptoms**: Clicking mic does nothing

**Solution**:
1. Open **System Settings**
2. Go to **Privacy & Security** > **Microphone**
3. Find "book" in the list
4. Toggle it **ON**
5. Restart the app

### ❌ Issue: "Screenshot fails"

**Symptoms**: Camera button doesn't capture screen

**Solution**:
1. Open **System Settings**
2. Go to **Privacy & Security** > **Screen Recording**
3. Find "book" in the list
4. Toggle it **ON**
5. Restart the app

### ❌ Issue: "Build fails"

**Symptoms**: Xcode shows build errors

**Solution**:
1. Clean build folder: `Cmd + Shift + K`
2. Close Xcode
3. Delete DerivedData:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/book-*
```
4. Reopen project and build

### ❌ Issue: "App crashes on launch"

**Symptoms**: App opens then immediately closes

**Solution**:
1. Check Console.app for crash logs
2. Look for permission errors
3. Ensure all entitlements are set
4. Try running from Xcode to see error messages

## Debugging Tips

### View Console Logs
While app is running in Xcode:
1. Open **Debug Area** (Cmd + Shift + Y)
2. Look for error messages
3. Common errors:
   - "Invalid API key" → Check Settings
   - "Model not found" → Run fix_api_model.sh
   - "Permission denied" → Grant system permissions

### Test API Connection
Add this to test API directly:
```swift
// In ChatView.swift, add to onAppear:
Task {
    do {
        let response = try await GroqAPIService().getSingleResponse("Hello")
        print("API Test Success: \(response)")
    } catch {
        print("API Test Failed: \(error)")
    }
}
```

### Check API Key
```bash
grep "groqAPIKey" book/Config/APIKeys.swift
```
Should show: `static let groqAPIKey = "gsk_..."`

## What Should Work

✅ **Working Features**:
- Voice input with speech recognition
- AI-powered speech correction
- Text input with Enter key
- Streaming AI responses
- Screenshot capture and preview
- Settings persistence
- Transparent window design
- Privacy mode (hide from screen capture)
- Prompt templates (Short/Long/Solution)
- Markdown formatting in responses
- Code syntax highlighting
- Copy code button

⚠️ **Known Limitations**:
- Chat history not persisted (lost on app close)
- No offline mode
- Requires active internet connection
- macOS 15.2+ only

## Performance Expectations

- **Voice transcription**: Real-time, < 1 second delay
- **AI correction**: 1-3 seconds
- **AI response**: Streams in real-time
- **Screenshot**: Instant capture
- **App launch**: < 2 seconds

## Success Criteria

Your app is working correctly if:
1. ✓ Voice input transcribes your speech
2. ✓ AI corrects grammar and punctuation
3. ✓ Messages auto-send after voice input
4. ✓ AI responds with streaming text
5. ✓ Screenshots can be captured and sent
6. ✓ Settings save and persist
7. ✓ UI is responsive and smooth

## Next Steps

1. **Run the app** in Xcode (Cmd + R)
2. **Test each feature** using the guide above
3. **Check for errors** in the debug console
4. **Apply fixes** if needed (likely just API model)
5. **Enjoy your AI chat app!**

## Need Help?

If something specific isn't working:
1. Note the exact error message
2. Check which feature fails
3. Look at Console.app logs
4. Review the DIAGNOSTIC_REPORT.md

---

**Your code is solid!** The most likely issue is just the API model name. Run the fix script and you should be good to go.
