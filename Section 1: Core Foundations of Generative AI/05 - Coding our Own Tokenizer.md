---
title: Coding our Own Tokenizer
date: 2026-05-28
source: "Section 1 / Lecture 5"
type: lecture-notes
status: in-progress
section: "Section 1: Core Foundations of Generative AI"
tags:
  - llm
  - tokens
  - tokenization
  - detokenization
  - tiktoken
  - python
  - openai
  - hands-on
  - virtualenv
  - foundations
related:
  - "[[01 - What is an LLM]]"
  - "[[02 - How LLMs Work - Decoding GPT]]"
  - "[[03 - The Transformer - Predicting the Next Token]]"
  - "[[04 - What is a Token]]"
---

# Coding our Own Tokenizer

> [!NOTE]
> **TL;DR**
> Hands-on note: build a working tokenizer in Python using OpenAI's open-source **`tiktoken`** library. Workflow:
> 1. `python -m venv venv` → create an isolated virtual environment.
> 2. `source venv/bin/activate` → activate it.
> 3. `pip install tiktoken` → install the tokenizer.
> 4. `pip freeze > requirements.txt` → save dependencies.
> 5. Use `tiktoken.encoding_for_model("gpt-4o")` to get the right tokenizer.
> 6. `encoder.encode(text)` → text → list of token IDs.
> 7. `encoder.decode(tokens)` → tokens → original text.
>
> By the end, there's working code that round-trips `"hey there, my name is Jayanth"` through `tiktoken` and gets back the original string.

> [!NOTE]
> **Where this fits**
> Fifth note of **Section 1: Core Foundations of Generative AI**. Builds on [[04 - What is a Token]] (the concept) by making it concrete: actual Python code that tokenizes and detokenizes text using the **same library OpenAI uses internally**. First hands-on code note in the course.

---

## 1. Why `tiktoken`

`tiktoken` is a package made by OpenAI that handles both tokenization and detokenization of text.

Key points:
- **Built by OpenAI** — same tokenizer their GPT models use.
- **Open source** (MIT licensed) — anyone can use it offline.
- **Fast** — written in Rust under the hood, with Python bindings.
- Supports **multiple tokenizer encodings**:
  - `cl100k_base` → GPT-3.5, GPT-4.
  - `o200k_base` → GPT-4o, o1, o3.
  - `p50k_base` → older Codex / GPT-3.
  - `r50k_base` (aka `gpt2`) → GPT-2.

Using `tiktoken` makes it possible to:
- Count tokens **before** sending a request (for cost / context-window calculations).
- Pre-process or trim text to fit limits.
- Inspect how a specific model "sees" any text.

---

## 2. Step 1 — Project setup

### Create the folder
```bash
mkdir 01_tokenization
cd 01_tokenization
```

### Create a `main.py` file
Just an empty `main.py` to start.

### Create a Python virtual environment
> [!NOTE]
> **Why a virtual environment?**
> A `venv` isolates this project's dependencies from system-wide Python. Without it, `pip install tiktoken` would install globally and could conflict with other projects. Always use `venv` (or another tool like `poetry`, `uv`, `pipenv`) for any non-trivial Python work.

```bash
python -m venv venv
```

This creates a `venv/` folder containing an isolated Python interpreter + `pip`.

### Activate the venv

```bash
# Linux / macOS
source venv/bin/activate

# Windows (PowerShell)
.\venv\Scripts\Activate.ps1
```

After activation, the terminal prompt usually shows `(venv)` as a prefix. Any `pip install` now goes into this venv, not system Python.

---

## 3. Step 2 — Install `tiktoken`

```bash
pip install tiktoken
```

Then freeze the dependency list:

```bash
pip freeze > requirements.txt
```

> [!TIP]
> **Why `pip freeze`?**
> `requirements.txt` documents the exact versions installed. Anyone (including future-you on another machine) can run `pip install -r requirements.txt` to reproduce the exact environment. **Always commit `requirements.txt` to git.**

The resulting `requirements.txt` will list `tiktoken==<version>` and its transitive dependencies (`regex`, `requests`, etc.).

---

## 4. Step 3 — Encode (text → tokens)

The full `main.py`:

```python
import tiktoken

# Get the tokenizer that matches a specific model
encoder = tiktoken.encoding_for_model("gpt-4o")

text = "hey there, my name is Jayanth"

tokens = encoder.encode(text)

print("tokens:", tokens)
```

