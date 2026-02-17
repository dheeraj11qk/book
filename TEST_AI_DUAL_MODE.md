# Test Cases for AI Dual Mode System

## 🧪 How to Test

Copy each question below and paste it into your AI chat. Verify the response matches the expected format.

---

## ✅ Interview Mode Tests (Should be SHORT)

### Test 1: Basic Concept
**Question:** What is a Goroutine?

**Expected Format:**
- 2-4 sentences
- Numbered emoji (1️⃣)
- 1-2 keywords
- No code
- Natural speaking tone

**Expected Answer Style:**
```
1️⃣ A <keyword>goroutine</keyword> is a lightweight thread managed by the Go runtime. It allows us to run functions concurrently. Goroutines are much cheaper than OS threads, so we can easily run thousands of them.
```

---

### Test 2: Another Concept
**Question:** What is a Mutex?

**Expected Format:**
- 2-4 sentences
- Numbered emoji (1️⃣)
- 1-2 keywords
- No code

**Expected Answer Style:**
```
1️⃣ A <keyword>mutex</keyword> is used to protect shared data from concurrent access. It ensures only one goroutine can access the data at a time. This prevents race conditions.
```

---

### Test 3: Channel Concept
**Question:** Explain channels in Go

**Expected Format:**
- 2-4 sentences
- Numbered emoji (1️⃣)
- 1-2 keywords
- No code

**Expected Answer Style:**
```
1️⃣ A <keyword>channel</keyword> is used to communicate between goroutines. It helps share data safely without using locks. Channels follow the principle: don't share memory, share data through communication.
```

---

### Test 4: REST API
**Question:** What is REST API?

**Expected Format:**
- 2-4 sentences
- Numbered emoji (1️⃣)
- 1-2 keywords
- No code

---

### Test 5: Microservices
**Question:** Define microservices

**Expected Format:**
- 2-4 sentences
- Numbered emoji (1️⃣)
- 1-2 keywords
- No code

---

## 🔍 Deep Dive Mode Tests (Should be DETAILED)

### Test 6: Request Code
**Question:** Show me how to implement a goroutine with code

**Expected Format:**
- Full structured answer
- Code example included
- Detailed explanation
- 2-4 keywords
- Sections and bullet points

**Expected Answer Style:**
```
# Goroutine Implementation

[Definition with keywords]

**Code Example:**
```go
[Working code]
```

**Explanation:**
[How it works]

**Complexity:**
[Time/space analysis]
```

---

### Test 7: Detailed Explanation
**Question:** Explain mutex in detail

**Expected Format:**
- Full structured answer
- Code example included
- Detailed explanation
- Sections and bullet points

---

### Test 8: Implementation Request
**Question:** How do I implement a channel in Go?

**Expected Format:**
- Full structured answer
- Code example included
- Detailed explanation

---

### Test 9: Deep Dive Trigger
**Question:** Deep dive into goroutines

**Expected Format:**
- Full structured answer
- Code example included
- Detailed explanation

---

### Test 10: Elaborate Request
**Question:** Elaborate on REST API with examples

**Expected Format:**
- Full structured answer
- Code/examples included
- Detailed explanation

---

## 🔄 Mode Switching Tests

### Test 11: Interview → Deep Dive
**Step 1:** What is a channel?
**Expected:** Short answer (Interview Mode)

**Step 2:** Show me code for that
**Expected:** Detailed answer with code (Deep Dive Mode)

---

### Test 12: Deep Dive → Interview
**Step 1:** Explain goroutines in detail with code
**Expected:** Detailed answer (Deep Dive Mode)

**Step 2:** What is a mutex?
**Expected:** Short answer (Interview Mode)

---

## 📊 Verification Checklist

For each test, verify:

### Interview Mode Checklist:
- [ ] Answer is 2-4 sentences
- [ ] Uses numbered emoji (1️⃣)
- [ ] Has 1-2 keywords maximum
- [ ] No code blocks (unless explicitly asked)
- [ ] No markdown headers
- [ ] No bullet points (unless listing)
- [ ] Natural, speakable tone
- [ ] Sounds like something you'd say in an interview

### Deep Dive Mode Checklist:
- [ ] Answer is complete and thorough
- [ ] Includes code example
- [ ] Has structured sections
- [ ] Uses 2-4 keywords
- [ ] Includes complexity analysis (when relevant)
- [ ] Has bullet points and formatting
- [ ] Professional and detailed

---

## 🐛 Troubleshooting

### If Interview Mode gives too much detail:
- Check if question contains trigger words ("detail", "code", "implement")
- Rephrase to simple "What is X?" format
- Remove any words that might trigger Deep Dive Mode

### If Deep Dive Mode gives too little detail:
- Add explicit trigger: "explain in detail"
- Add "show me code" or "give me an example"
- Use "how to implement" phrasing

### If mode doesn't switch:
- Use explicit trigger phrases
- Make sure question is clear
- Try rephrasing the question

---

## 🎯 Success Criteria

The system is working correctly if:

1. ✅ Simple "What is X?" questions get 2-4 sentence answers
2. ✅ "Show code" or "explain in detail" gets full structured answers
3. ✅ Interview Mode answers are easy to speak naturally
4. ✅ Deep Dive Mode answers include code and complexity
5. ✅ Mode switches correctly based on phrasing

---

## 📝 Notes

- Test with your actual interview questions
- Practice reading Interview Mode answers out loud
- Verify they sound natural and confident
- Make sure you can speak them without sounding like you're reading documentation

---

## 🚀 Next Steps

After testing:
1. Use Interview Mode for live interview prep
2. Use Deep Dive Mode for learning and practice
3. Adjust rules if needed based on your preferences
4. Share feedback on what works best for you

---

## ✅ Quick Test Commands

Copy and paste these rapid-fire tests:

```
What is a Goroutine?
What is a Mutex?
What is a Channel?
Explain REST API
Define microservices
What is Docker?
What is Kubernetes?
Explain database indexing
What is a hash table?
Define binary search tree
```

All should give short, speakable answers!

Then test Deep Dive:

```
Show me how to implement a goroutine
Explain mutex in detail with code
How do I implement channels in Go?
Deep dive into REST API
Elaborate on microservices with examples
```

All should give detailed, structured answers with code!
