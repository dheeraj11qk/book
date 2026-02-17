# AI Rules Dual Mode System - Quick Guide

## 🎯 Overview

Your AI assistant now has **two response modes** that automatically activate based on your question type:

1. **Interview Mode** (Default) - Short, speakable answers for conceptual questions
2. **Deep Dive Mode** - Detailed, structured answers with code examples

---

## 📋 Mode Detection

### Interview Mode Activates When:
- Question starts with: "What is", "Define", "Explain", "Tell me about"
- Question is about a **single concept**
- Question does NOT ask for code or implementation

**Examples:**
- ✅ "What is a Goroutine?"
- ✅ "Explain mutex"
- ✅ "What is a channel in Go?"
- ✅ "Define REST API"

### Deep Dive Mode Activates When:
- Question contains: "explain in detail", "show code", "how to implement", "give example", "deep dive", "elaborate"
- Question explicitly asks for code or implementation
- Question is about debugging or fixing code

**Examples:**
- ✅ "Explain goroutines in detail"
- ✅ "Show me how to implement a mutex"
- ✅ "Give me a code example of channels"
- ✅ "How do I fix this race condition?"

---

## 📝 Interview Mode Format

### Characteristics:
- **Length**: 2-4 sentences maximum
- **Format**: Numbered emoji (1️⃣)
- **Keywords**: 1-2 maximum
- **Code**: None (unless explicitly requested)
- **Tone**: Natural, speakable, as if in a live interview
- **Structure**: Definition → Purpose → Key characteristic

### Example Response:

**Question:** What is a Goroutine?

**Answer:**
```
1️⃣ A <keyword>goroutine</keyword> is a lightweight thread managed by the Go runtime. It allows us to run functions concurrently. Goroutines are much cheaper than OS threads, so we can easily run thousands of them.
```

### What Interview Mode AVOIDS:
- ❌ Markdown headers (no #, ##, ###)
- ❌ Bullet points (unless listing 2-3 items)
- ❌ Code blocks
- ❌ Complexity analysis
- ❌ "Key Points" or "Important Notes" sections
- ❌ Long explanations

---

## 🔍 Deep Dive Mode Format

### Characteristics:
- **Length**: Complete and thorough
- **Format**: Structured with sections
- **Keywords**: 2-4 keywords
- **Code**: Mandatory for implementation topics
- **Tone**: Professional, detailed
- **Structure**: Definition → Code → Explanation → Complexity

### Example Response:

**Question:** Explain goroutines in detail with code

**Answer:**
```
# Goroutine Overview

A <keyword>goroutine</keyword> is a <keyword>lightweight thread</keyword> managed by the <keyword>Go runtime</keyword>.

**Key Characteristics:**
- Lightweight execution
- Managed by Go scheduler
- Cheaper than OS threads

**Code Example:**
```go
func main() {
    var wg sync.WaitGroup
    wg.Add(1)
    
    go func() {
        defer wg.Done()
        fmt.Println("Hello from goroutine")
    }()
    
    wg.Wait()
}
```

**How it works:**
The `go` keyword spawns a new goroutine. The WaitGroup ensures the main function waits for the goroutine to complete.

**Complexity:** O(1) to spawn, minimal memory overhead (~2KB per goroutine)
```

---

## 🎯 How to Switch Modes

### Force Interview Mode (if in Deep Dive):
Just ask a simple "What is X?" question

### Force Deep Dive Mode (if in Interview):
Add trigger phrases:
- "explain in detail"
- "show me code"
- "how to implement"
- "give me an example"
- "deep dive into"
- "elaborate on"

---

## 💡 Usage Tips

### For Live Interviews:
1. Ask simple "What is X?" questions
2. Get short, speakable answers
3. Read them naturally during the call
4. Sound confident and knowledgeable

### For Learning/Practice:
1. Add "explain in detail" to your question
2. Get full structured answers with code
3. Study the implementation
4. Understand the concept deeply

### For Quick Revision:
1. Ask multiple "What is X?" questions
2. Get rapid-fire short answers
3. Review concepts quickly
4. Perfect for pre-interview prep

---

## 📊 Comparison Table

| Feature | Interview Mode | Deep Dive Mode |
|---------|---------------|----------------|
| **Length** | 2-4 sentences | Complete & thorough |
| **Format** | Numbered emoji | Structured sections |
| **Code** | No (unless asked) | Yes (mandatory) |
| **Keywords** | 1-2 | 2-4 |
| **Complexity** | No | Yes |
| **Bullet Points** | Minimal | Yes |
| **Headers** | No | Yes |
| **Use Case** | Live interviews | Learning & practice |

---

## 🧪 Test Examples

### Test 1: Interview Mode
**Ask:** "What is a mutex?"

**Expected:**
```
1️⃣ A <keyword>mutex</keyword> is used to protect shared data from concurrent access. It ensures only one goroutine can access the data at a time. This prevents race conditions.
```

### Test 2: Deep Dive Mode
**Ask:** "Explain mutex in detail with code"

**Expected:**
```
[Full structured answer with code example, explanation, and complexity]
```

### Test 3: Mode Switch
**Ask:** "What is a channel?"
**Then:** "Show me code for that"

**Expected:**
- First answer: Short interview-style
- Second answer: Detailed with code

---

## ✅ Benefits

### For You:
- ✅ Quick answers during live interviews
- ✅ Easy to read and speak naturally
- ✅ No overwhelming information
- ✅ Sounds professional and confident

### For Learning:
- ✅ Can still get detailed explanations when needed
- ✅ Code examples available on demand
- ✅ Flexible based on your needs
- ✅ Best of both worlds

---

## 🔧 Customization

If you want to adjust the behavior:

1. **Make Interview Mode even shorter**: Edit the "2-4 sentences" rule to "1-2 sentences"
2. **Add more trigger phrases**: Add to the "DEEP DIVE MODE DETECTION" section
3. **Change default mode**: Swap the detection logic (not recommended)

---

## 📞 Support

If the AI doesn't switch modes correctly:
1. Use explicit trigger phrases ("explain in detail", "show code")
2. Rephrase your question to match the mode triggers
3. Check if your question is clear and specific

---

## 🎉 Summary

You now have an intelligent AI assistant that:
- Gives **short, speakable answers** for quick questions (perfect for interviews)
- Gives **detailed, code-heavy answers** when you need to learn deeply
- **Automatically detects** which mode to use
- **Switches seamlessly** based on your phrasing

Perfect for acing technical interviews while still having access to deep learning when you need it! 🚀