### Walking through it

| Line | What it does |
|---|---|
| `import tiktoken` | Load the library. |
| `tiktoken.encoding_for_model("gpt-4o")` | Returns the **exact** tokenizer GPT-4o uses (`o200k_base`). |
| `encoder.encode(text)` | Converts the string into a list of integer token IDs. |
| `print(tokens, …)` | Just prints the result. |

### Running it

Two options:

```bash
# Option A — from the project folder
python main.py

# Option B — IDE play button (VS Code etc.)
```

Output looks something like:
```
tokens: [25216, 1354, 11, 856, 1308, 382, 96270, 320]
```

(Exact IDs depend on the model and library version.)

> [!NOTE]
> Each integer is a single token. The full string `"hey there, my name is Jayanth"` collapses to a handful of tokens — far fewer than the character count.

---

## 5. Step 4 — Decode (tokens → text)

Append to `main.py`:

```python
# Decode back to the original text
decoded = encoder.decode(tokens)

print("decoded:", decoded)
```

Output:
```
decoded: hey there, my name is Jayanth
```

> [!TIP]
> **Round-trip property**
> `decode(encode(text)) == text` — always. Tokenization is **lossless**: every encoded string can be recovered exactly. Confirms that `tiktoken` is doing a proper invertible mapping.

---

## 6. The full final `main.py`

```python
import tiktoken

# 1. Pick the tokenizer for the target model
encoder = tiktoken.encoding_for_model("gpt-4o")

# 2. Text to tokenize
text = "hey there, my name is Jayanth"

# 3. Encode: text → token IDs
tokens = encoder.encode(text)
print("tokens:", tokens)

# 4. Decode: token IDs → text
decoded = encoder.decode(tokens)
print("decoded:", decoded)
```

That's it — a complete tokenize/detokenize round-trip in ~10 lines.

---

## 7. What this code is doing inside an LLM pipeline

Connecting back to the bigger picture:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  User input:  "hey there, my name is Jayanth"                   │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────────────────┐                                   │
│  │  tiktoken.encode(...)    │  ← THIS CODE                      │
│  └──────────────────────────┘                                   │
│       │                                                         │
│       ▼                                                         │
│  Token IDs:  [25216, 1354, 11, 856, 1308, 382, 96270, 320]      │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────────────────┐                                   │
│  │   TRANSFORMER (GPT-4o)   │  ← network call                   │
│  │   predicts next tokens   │                                   │
│  └──────────────────────────┘                                   │
│       │                                                         │
│       ▼                                                         │
│  Predicted token IDs:  [..., ..., ...]                          │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────────────────┐                                   │
│  │  tiktoken.decode(...)    │  ← THIS CODE                      │
│  └──────────────────────────┘                                   │
│       │                                                         │
│       ▼                                                         │
│  Reply text:  "Hi Jayanth, nice to meet you!"                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

When using the OpenAI API directly, tiktoken-style tokenization happens **server-side** — the API accepts strings and returns strings, hiding the token IDs. But running it locally (as this note does) shows what's happening behind the curtain.

---

## 8. Useful extras

> [!NOTE]
> **Counting tokens for cost estimation**

```python
import tiktoken

encoder = tiktoken.encoding_for_model("gpt-4o")

prompt = "Write a poem about Bangalore in five lines."
token_count = len(encoder.encode(prompt))

# GPT-4o input pricing: ~$2.50 per million input tokens
cost_per_million = 2.50
estimated_cost = (token_count / 1_000_000) * cost_per_million

print(f"Tokens: {token_count}")
print(f"Estimated input cost: ${estimated_cost:.6f}")
```

> [!NOTE]
> **Using encoding directly**

```python
import tiktoken

# Use a specific encoding directly (independent of model name)
encoder = tiktoken.get_encoding("o200k_base")  # for GPT-4o
# or "cl100k_base" for GPT-3.5/4, "p50k_base" for Codex, etc.

tokens = encoder.encode("hello world")
```

> [!NOTE]
> **Inspecting individual tokens**

```python
import tiktoken

encoder = tiktoken.encoding_for_model("gpt-4o")
tokens = encoder.encode("hey there, my name is Jayanth")

# Decode each token individually to see what each integer represents
for token_id in tokens:
    decoded = encoder.decode([token_id])
    print(f"{token_id:>7} → {decoded!r}")
```

