# AI Custom Rules Guide

## Overview

The AI Custom Rules system allows you to define additional instructions for the AI assistant without modifying code. Rules are loaded from a text file and automatically appended to every AI prompt.

---

## 📁 File Location

**Path**: `book/Config/AIRules.txt`

This file is automatically loaded when the app starts.

---

## 📝 How to Add Rules

### 1. Open the Rules File

Navigate to `book/Config/AIRules.txt` in your project.

### 2. Add Your Rules

Each rule should be on its own line, starting with a dash (-):

```
- Always respond in a friendly and encouraging tone
- Keep responses concise unless asked for detailed explanations
- Use examples when explaining technical concepts
```

### 3. Comments and Empty Lines

- Lines starting with `#` are comments (ignored)
- Empty lines are ignored
- Use comments to organize your rules

**Example**:
```
# Tone and Style Rules
- Always be friendly and encouraging
- Use simple language when possible

# Response Format Rules
- Keep responses concise by default
- Use bullet points for lists

# Technical Rules
- Provide code examples when explaining programming concepts
- Explain technical terms when first used
```

---

## 🔄 Reloading Rules

### Option 1: Restart the App
Rules are automatically loaded when the app starts.

### Option 2: Programmatic Reload (Future Enhancement)
You can add a button in settings to reload rules without restarting:

```swift
ragService.reloadCustomRules()
```

---

## 📋 Rule Examples

### Tone and Personality
```
- Always respond in a friendly and encouraging tone
- Use humor when appropriate but stay professional
- Be empathetic and understanding
- Show enthusiasm for the user's projects and ideas
```

### Response Style
```
- Keep responses concise unless asked for detailed explanations
- Use bullet points for lists of 3 or more items
- Break long responses into clear sections
- Use examples to illustrate complex concepts
```

### Technical Assistance
```
- Provide code examples when explaining programming concepts
- Explain technical terms when first used
- Suggest best practices and common pitfalls
- Offer alternative approaches when relevant
```

### Conversation Management
```
- Ask clarifying questions if the user's request is ambiguous
- Summarize long conversations periodically
- Confirm understanding before providing complex solutions
- Offer to break down complex tasks into steps
```

### Domain-Specific Rules
```
- When discussing code, always mention potential security implications
- For design questions, consider accessibility requirements
- When suggesting libraries, mention their maintenance status
- For performance questions, discuss trade-offs
```

---

## 🎯 Best Practices

### 1. Be Specific
❌ Bad: "Be helpful"  
✅ Good: "Provide step-by-step instructions for technical tasks"

### 2. Be Actionable
❌ Bad: "Think about the user"  
✅ Good: "Ask clarifying questions if the request is ambiguous"

### 3. Avoid Conflicts
Make sure your rules don't contradict each other or the base instructions.

### 4. Keep It Manageable
Start with 5-10 rules. Too many rules can confuse the AI.

### 5. Test Your Rules
After adding rules, test the AI's responses to ensure they're being followed.

---

## 🔍 How It Works

### 1. File Loading
When the app starts, `InMemoryRAGService` loads `AIRules.txt`:

```swift
init() {
    loadCustomRules()
}
```

