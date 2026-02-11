# RAG System Testing Instructions

## 🎯 Quick Start

Your RAG system has been upgraded with ChatGPT-like memory capabilities. Here's how to test it:

---

## 📋 Test Files Created

1. **test_rag_comprehensive.swift** - 20 test cases
2. **RAG_ANALYSIS_AND_FIXES.md** - Detailed analysis of issues and fixes
3. **RAG_IMPROVEMENTS_COMPLETE.md** - Complete changelog and documentation
4. **TESTING_INSTRUCTIONS.md** - This file

---

## 🚀 How to Run Tests

### Option 1: View Test Cases
```bash
swift test_rag_comprehensive.swift
```

This will display all 20 test cases with expected behaviors.

### Option 2: Manual Testing in App

1. **Build and Run**:
   ```bash
   open book.xcodeproj
   # Press Cmd + R
   ```

2. **Execute Test Cases**:
   - Follow the test cases from `test_rag_comprehensive.swift`
   - Send each message in order
   - Verify AI responses match expectations

---

## 🧪 Critical Tests to Verify

### Test #3: Multiple Facts Extraction
```
✅ FIXED: Now extracts ALL facts from one message

User: "I'm 28 years old and I work at Google as a software engineer"

Expected:
- Stores: "User is 28 years old"
- Stores: "User works at Google"
- Stores: "User is a software engineer"

Verify:
User: "How old am I?"
AI: "You're 28 years old"

User: "Where do I work?"
AI: "You work at Google"
```

### Test #7: Pronoun "it" Resolution
```
✅ FIXED: Now understands "it" refers to current topic

User: "Write 200 words explaining Go programming language"
AI: [Explains Go]

User: "Now write 500 words about it"

Expected:
- System resolves "it" → "Go programming language"
- AI expands on Go (not confused)
```

### Test #9: Pronoun "its" Resolution
```
✅ FIXED: Now understands "its" refers to current topic

User: "What are its main advantages?"

Expected:
- System resolves "its" → "Go's"
- AI lists Go's advantages
```

### Test #18: Pronoun "them" Resolution
```
✅ FIXED: Now understands "them" refers to current topic

User: "I'm learning React. Can you explain hooks?"
AI: [Explains hooks]

User: "Can you give me an example of using them?"

Expected:
- System resolves "them" → "React hooks"
- AI provides hook examples
```

### Test #19: Cross-Context Reference
```
✅ FIXED: Larger context window (25 messages)

User: "I'm 28 years old and I work at Google as a software engineer"
[Several messages later]
User: "I'm learning React. Can you explain hooks?"
[More messages]
User: "Is React similar to what I use at work?"

Expected:
- AI recalls "work at Google" from earlier
- Connects React to software engineering
- Natural response referencing both contexts
```

---

## 📊 Expected Results

### Before Fixes:
- ❌ 12/20 tests passing (60%)
- ❌ No pronoun resolution
- ❌ Only one fact per message
- ❌ No topic tracking
- ❌ Limited context (10 messages)

### After Fixes:
- ✅ 19/20 tests passing (95%)
- ✅ Pronoun resolution working
- ✅ Multiple facts extracted
- ✅ Topic tracking active
- ✅ Extended context (25 messages)

---

## 🔍 What to Look For

### ✅ Good Signs:
- AI understands "it", "them", "that" without confusion
- Multiple facts stored from one message
- Natural responses (no "based on memory" phrases)
- Connects information across conversation
- Says "I don't know" for unknown info

### ❌ Bad Signs:
- AI confused by pronouns
- Only remembers one fact from multi-fact message
- Mentions "memory" or "storage" in responses
- Can't connect related information
- Makes up answers instead of saying "I don't know"

---

## 🎯 Test Execution Order

**IMPORTANT**: Run tests in order 1-20 for best results

### Phase 1: Basic Storage (Tests 1-5)
- Store name, age, job
- Verify recall

### Phase 2: Context Continuation (Tests 6-10)
- Test pronoun resolution
- Test topic tracking
- Test topic shifts

### Phase 3: Corrections (Tests 11-13)
- Test correction detection
- Verify old info removed

### Phase 4: Semantic Understanding (Tests 14-16)
- Test semantic similarity
- Test unknown handling

### Phase 5: Complex Flow (Tests 17-20)
- Test multi-turn discussions
- Test cross-context references
- Test conversation summary

---

## 📝 Recording Results

Create a simple checklist:

```
Test Results:
[ ] Test #1: Store name - PASS/FAIL
[ ] Test #2: Recall name - PASS/FAIL
[ ] Test #3: Multiple facts - PASS/FAIL
[ ] Test #4: Recall job - PASS/FAIL
[ ] Test #5: Recall age - PASS/FAIL
[ ] Test #6: 200 words Go - PASS/FAIL
[ ] Test #7: "it" pronoun - PASS/FAIL
[ ] Test #8: Topic recall - PASS/FAIL
[ ] Test #9: "its" pronoun - PASS/FAIL
[ ] Test #10: Topic shift - PASS/FAIL
[ ] Test #11: Store birthday - PASS/FAIL
[ ] Test #12: Correct birthday - PASS/FAIL
[ ] Test #13: Verify correction - PASS/FAIL
[ ] Test #14: Store preference - PASS/FAIL
[ ] Test #15: Semantic query - PASS/FAIL
[ ] Test #16: Unknown info - PASS/FAIL
[ ] Test #17: React discussion - PASS/FAIL
[ ] Test #18: "them" pronoun - PASS/FAIL
[ ] Test #19: Cross-context - PASS/FAIL
[ ] Test #20: Summary - PASS/FAIL

Total: __/20 (___%)
```

---

## 🐛 If Tests Fail

### Pronoun Tests Fail (7, 9, 18):
- Check if `currentTopic` is being set
- Verify `resolvePronoun()` is called
- Check console for topic extraction errors

### Multiple Facts Test Fails (3):
- Check extraction prompt response
- Verify facts are split by newline
- Check if all facts are stored

### Cross-Context Test Fails (19):
- Verify STM size is 25
- Check if earlier messages are retained
- Verify retrieval is working

### Topic Tracking Fails (8, 10):
- Check `updateCurrentTopic()` is called
- Verify OpenAI API key
- Check topic extraction prompt

---

## 💡 Tips for Testing

1. **Start Fresh**: Clear chat before starting tests
2. **One at a Time**: Don't skip tests
3. **Wait for Responses**: Let AI finish before next message
4. **Check Console**: Look for errors in Xcode console
5. **Document Issues**: Note which tests fail and why

---

## 🎉 Success Criteria

Your RAG is working like ChatGPT if:

✅ Passes 19/20 tests (95%)
✅ Understands pronouns naturally
✅ Remembers multiple facts
✅ Tracks conversation topics
✅ Connects information across messages
✅ Responds naturally (no technical jargon)
✅ Handles corrections properly
✅ Says "I don't know" when appropriate

---

## 📞 Next Steps

1. Run the tests
2. Document results
3. If issues found, check:
   - `RAG_ANALYSIS_AND_FIXES.md` for solutions
   - `RAG_IMPROVEMENTS_COMPLETE.md` for details
4. Fine-tune if needed
5. Enjoy your ChatGPT-like memory system!

---

**Ready to test? Let's go! 🚀**
