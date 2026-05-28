---
title: Using OpenAI API in Python
date: 2026-05-28
source: "Section 2 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 2: API Setup & Integration"
tags:
  - openai
  - api
  - python
  - sdk
  - python-dotenv
  - environment-variables
  - chat-completions
  - hands-on
  - foundations
related:
  - "[[01 - What is an LLM]]"
  - "[[05 - Coding our Own Tokenizer]]"
  - "[[01 - Setting up OpenAI Account]]"
---

# Using OpenAI API in Python

> [!abstract] TL;DR
> First real LLM API call from code. Workflow:
> 1. `pip install openai python-dotenv` → official OpenAI SDK + a helper for loading env files.
> 2. Create a `.env` file: `OPENAI_API_KEY=sk-...`.
> 3. In Python: `load_dotenv()` → `client = OpenAI()` → `client.chat.completions.create(model=..., messages=[...])`.
> 4. Extract the reply with `response.choices[0].message.content`.
>
> Messages are structured as a list of `{"role": "user"/"assistant"/"system", "content": "..."}` dictionaries — this is the **chat completion** format that's now the industry-standard interface to LLMs. The first run reveals a common gotcha: if `.env` isn't actually loaded, the client throws an authentication error. Adding `load_dotenv()` before constructing the client fixes it.

> [!info] Where this fits
> Second note of **Section 2: API Setup & Integration**. Follows [[01 - Setting up OpenAI Account]] (which got the API key created). This is where **real LLM calls happen from real code** for the first time — every later section builds on this foundation. The `messages` list + `chat.completions.create` pattern shows up everywhere downstream (agents, RAG, memory).

---

## 1. The plan

1. Reference the official **OpenAI Python SDK** quickstart docs.
2. Install the `openai` package via pip.
3. Set up an isolated **virtual environment**.
4. Store the API key in a **`.env` file** (never hardcoded).
5. Load the env file with **`python-dotenv`**.
6. Make a `chat.completions.create` call.
7. Extract the reply from the response object.

---

## 2. Project setup

Starting from an existing Python project (with `venv` already created and activated, as set up in [[05 - Coding our Own Tokenizer]]):

```bash
# Activate the venv (if not already)
source venv/bin/activate

# Install the OpenAI SDK
pip install openai

# Freeze dependencies
pip freeze > requirements.txt
```

After this, `requirements.txt` contains `openai==<version>` plus its transitive deps (`httpx`, `pydantic`, etc.).

### Create the project folder

```bash
mkdir hello_world
cd hello_world
touch main.py
```

> [!tip] Project structure so far
> ```
> Python-AI-Course/
> ├── venv/
> ├── requirements.txt
> ├── 01_tokenization/        ← from Section 1 / Note 5
> │   └── main.py
> └── hello_world/
>     ├── main.py             ← this note
>     └── .env                ← API key (NEVER commit)
> ```

---

## 3. Storing the API key — the `.env` file

Inside `hello_world/`, create a file named exactly `.env`:

```env
OPENAI_API_KEY=sk-...your-actual-key-here...
```

Key things:

| Rule | Why |
|---|---|
| Filename is **exactly** `.env` (with the leading dot) | This is what `python-dotenv` looks for by default. |
| Variable name is **exactly** `OPENAI_API_KEY` | The OpenAI SDK auto-reads this env var by convention. |
| **No quotes** around the value | `python-dotenv` handles raw values cleanly. |
| **No spaces** around `=` | Some shells will choke. |
| **Add `.env` to `.gitignore`** | Otherwise the key gets committed and leaked. |

> [!warning] Always gitignore `.env`
> In the project's `.gitignore`:
> ```
> .env
> .env.*
> venv/
> __pycache__/
> ```
> If the key already got committed at any point, **revoke it** ([[01 - Setting up OpenAI Account]]) and generate a new one.

---

## 4. The minimal code — first call

`hello_world/main.py`:

```python
from openai import OpenAI

client = OpenAI()

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "user", "content": "hey there"}
    ],
)

print(response.choices[0].message.content)
```

That's the entire program — about 9 lines. But the very first run will likely **fail** with this error:

```
OpenAIError: The api_key client option must be set either
by passing api_key to the client or by setting the
OPENAI_API_KEY environment variable.
```

Why? Because Python doesn't automatically read `.env` files. The next step fixes that.

---

## 5. Loading the `.env` file — `python-dotenv`

```bash
pip install python-dotenv
pip freeze > requirements.txt
```

Updated `main.py`:

```python
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()   # <-- reads .env into os.environ

client = OpenAI()   # auto-picks up OPENAI_API_KEY from env

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "user", "content": "hey there"}
    ],
)

print(response.choices[0].message.content)
```

The only changes:
1. `from dotenv import load_dotenv` (new import).
2. `load_dotenv()` called **before** instantiating `OpenAI()`.

Now running:

```bash
python main.py
```

Should produce something like:

```
Hello! How can I assist you today?
```

The `load_dotenv()` function is responsible for reading the `.env` file and loading its contents into the environment. After that single addition, the retry works cleanly.

---

