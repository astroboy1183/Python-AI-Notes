---
title: Using Gemini through OpenAI SDK
date: 2026-05-28
source: "Section 2 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 2: API Setup & Integration"
tags:
  - openai
  - gemini
  - sdk
  - python
  - compatibility-layer
  - base-url
  - api
  - foundations
  - hands-on
  - portability
related:
  - "[[01 - What is an LLM]]"
  - "[[02 - Using OpenAI API in Python]]"
  - "[[03 - Setting up Gemini API - Free Alternative]]"
---

# Using Gemini through OpenAI SDK

> [!NOTE]
> **TL;DR**
> Google's Gemini exposes an **OpenAI-compatible API endpoint**. That means the **same OpenAI Python SDK code** from [[02 - Using OpenAI API in Python]] can talk to Gemini with only **two parameters changed**: `api_key` (point at the Gemini key) and `base_url` (point at Google's compat URL). The third change is to use a Gemini model name (e.g., `gemini-2.5-flash` instead of `gpt-4o`). This compatibility layer means a single codebase can target either provider — useful for these notes (anyone can follow along whether they're paying for OpenAI or using free Gemini) and useful in production (provider lock-in is bad). I'm sticking with **OpenAI** as the primary, but this trick makes Gemini a drop-in alternative for ~99% of cases.

> [!NOTE]
> **Where this fits**
> Fourth and final note of **Section 2: API Setup & Integration**. Wraps up the foundations of "talking to an LLM from code." After this, the focus shifts to **prompt engineering, prompt serialization, local LLMs, agents, RAG**, etc. — all of which assume an LLM client is already wired up.

> [!WARNING]
> **Caveats**
> - **99% compatibility, not 100%**: some advanced features (specific tool-calling shapes, structured outputs, image inputs) may behave differently.
> - **Free tier may change**: Gemini's no-cost access is generous now but isn't guaranteed forever.
> - The compatibility layer is a **convenience**, not a magic universal adapter. For production-critical edges, test against both providers.

---

## 1. The problem this solves

Two API providers means two SDKs means two code paths:

| Without the compat layer | With the compat layer |
|---|---|
| `from openai import OpenAI` + chat-completions schema | Same code |
| OR `from google import genai` + `generate_content` schema | Same code |
| **Different model names, different param shapes, different response shapes** | Only model name + base URL change |

For anyone working through these notes: avoid maintaining two parallel codebases. For production: avoid provider lock-in.

The concern is real — if the OpenAI client is the default and someone wants to follow along with Gemini, the SDK usage and writing style are different. The fix: Gemini is now accessible from the OpenAI library directly, through a compatibility endpoint.

---

## 2. The trick — point OpenAI client at Gemini's compat URL

The standard OpenAI client call:

```python
from openai import OpenAI

client = OpenAI()    # uses api.openai.com by default

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "hello"}],
)
print(response.choices[0].message.content)
```

The Gemini-via-OpenAI version requires just three changes:

```python
from openai import OpenAI

client = OpenAI(
    api_key="AIzaSy...your-GEMINI-key...",                                # change 1: Gemini key
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/",  # change 2: Google's compat URL
)

response = client.chat.completions.create(
    model="gemini-2.5-flash",                                              # change 3: Gemini model name
    messages=[{"role": "user", "content": "hello"}],
)
print(response.choices[0].message.content)
```

Everything else — `messages` schema, response extraction, error handling — is **identical**.

---

## 3. The two parameters explained

### `api_key`
Overrides the default `OPENAI_API_KEY` environment variable. Passing the Gemini key directly here means the SDK authenticates against Google's endpoint with the Gemini key.

### `base_url`
The OpenAI SDK sends HTTP requests to `https://api.openai.com/v1/` by default. Setting `base_url` redirects those calls elsewhere — any server that **speaks the OpenAI protocol**.

| Target | `base_url` |
|---|---|
| OpenAI (default) | (omitted) → `https://api.openai.com/v1/` |
| **Gemini compat** | `https://generativelanguage.googleapis.com/v1beta/openai/` |
| Anthropic compat (via 3rd party) | `https://...some-proxy.../v1/` |
| Local LLM via Ollama | `http://localhost:11434/v1/` |
| Local LLM via vLLM | `http://localhost:8000/v1/` |
| OpenRouter (multi-provider aggregator) | `https://openrouter.ai/api/v1/` |
| Together AI | `https://api.together.xyz/v1/` |
| Groq | `https://api.groq.com/openai/v1/` |

> [!TIP]
> **The OpenAI protocol has become a de facto standard**
> Many providers ship "OpenAI-compatible" endpoints, partly because the chat-completions schema is widely understood, partly because client libraries already exist in every language. As of 2024+, "OpenAI-compatible" is the **lingua franca of LLM APIs**.

---

## 4. Changing the model name

Don't forget step 3 — the model parameter has to be a Gemini model name. Using `"gpt-4o"` against Gemini's endpoint produces:

```
openai.NotFoundError: Error code: 404 - {'error': ...}
```

That 404 is the classic "wrong model" mistake — easy to forget when only two of the three changes have been made. Swap `gpt-4o` for a Gemini model name and it works.

Common Gemini model names usable on the OpenAI-compat endpoint:

| Model | Notes |
|---|---|
| `gemini-2.5-flash` | Default fast model. Recommended for general use. |
| `gemini-2.5-pro` | Slower, higher quality. |
| `gemini-2.0-flash` | Good multimodal. |
| `gemini-1.5-flash` | 1M-token context. |
| `gemini-1.5-pro` | 1M-token context + higher quality. |

---

## 5. Full side-by-side comparison

### Pure OpenAI
```python
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

client = OpenAI()    # uses OPENAI_API_KEY from .env

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "user", "content": "Hey, I am Jayanth. Nice to meet you."}
    ],
)
print(response.choices[0].message.content)
```

### Same code, Gemini under the hood
```python
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

client = OpenAI(
    api_key=os.environ["GEMINI_API_KEY"],
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
)

response = client.chat.completions.create(
    model="gemini-2.5-flash",
    messages=[
        {"role": "user", "content": "Hey, I am Jayanth. Nice to meet you."}
    ],
)
print(response.choices[0].message.content)
```

> [!NOTE]
> **Output difference**
> The replies' wording differs (different model, different training data), but the **call shape, message shape, response shape — all identical**.
>
> Asking *"Who are you?"* through the Gemini-via-OpenAI path returns something like: *"I am a large language model trained by Google."* — confirming the calls actually reach Gemini's servers.

---

## 6. Architectural insight — abstracting the provider

Once `api_key` + `base_url` + `model` can be swapped, it's natural to make them configuration:

```python
# config.py
import os
from dotenv import load_dotenv

load_dotenv()

PROVIDER = os.environ.get("LLM_PROVIDER", "openai")

if PROVIDER == "openai":
    LLM_CONFIG = {
        "api_key": os.environ["OPENAI_API_KEY"],
        "base_url": None,    # default
        "model": "gpt-4o-mini",
    }
elif PROVIDER == "gemini":
    LLM_CONFIG = {
        "api_key": os.environ["GEMINI_API_KEY"],
        "base_url": "https://generativelanguage.googleapis.com/v1beta/openai/",
        "model": "gemini-2.5-flash",
    }
elif PROVIDER == "groq":
    LLM_CONFIG = {
        "api_key": os.environ["GROQ_API_KEY"],
        "base_url": "https://api.groq.com/openai/v1/",
        "model": "llama-3.1-70b-versatile",
    }
```

```python
# main.py
from openai import OpenAI
from config import LLM_CONFIG

client = OpenAI(
    api_key=LLM_CONFIG["api_key"],
    base_url=LLM_CONFIG["base_url"],
)

response = client.chat.completions.create(
    model=LLM_CONFIG["model"],
    messages=[...]
)
```

Flipping `LLM_PROVIDER=gemini` (or `groq`, etc.) in the environment changes the backend with zero code changes. This is the simplest possible **provider abstraction**.

> [!TIP]
> **Real-world benefit**
> In production, having a one-line switch between providers is huge:
> - **Cost optimization**: route cheap prompts to Gemini Flash, complex ones to GPT-4o.
> - **Fallback**: when one provider has an outage, switch over.
> - **A/B testing**: compare reply quality between models.
> - **Vendor leverage**: not locked into a single provider's pricing.

---

## 7. What doesn't carry over (the 1%)

The compatibility is **really good**, but a few edges to watch:

| Feature | Status |
|---|---|
| Basic chat completions | ✅ Works |
| System / user / assistant roles | ✅ Works |
| Streaming (`stream=True`) | ✅ Works |
| Temperature, max_tokens, top_p | ✅ Works |
| **Function calling / tools** | ⚠️ Shape may differ, especially for nested schemas |
| **JSON mode / structured outputs** | ⚠️ Behavior may vary; test thoroughly |
| **Image inputs (multimodal)** | ⚠️ Image-content format differs in some versions |
| **Audio inputs** | ⚠️ Not yet on Gemini's OpenAI-compat endpoint |
| **OpenAI-specific responses** (`logprobs`, `prediction`) | ❌ Won't work |
| **Embeddings** | ⚠️ Different endpoint paths |
| **Fine-tuning** | ❌ Provider-specific, never compatible |

For ~99% of cases this works when following along with Gemini against OpenAI-compat — but the remaining 1% is the kind of edge case that bites unexpectedly. Worth keeping in mind for anything beyond basic chat.

For everything in these notes' foundations (basic chat, streaming, common params), **the compat layer is fine**.

---

## 8. The bigger picture — OpenAI protocol as the universal API

This compatibility trick reveals an industry-wide pattern:

```
                ┌────────────────────────┐
                │   OpenAI client SDK    │
                │   (or LangChain, etc.) │
                └────────────┬───────────┘
                             │
                  HTTP requests in OpenAI's chat-completions shape
                             │
        ┌──────────┬─────────┼─────────┬──────────┬─────────┐
        ▼          ▼         ▼         ▼          ▼         ▼
   OpenAI's     Gemini    Anthropic   Groq    Together   Local
   actual       compat    compat              AI         (Ollama,
   endpoint     endpoint  (via proxy)                    vLLM)
```

> [!NOTE]
> **Why this matters**
> Knowing this pattern means **a single skill** (the OpenAI SDK) effectively unlocks the entire LLM API ecosystem. These notes lean into that for exactly that reason.

---

## 9. Common gotchas

> [!WARNING]
> **Issues to watch for**

| Symptom | Likely cause | Fix |
|---|---|---|
| `404 Model not found` | Still using `gpt-4o` against Gemini endpoint | Change to a Gemini model name |
| `401 Unauthorized` | Using OpenAI key against Gemini endpoint (or vice versa) | Use the matching `api_key` for the chosen `base_url` |
| `Invalid base URL` | Typo in URL — missing `/` at end | Use exactly: `https://generativelanguage.googleapis.com/v1beta/openai/` |
| Tool calling produces weird shapes | Schema differences between providers | Test the tool-calling code against both, normalize as needed |
| Streaming has different chunk format | Provider-specific token emission | Both work, just don't assume exact byte-equivalence |
| Latency differences | Different infrastructure | Expected — pick model based on speed/quality/cost trade-off |

---

## 10. Main takeaways

- Gemini exposes an **OpenAI-compatible API endpoint** — same protocol, different server.
- Using it from Python requires **three changes**:
  1. `api_key=...` (Gemini key)
  2. `base_url="https://generativelanguage.googleapis.com/v1beta/openai/"`
  3. `model="gemini-2.5-flash"` (or other Gemini model name)
- Everything else — `messages` schema, `response.choices[0].message.content`, streaming, common params — stays the same.
- The **OpenAI protocol** has become the de facto standard. Many providers (Groq, Together AI, OpenRouter, Ollama, vLLM, etc.) speak it too.
- Configuring `api_key` + `base_url` + `model` as environment variables enables **provider switching** with zero code changes.
- **99% compatible** — basic flows work; tool calling, structured outputs, multimodal may have edge cases.
- I'm using OpenAI as the primary; Gemini-via-OpenAI is a working fallback.

---

## 11. Things I still want to figure out

- How does **tool calling** behave specifically on Gemini's OpenAI-compat endpoint? Are there schema gotchas?
- Can **`response_format={"type": "json_object"}`** be used for structured JSON output on Gemini compat?
- Does the **`embeddings.create`** call also work via the compat endpoint?
- What's the latency / rate-limit difference between Gemini's native and OpenAI-compat endpoints?
- For local models (Ollama, vLLM), is the schema **exactly** OpenAI-compatible or are there subtle differences?
- Is there an **official spec** for the "OpenAI protocol" that other providers conform to?
- How do **token-counting / usage** stats compare across providers' compat endpoints?

---

## 12. Things to dig into

- **Gemini OpenAI-compat docs**: https://ai.google.dev/gemini-api/docs/openai
- **OpenRouter** — multi-provider gateway with one OpenAI-compatible URL: https://openrouter.ai
- **Groq** — ultra-fast Llama/Mixtral inference, OpenAI-compat: https://groq.com
- **Together AI** — open-model inference, OpenAI-compat: https://together.ai
- **Ollama** — run local models with an OpenAI-compatible endpoint: https://ollama.com
- **vLLM** — high-throughput local inference, OpenAI-compat: https://github.com/vllm-project/vllm

---

## 13. End of Section 2

This wraps up **Section 2: API Setup & Integration**. Section 2 covered:

| Note | Topic |
|---|---|
| 01 | Setting up OpenAI Account |
| 02 | Using OpenAI API in Python |
| 03 | Setting up Gemini API (Free Alternative) |
| 04 | Using Gemini through OpenAI SDK (this note) |

From here, a working LLM client is assumed to be wired up, and the focus turns to making it **useful**:

- [ ] **Section 3: Advanced Prompt Engineering Techniques** — getting better answers from the LLM.
- [ ] **Section 4: Prompt Serialization & Instruction Formats** — structured I/O.
- [ ] **Section 5: Local LLM Deployment & API Integration** — running models locally (the `base_url` trick from this lecture is exactly what plugs local LLMs in).
- [ ] **Section 6: Running LLMs via Hugging Face Hub**.

The compatibility insight from this note is the **bridge** to Section 5: local LLMs (Ollama, vLLM) ship the same OpenAI-compatible endpoint, so the same client code talks to them too.

---

## Related
- [[02 - Using OpenAI API in Python]] — the OpenAI version of the same call.
- [[03 - Setting up Gemini API - Free Alternative]] — the native Gemini SDK approach (alternative to this note).
- [[01 - What is an LLM]] — the family of providers this trick spans.

## Sources
- Gemini OpenAI-compat docs: https://ai.google.dev/gemini-api/docs/openai
- OpenRouter: https://openrouter.ai
- Groq: https://groq.com
- Together AI: https://together.ai
- Ollama: https://ollama.com
- vLLM: https://github.com/vllm-project/vllm