Output (illustrative):
```
  25216 → 'hey'
   1354 → ' there'
     11 → ','
    856 → ' my'
   1308 → ' name'
    382 → ' is'
  96270 → ' Jay'
    320 → 'anth'
```

Notice the **leading space** is part of most tokens (` there`, ` my`, etc.), and `Jayanth` splits into ` Jay` + `anth` — exactly the sub-word behavior covered in [[04 - What is a Token]].

---

## 9. Other tokenizers (for non-OpenAI models)

`tiktoken` only handles OpenAI's tokenizers. For other models:

| Model | Library / package |
|---|---|
| OpenAI (GPT-4, GPT-4o, etc.) | `tiktoken` |
| Anthropic Claude | `anthropic-tokenizer` (or use Anthropic's API token-count endpoint) |
| Google Gemini | Google's `vertexai` SDK / Gemini API token-count |
| Llama / Mistral / HuggingFace models | `transformers.AutoTokenizer.from_pretrained(...)` |
| BERT, GPT-2 family | `transformers` library |

> [!NOTE]
> For most multi-model work, the **`transformers`** library from Hugging Face is the lingua franca. It supports virtually any open-source model's tokenizer.

---

## 10. Main takeaways

- **`tiktoken`** is OpenAI's official open-source tokenizer for Python.
- Workflow: `venv` → `pip install tiktoken` → `pip freeze > requirements.txt`.
- API:
  - `tiktoken.encoding_for_model(model_name)` → get the right tokenizer.
  - `encoder.encode(text)` → list of token IDs.
  - `encoder.decode(tokens)` → original text.
- Round-trip is **lossless**: `decode(encode(x)) == x`.
- Each numeric ID corresponds to a sub-word chunk, often with a leading space.
- Useful for:
  - Pre-flight token counting (cost + context-limit checks).
  - Understanding how a model "sees" any specific text.
  - Trimming or chunking inputs intelligently.
- For non-OpenAI models, use the model's own tokenizer (e.g., HuggingFace `transformers`).

---

## 11. Things I still want to figure out

- How does `tiktoken` know the vocabulary mapping? Is it bundled with the package or downloaded?
- What's the difference between `encoding_for_model("gpt-4o")` and `get_encoding("o200k_base")` in practice?
- Are there edge cases where decoding produces slightly different text than the input?
- How does `tiktoken` handle Unicode normalization (e.g., NFC vs NFD)?
- What happens if you pass an obscure model name? Does it error or fall back?
- For exact server-side token counts on Claude / Gemini, what's the best client-side library?

---

## 12. Things to dig into

- **Repo**: https://github.com/openai/tiktoken — the official source, with usage docs.
- **Online tokenizers** (no install needed):
  - https://platform.openai.com/tokenizer — OpenAI's hosted version.
  - `tiktokenizer` web visualizer — graphical breakdown.
- **`transformers` library** for non-OpenAI models: https://huggingface.co/docs/transformers
- **Practical exercise**: tokenize the same paragraph with three different models (GPT-4o, Llama 3, BERT) and compare token counts — useful intuition for multi-model engineering.

---

## 13. Project files at the end of this note

```
01_tokenization/
├── venv/                      # virtual environment (don't commit)
├── main.py                    # the tokenize/decode script
└── requirements.txt           # frozen dependencies (tiktoken==…)
```

A typical `.gitignore` would exclude `venv/` and add `__pycache__/`.

---

## 14. Next up in this section

The next note goes back to theory — actually walking through the transformer architecture diagram from the Google paper:

- [ ] [[06 - Attention Is All You Need - Architecture Walkthrough]] — every box in the diagram, end-to-end.

After that:

- [ ] [[07 - Vector Embeddings]]
- [ ] [[08 - Positional Encoding]]
- [ ] [[09 - Multi-Head Attention]]

---

## Related
- [[01 - What is an LLM]]
- [[02 - How LLMs Work - Decoding GPT]]
- [[03 - The Transformer - Predicting the Next Token]]
- [[04 - What is a Token]] — the theory this code implements.

## Sources
- `tiktoken` repo — https://github.com/openai/tiktoken
- OpenAI tokenizer playground — https://platform.openai.com/tokenizer
- Hugging Face `transformers` library — https://huggingface.co/docs/transformers