## 6. Anatomy of the call

### The function signature

```python
client.chat.completions.create(
    model=...,        # which LLM
    messages=[...],   # the conversation so far
    ...               # many other optional params
)
```

### Available models (commonly used)

| Model | Strengths | Use when |
|---|---|---|
| `gpt-4o` | High quality, multimodal | Default for serious tasks |
| `gpt-4o-mini` | ~16× cheaper than 4o, still very good | Most experimentation, high-volume |
| `gpt-4.1` | Newer general-purpose | Latest features |
| `o1`, `o3-mini`, `o3` | Reasoning models | Math, complex multi-step problems |
| `gpt-3.5-turbo` | Older, cheap | Legacy fallback |

There are many LLM models available with different costs, pricing tiers, and capabilities — the table above is just the commonly-used subset.

### The `messages` format

This is the **chat-completions schema** — a list of structured dictionaries:

```python
messages = [
    {"role": "system",    "content": "You are a helpful assistant."},
    {"role": "user",      "content": "Hey, I am Jayanth."},
    {"role": "assistant", "content": "Nice to meet you, Jayanth!"},
    {"role": "user",      "content": "What's the weather like in Bangalore?"},
]
```

Three valid roles:

| Role | Who's "speaking" | Typical use |
|---|---|---|
| `system` | The application | Persona / instructions / constraints. |
| `user` | The end user | What the human typed. |
| `assistant` | The LLM (past responses) | Previous turns of conversation. |

A `tool` role also exists for function-calling responses (covered later in the course).

> [!info] Why this schema is standard
> The `messages` list with `role` + `content` is the **lingua franca** of modern LLM APIs:
> - OpenAI uses it (since 2023).
> - Anthropic Claude uses (almost) the same schema.
> - Gemini (via the OpenAI-compatible endpoint, [[04 - Using Gemini through OpenAI SDK]]) uses it.
> - Mistral, Together AI, Groq, OpenRouter — all use the same shape.
>
> Knowing this one schema unlocks ~90% of the LLM-API ecosystem.

---

## 7. Extracting the reply — `response.choices[0].message.content`

The full response object has more than just the text:

```python
response = client.chat.completions.create(...)

# response.choices is a list (usually with 1 element)
# response.choices[0].message is the assistant's reply
# response.choices[0].message.content is the actual text
```

Why `.choices[0]`? Because the API can return multiple completions in one call (with the `n` parameter). Default `n=1`, so it's always `[0]`.

### The full response object (illustrative)

```python
ChatCompletion(
    id="chatcmpl-...",
    object="chat.completion",
    created=1716910392,
    model="gpt-4o-2024-08-06",
    choices=[
        Choice(
            index=0,
            message=ChatCompletionMessage(
                role="assistant",
                content="Hello! How can I assist you today?",
                refusal=None,
                tool_calls=None,
            ),
            finish_reason="stop",
        )
    ],
    usage=CompletionUsage(
        prompt_tokens=10,
        completion_tokens=9,
        total_tokens=19,
    ),
)
```

> [!tip] Useful extras
> - `response.usage` → token counts. Use this to track cost per call.
> - `response.choices[0].finish_reason` → `"stop"`, `"length"`, `"content_filter"`, `"tool_calls"`. Tells *why* the model stopped generating.
> - `response.model` → confirms which model version actually served the request (useful when an alias like `gpt-4o` is used).

---

## 8. Two example runs

Two prompts worth walking through:

### Run 1
```python
messages=[{"role": "user", "content": "hey there"}]
```
Reply: *"Hello! How can I assist you today?"*

### Run 2
```python
messages=[{"role": "user", "content": "hey, I am Jayanth, nice to meet you."}]
```
Reply: *"Nice to meet you, Jayanth! How can I assist you today?"*

The model **incorporates the user-provided name** because it's in the input tokens — a tiny preview of how stateful conversations work (with full history, this is exactly [[01 - Short-Term Memory in LLMs|short-term memory]]).

---

## 9. Common gotchas

> [!warning] First-time problems

| Symptom | Likely cause | Fix |
|---|---|---|
| `OpenAIError: api_key must be set` | `.env` not loaded | Add `load_dotenv()` **before** `OpenAI()` |
| `No module named openai` | Wrong venv active | `source venv/bin/activate`, re-`pip install` |
| `RateLimitError: 429` | No credits added | [[01 - Setting up OpenAI Account]] — add $5 |
| `RateLimitError: 429` (with credits) | Too many requests/min | Throttle calls; check tier limits |
| `model_not_found` | Typo in model name or no access yet | Try `gpt-4o-mini`; some models need higher tiers |
| `AuthenticationError: Incorrect API key` | Key was revoked / typo | Generate new key, update `.env` |
| `.env` value picked up as literal `"sk-..."` (with quotes) | Quotes wrapped around the value | Remove quotes from `.env` |
| Output suddenly truncated mid-sentence | Hit `max_tokens` limit | Set higher `max_tokens=...` |

---

## 10. Useful extras

> [!example] Common parameters

