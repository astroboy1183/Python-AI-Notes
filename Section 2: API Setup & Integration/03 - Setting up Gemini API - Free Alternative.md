---
title: Setting up Gemini API - Free Alternative
date: 2026-05-28
source: "Section 2 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 2: API Setup & Integration"
tags:
  - gemini
  - google
  - api
  - google-genai
  - ai-studio
  - python
  - free-tier
  - api-keys
  - foundations
  - hands-on
related:
  - "[[01 - What is an LLM]]"
  - "[[01 - Setting up OpenAI Account]]"
  - "[[02 - Using OpenAI API in Python]]"
---

# Setting up Gemini API — Free Alternative

> [!NOTE]
> **TL;DR**
> Google's **Gemini API** is a **free** alternative to OpenAI's paid API — useful when avoiding any out-of-pocket spend. Setup is faster than OpenAI's: visit **aistudio.google.com**, click "Get API key", generate a key (no billing setup, no credit card). In Python: `pip install google-genai` → `from google import genai` → `client = genai.Client(api_key=...)` → `client.models.generate_content(model="gemini-...", contents="...")`. Free as of now with no guarantees about the future. I'm using OpenAI as the primary API throughout these notes, but Gemini is a solid path for anyone unwilling to pay $5.

> [!NOTE]
> **Where this fits**
> Third note of **Section 2: API Setup & Integration**. Parallel to [[01 - Setting up OpenAI Account]] + [[02 - Using OpenAI API in Python]] — same outcome (talk to an LLM from Python), different provider. The next note ([[04 - Using Gemini through OpenAI SDK]]) shows a clever trick: use the **same OpenAI client code** to call Gemini via a compatibility layer.

> [!WARNING]
> **"Free" disclaimer**
> Gemini's API has a generous free tier as of now — but **this can change**. Google can introduce billing, change rate limits, or restrict models at any time. Treat "free" as "free for now."

---

## 1. The URL

> **aistudio.google.com**

Google's developer portal for Gemini (their LLM family). Sign in with a Google account.

It's separate from:
- `gemini.google.com` — the consumer chat UI (like ChatGPT).
- `vertexai.google.com` — Google Cloud's enterprise-grade ML platform.

For learning + small projects, **AI Studio** is the right entry point.

---

## 2. Getting an API key

Path: **AI Studio → Get API key → Create API key**

- Pick or create a Google Cloud project (AI Studio auto-creates one if needed).
- Click **Create API key**.
- The key is displayed → copy it.

No billing setup is required — the API key can just be created on the spot.

Crucial differences from OpenAI:

| Setup step | OpenAI | Gemini |
|---|---|---|
| Sign in | ✅ | ✅ |
| Add credit card | ✅ Required ($5 min) | ❌ Not required |
| Generate API key | ✅ | ✅ |
| Time to first key | ~3 mins (incl. payment) | ~30 seconds |

> [!WARNING]
> **Same security rules apply**
> Even though Gemini is free, the key is still **personal credentials**. Treat it the same way as the OpenAI key:
> - Store in `.env`.
> - Add `.env` to `.gitignore`.
> - Never commit, never share, never paste publicly.
> - Revoke any key shown on a screen share or accidentally exposed.

---

## 3. The Python package — `google-genai`

The official SDK is **`google-genai`**:

```bash
pip install google-genai
pip freeze > requirements.txt
```

> [!NOTE]
> This is the new package (released 2024). The older `google-generativeai` package is being phased out. Use `google-genai` for any new code.

Imports:

```python
from google import genai
```

---

## 4. The minimal code — first Gemini call

`gemini_hello.py`:

```python
from google import genai

client = genai.Client(api_key="AIzaSy...your-actual-key...")

response = client.models.generate_content(
    model="gemini-2.5-flash",   # or gemini-1.5-flash, gemini-1.5-pro, etc.
    contents="Explain how AI works in a few words.",
)

print(response.text)
```

Run it:

```bash
python gemini_hello.py
```

Output (illustrative):
```
AI learns patterns from data to make intelligent decisions.
```

> [!TIP]
> **Keep the key in `.env` instead**
> Hardcoding the key in source is fine for a 30-second test, but in real code:
> ```python
> import os
> from dotenv import load_dotenv
> from google import genai
>
> load_dotenv()
> client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
> ```
> Add to `.env`: `GEMINI_API_KEY=AIzaSy...`