### 2. Rule Parsing
The system:
- Reads the file line by line
- Removes comments (lines starting with #)
- Removes empty lines
- Stores valid rules in memory

### 3. Prompt Building
When building a prompt, custom rules are appended:

```
CRITICAL INSTRUCTIONS:
- Answer NATURALLY like a human would
- Use the CURRENT TOPIC and RECENT CONVERSATION to understand pronouns
[... base instructions ...]

ADDITIONAL CUSTOM RULES:
- [Your custom rule 1]
- [Your custom rule 2]
- [Your custom rule 3]

ASSISTANT:
```

---

## 📊 Example Configuration

Here's a complete example `AIRules.txt`:

```
# AI Assistant Custom Rules
# Project: Voice-to-Text AI Chat
# Last Updated: February 11, 2026

# ===== TONE AND PERSONALITY =====
- Always respond in a friendly and encouraging tone
- Use simple, clear language
- Show enthusiasm for the user's projects

# ===== RESPONSE FORMAT =====
- Keep responses concise by default
- Use bullet points for lists of 3+ items
- Break long explanations into clear sections

# ===== TECHNICAL ASSISTANCE =====
- Provide code examples when explaining programming concepts
- Mention potential security implications for code suggestions
- Suggest best practices and common pitfalls
- Explain technical terms when first used

# ===== CONVERSATION MANAGEMENT =====
- Ask clarifying questions if the request is ambiguous
- Confirm understanding before providing complex solutions
- Offer to break down complex tasks into steps

# ===== DOMAIN-SPECIFIC =====
- For Swift/SwiftUI questions, follow Apple's design guidelines
- When discussing APIs, mention rate limits and error handling
- For UI/UX suggestions, consider accessibility requirements
```

---

## 🧪 Testing Your Rules

### 1. Add a Test Rule
```
- Always end responses with "Hope this helps!"
```

### 2. Restart the App
Close and reopen the app to load the new rules.

### 3. Test a Query
Ask the AI a question and verify it follows your rule.

### 4. Check Console
Look for the loading message:
```
✅ Loaded 5 custom AI rules
```

---

## 🐛 Troubleshooting

### Rules Not Loading?

**Check 1**: File exists at `book/Config/AIRules.txt`
```bash
ls -la book/Config/AIRules.txt
```

**Check 2**: File is included in Xcode project
- Open Xcode
- Check if `AIRules.txt` appears in the file navigator
- Verify it's in the "Copy Bundle Resources" build phase

**Check 3**: Check console for loading message
Look for: `✅ Loaded X custom AI rules`

### Rules Not Being Followed?

**Issue 1**: Rules are too vague
- Make rules specific and actionable

**Issue 2**: Rules conflict with base instructions
- Review base instructions in `buildAugmentedPrompt()`
- Ensure your rules complement, not contradict

**Issue 3**: Too many rules
- Start with 5-10 most important rules
- Add more gradually

---

## 🔧 Advanced Usage

### Dynamic Rule Loading

Add a settings option to reload rules without restarting:

```swift
// In SettingsView.swift
Button("Reload AI Rules") {
    ragService.reloadCustomRules()
}
```

### Rule Profiles

Create multiple rule files for different contexts:

```
AIRules_Casual.txt
AIRules_Professional.txt
AIRules_Technical.txt
```

Then load the appropriate one based on user preference.

### Rule Validation

Add validation to ensure rules are well-formed:

```swift
private func validateRule(_ rule: String) -> Bool {
    // Check minimum length
    guard rule.count > 10 else { return false }
    
    // Check for actionable verbs
    let actionVerbs = ["always", "never", "use", "provide", "ask", "explain"]
    return actionVerbs.contains(where: { rule.lowercased().contains($0) })
}
```

---

## 📈 Impact on Performance

### Token Usage
Each custom rule adds ~10-20 tokens to every prompt.

**Example**:
- 5 rules ≈ 50-100 extra tokens per message
- 10 rules ≈ 100-200 extra tokens per message

### Recommendations
- Keep rules concise (under 100 characters each)
- Limit to 10-15 rules maximum
- Monitor API costs if using many rules

---

## 🎯 Example Use Cases

### 1. Personal Assistant Mode
```
- Address me by name when appropriate
- Remember my preferences and habits
- Proactively suggest related topics
- Keep track of my ongoing projects
```

### 2. Coding Tutor Mode
```
- Explain concepts step-by-step
- Provide code examples for every explanation
- Ask if I understand before moving on
- Suggest practice exercises
```

### 3. Professional Mode
```
- Use formal language
- Provide detailed, comprehensive answers
- Include references and sources when possible
- Focus on accuracy over speed
```

### 4. Creative Writing Assistant
```
- Encourage creative thinking
- Offer multiple alternatives
- Ask about tone and style preferences
- Provide constructive feedback
```

---

## 📝 Template

Copy this template to get started:

```
# AI Assistant Custom Rules
# Add your custom instructions below

# ===== TONE =====
- [Your tone rule]

# ===== FORMAT =====
- [Your format rule]

# ===== TECHNICAL =====
- [Your technical rule]

# ===== CONVERSATION =====
- [Your conversation rule]

# ===== CUSTOM =====
- [Your custom rule]
```

---

## ✅ Summary

1. **File**: `book/Config/AIRules.txt`
2. **Format**: One rule per line, starting with `-`
3. **Comments**: Lines starting with `#` are ignored
4. **Loading**: Automatic on app start
5. **Reload**: Restart app or call `reloadCustomRules()`
6. **Best Practice**: 5-10 specific, actionable rules

---

**Your custom rules are now integrated into every AI conversation! 🎉**