```python
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": "You are a concise assistant."},
        {"role": "user", "content": "Explain transformers in one sentence."},
    ],
    temperature=0.7,        # 0.0 = deterministic, 1.0 = creative (typical default)
    max_tokens=200,         # cap on response length (cost ceiling)
    top_p=1.0,              # nucleus sampling threshold
    frequency_penalty=0.0,  # penalize repetitive tokens
    presence_penalty=0.0,   # penalize already-mentioned topics
    n=1,                    # how many alternative completions to generate
    stop=None,              # custom stop sequences
)
```

> [!example] Streaming responses

```python
stream = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Write a haiku about Bangalore."}],
    stream=True,
)

for chunk in stream:
    delta = chunk.choices[0].delta.content
    if delta:
        print(delta, end="", flush=True)
```

Streaming = print tokens as they're generated → snappier UX for chat apps.

> [!example] Multi-turn conversation

```python
messages = [{"role": "system", "content": "You are Jayanth's assistant."}]

while True:
    user_input = input("You: ")
    if not user_input:
        break

    messages.append({"role": "user", "content": user_input})

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages,
    )
    reply = response.choices[0].message.content

    print(f"Assistant: {reply}\n")
    messages.append({"role": "assistant", "content": reply})
```

That tiny script is the foundation of every chatbot. Notice: the **whole history** gets re-sent each turn. That's [[01 - Short-Term Memory in LLMs|short-term memory]] in action.

---

## 11. What's actually happening under the hood

Connecting back to Section 1 theory:

```
Python code:
    client.chat.completions.create(model="gpt-4o", messages=[...])
            │
            ▼
        HTTPS POST to api.openai.com/v1/chat/completions
            │
            ▼
        OpenAI servers:
            1. Tokenize the messages         ← [[04 - What is a Token]]
            2. Run through transformer       ← [[03 - The Transformer - Predicting the Next Token]]
            3. Generate output tokens (loop) ← [[09 - Multi-Head Attention]]
            4. Detokenize back to text
            │
            ▼
        JSON response
            │
            ▼
        Parsed by the SDK into a `ChatCompletion` object
            │
            ▼
        response.choices[0].message.content
```

The whole Section 1 theory stack is what's running **on the other end** of this API call.

---

## 12. Main takeaways

- **`pip install openai`** + **`pip install python-dotenv`** = the full client stack.
- API key goes in a `.env` file as `OPENAI_API_KEY=sk-...`. **Never hardcoded, never committed.**
- `load_dotenv()` reads the file into `os.environ` before instantiating the client.
- `client = OpenAI()` auto-picks up `OPENAI_API_KEY` from the env.
- `client.chat.completions.create(model=..., messages=[...])` is the standard call.
- `messages` is a list of `{"role": "system"/"user"/"assistant", "content": "..."}` dicts.
- Reply text lives at `response.choices[0].message.content`.
- `response.usage` shows token counts → useful for tracking cost.
- The same `messages` schema is used by Anthropic, Gemini-via-OpenAI-compat, Mistral, etc.
- Streaming responses (`stream=True`) deliver tokens as they're generated.
- Multi-turn conversation = append each turn to the `messages` list and re-send.

---

## 13. Things I still want to figure out

- What's the difference between **chat completions** and the newer **Responses API**?
- How does **function calling** (`tools` parameter) work? When to use it vs structured output?
- What happens when the conversation history gets really long (close to context limit)?
- How do **JSON mode** and **structured outputs** work?
- What's the right way to handle **rate limits** in a production app (exponential backoff?)?
- How does **prompt caching** (newer feature) save money on repeated system prompts?
- Are there idiomatic patterns for handling **content moderation** flags?

---

## 14. Things to dig into

- **Official quickstart**: https://platform.openai.com/docs/quickstart
- **API reference**: https://platform.openai.com/docs/api-reference
- **`python-dotenv` docs**: https://github.com/theskumar/python-dotenv
- **OpenAI Cookbook**: https://cookbook.openai.com — recipes for common patterns.
- **Try in Playground first**: any prompt put into code should usually be tested in the Playground first to iterate faster.

---

## 15. Next up in this section

The next note sets up the **free Gemini alternative**, useful if avoiding any payment is preferable:

- [ ] [[03 - Setting up Gemini API - Free Alternative]] — Google AI Studio + `google-genai`.

Then a really nice architectural trick:

- [ ] [[04 - Using Gemini through OpenAI SDK]] — repoint the OpenAI SDK at Gemini's compatible endpoint so the **same code** works against either provider.

---

## Related
- [[01 - Setting up OpenAI Account]] — where the API key came from.
- [[04 - What is a Token]] — what `response.usage` counts.
- [[05 - Coding our Own Tokenizer]] — counting tokens **before** sending (cost estimation).
- [[01 - Short-Term Memory in LLMs]] — multi-turn conversation = sending the whole `messages` history each call.

## Sources
- OpenAI Python SDK quickstart: https://platform.openai.com/docs/quickstart
- OpenAI API reference: https://platform.openai.com/docs/api-reference
- `python-dotenv` repo: https://github.com/theskumar/python-dotenv