---

## 5. Anatomy of the call

Compared to the OpenAI call ([[02 - Using OpenAI API in Python]]):

| Concept | OpenAI | Gemini |
|---|---|---|
| Client constructor | `OpenAI()` | `genai.Client(api_key=...)` |
| Call method | `client.chat.completions.create(...)` | `client.models.generate_content(...)` |
| Model param | `model="gpt-4o"` | `model="gemini-2.5-flash"` |
| Messages param | `messages=[{"role":..., "content":...}]` | `contents="..."` (string) or `contents=[...]` (structured) |
| Extract reply | `response.choices[0].message.content` | `response.text` |

The `model` parameter picks which model to use, `contents` carries the prompt, and `response.text` returns the reply — that's the whole flow.

For simple prompts, Gemini's API is **slightly more ergonomic** — `contents` accepts a plain string, and `response.text` is a direct attribute.

---

## 6. Common Gemini models

As of now:

| Model | Speed | Quality | Best for |
|---|---|---|---|
| `gemini-2.5-flash` | Fast | Good | General use, default pick |
| `gemini-2.5-pro` | Slower | Best | Complex reasoning |
| `gemini-1.5-flash` | Fast | Good | Long context (1M tokens) |
| `gemini-1.5-pro` | Slower | Better | Long context + quality |
| `gemini-2.0-flash` | Fast | Good | Multimodal |
| `gemini-2.0-flash-thinking-exp` | Slower | Reasoning | Experimental "thinking" model |

> [!NOTE]
> **Long context superpower**
> Gemini 1.5 Pro supports **up to 1 million tokens** of context — roughly 750k English words. Far beyond GPT-4o's 128k. Useful for entire codebases, long documents, or massive RAG inputs.

---

## 7. Multi-turn conversation in Gemini

For conversation history (analog of OpenAI's `messages` list), Gemini uses **chats** or structured `contents`:

```python
chat = client.chats.create(model="gemini-2.5-flash")

response = chat.send_message("Hi, I'm Jayanth.")
print(response.text)

response = chat.send_message("What's my name?")
print(response.text)   # should remember "Jayanth"
```

The `chat` object keeps the history server-side (or in the SDK's local state), so each `send_message` continues the conversation.

> [!NOTE]
> **Equivalent with structured `contents`**

```python
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        {"role": "user", "parts": [{"text": "Hi, I'm Jayanth."}]},
        {"role": "model", "parts": [{"text": "Nice to meet you, Jayanth!"}]},
        {"role": "user", "parts": [{"text": "What's my name?"}]},
    ],
)
print(response.text)
```

The shape (`role` + `parts`) is **slightly different** from OpenAI's `role` + `content`. This is exactly why the next note's OpenAI-compat trick is so useful — it removes the need to learn two shapes.

---

## 8. Pricing model — free tier vs paid

Gemini's free tier (as of now) typically includes:

| Limit | Free tier (illustrative — check Google's current docs) |
|---|---|
| Requests per minute | 15 RPM for Pro, much higher for Flash |
| Requests per day | 1,500 RPD for Pro, larger for Flash |
| Tokens per minute | 1M TPM |

When usage exceeds free-tier limits, Google asks to enable billing → switches to **paid tier** with much higher limits and per-token pricing.

> [!WARNING]
> **Implicit cost**
> Free tier means Google can **use your prompts/responses for training** their models by default. For sensitive data, enable billing or use Vertex AI (paid, doesn't train on your data).

---

## 9. Comparison cheat-sheet — OpenAI vs Gemini

| Dimension | OpenAI | Gemini |
|---|---|---|
| **Sign-up cost** | Credit card required ($5 min) | Free |
| **Default model** | `gpt-4o` | `gemini-2.5-flash` |
| **Max context window** | 128k tokens (GPT-4o) | 1M+ tokens (1.5 Pro) |
| **Python SDK** | `openai` | `google-genai` |
| **Client constructor** | `OpenAI()` | `genai.Client(api_key=...)` |
| **Call method** | `client.chat.completions.create(...)` | `client.models.generate_content(...)` |
| **Messages shape** | `[{"role":..., "content":...}]` | `contents="..."` or `[{"role":..., "parts": [...]}]` |
| **Reply extraction** | `response.choices[0].message.content` | `response.text` |
| **Native multimodal (images)** | ✅ in GPT-4o | ✅ in Gemini |
| **Streaming** | ✅ `stream=True` | ✅ `generate_content_stream(...)` |
| **Free tier** | ❌ | ✅ (for now) |
| **Trains on your data?** | ❌ (paid tier doesn't) | ✅ on free tier; ❌ on paid / Vertex |

---

## 10. My actual choice for these notes

The OpenAI API isn't free — each call charges money based on tokens used. Gemini is the obvious alternative. The decision I've made:

- The notes primarily use **OpenAI**.
- **Gemini** is the fallback for anyone not wanting to pay.
- The **next note** ([[04 - Using Gemini through OpenAI SDK]]) bridges these so the same code runs against either.

---

## 11. Common gotchas with Gemini

> [!WARNING]
> **First-time problems**

| Symptom | Likely cause | Fix |
|---|---|---|
| `API key not valid` | Typo / extra whitespace in `.env` | Re-copy the key exactly |
| Rate limit hit fast | Free tier RPM low for Pro models | Switch to `gemini-2.5-flash`, or enable billing |
| `No module named google.genai` | Installed wrong package | `pip install google-genai`, not `google-generativeai` |
| `model not found` | Old / wrong model name | Use `gemini-2.5-flash` or check current list |
| `permission denied` | Geographic restrictions | Some Gemini features are region-locked; try VPN to US |
| Different response shape than OpenAI | Different API design | Check `response.text`, not `response.choices[0]...` |

---

## 12. Main takeaways

- **Gemini** = Google's LLM family; their API is **free** (as of now).
- Setup at **aistudio.google.com** — no card required.
- Python SDK: **`google-genai`** (new) — not the older `google-generativeai`.
- Minimal code: `genai.Client(api_key=...)` → `client.models.generate_content(model=..., contents=...)` → `response.text`.
- Model names look like `gemini-2.5-flash`, `gemini-2.5-pro`, `gemini-1.5-pro` (1M-token context).
- API shape differs from OpenAI: `contents` instead of `messages`, `role`/`parts` instead of `role`/`content`, `response.text` instead of `response.choices[0].message.content`.
- Multi-turn via `client.chats.create(...)` then `chat.send_message(...)`.
- Free tier comes with the caveat that Google **may use prompts for training** unless on the paid tier / Vertex AI.
- Same security rules apply — `.env`, gitignore, revoke when exposed.

---

## 13. Things I still want to figure out

- What does Gemini's free tier limit look like in real numbers (current docs)?
- How does Gemini handle **system instructions** (analog of OpenAI's `system` role)?
- What's the format for **tool calling / function calling** in `google-genai`?
- How does Gemini's **safety filtering** work — what gets blocked by default?
- For really long context (1M tokens), what are best practices for **caching**?
- What's the difference between AI Studio's API and **Vertex AI's** Gemini endpoint?
- Can the same key be used across both AI Studio and Vertex, or are they separate?

---

## 14. Things to dig into

- **Quickstart**: https://ai.google.dev/gemini-api/docs/quickstart
- **Model list**: https://ai.google.dev/gemini-api/docs/models/gemini
- **Pricing & free tier**: https://ai.google.dev/pricing
- **`google-genai` repo**: https://github.com/googleapis/python-genai
- **Multimodal docs**: how to send images, audio, video as `contents`.
- **Vertex AI vs AI Studio**: when to pick which.

---

## 15. Next up in this section

The clever architectural payoff comes next: Google has built an **OpenAI-compatible endpoint** for Gemini. That means the OpenAI SDK can be used to call Gemini — with only **two lines changed** (api_key + base_url). Same code, two backends.

- [ ] [[04 - Using Gemini through OpenAI SDK]] — the compatibility-layer trick.

---

## Related
- [[01 - Setting up OpenAI Account]] — the paid alternative.
- [[02 - Using OpenAI API in Python]] — the API call this note mirrors with Gemini.
- [[01 - What is an LLM]] — Gemini is one of the major LLM families.

## Sources
- Gemini API quickstart: https://ai.google.dev/gemini-api/docs/quickstart
- Gemini model list: https://ai.google.dev/gemini-api/docs/models/gemini
- `google-genai` repo: https://github.com/googleapis/python-genai
