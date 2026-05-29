---
title: Using the Transformers Package
date: 2026-05-28
source: "Section 6 / Lecture 5"
type: lecture-notes
status: in-progress
section: "Section 6: Running LLMs via Hugging Face Hub"
tags:
  - hugging-face
  - transformers
  - pipeline
  - python
  - pytorch
  - gemma
  - local-llm
  - chatml
  - hands-on
related:
  - "[[04 - Hugging Face CLI Setup and Login]]"
  - "[[03 - Accessing Gated Models]]"
  - "[[03 - ChatML Prompting]]"
  - "[[06 - Connecting FastAPI to Ollama]]"
---

# Using the Transformers Package

> [!NOTE]
> **TL;DR**
> Hugging Face's **`transformers`** Python library is the universal entry point to **any** Hub model. Install: `pip install transformers torch` (PyTorch is the most common backend). The simplest interface is the **`pipeline()`** function — pass `model=<repo_id>` and call it with ChatML-format `messages`. The library auto-handles tokenization, model loading, device placement (CPU/GPU/MPS), and decoding. First call downloads model weights (4 GB+ for Gemma 3) and caches them in `~/.cache/huggingface/hub/` — subsequent runs reuse the cache. **Heads-up**: running medium-sized models on CPU is **slow and heats the laptop fast** — on my machine I had to kill the inference run before it finished to keep the laptop from cooking.

> [!NOTE]
> **Where this fits**
> Fifth and final note of **Section 6: Running LLMs via Hugging Face Hub**. With auth in place ([[04 - Hugging Face CLI Setup and Login]]) and a gated model approved ([[03 - Accessing Gated Models]]), this step **actually downloads and runs** the model. Closes out Section 6. Next: **Section 7** — building AI agents with the foundations now in place.

---

## 1. What `transformers` does

The library that wraps almost every modern model architecture behind a single Python API:

| What it handles | Detail |
|---|---|
| **Downloading models** | From any HF repo, automatically cached |
| **Tokenization** | Picks the right tokenizer per model |
| **Model loading** | Handles weights, config, device placement |
| **Inference** | Forward passes, sampling, generation |
| **Backends** | PyTorch (most common), TensorFlow, JAX |
| **Device routing** | CPU, CUDA, MPS (Apple Silicon), TPU |
| **Quantization** | Built-in support for `bitsandbytes`, GPTQ, AWQ |
| **Multi-modal models** | Vision-language, audio, etc. |
| **Fine-tuning** | Via `Trainer` class |

For this note's scope — running a chat model — only **install + pipeline + call** matters.

---

## 2. Installation

```bash
pip install transformers
pip install torch
pip freeze > requirements.txt
```

Two packages:
- **`transformers`** — the HF library.
- **`torch`** — PyTorch, the inference backend. Required for most models.

The `transformers` install will also pull in supporting packages like NumPy on the way. After it's done, `pip freeze > requirements.txt` to lock the environment.

> [!NOTE]
> **`torch` is heavy**
> PyTorch is large (~800 MB download). On CPU-only setups it installs the CPU build; for GPU setups it pulls the CUDA-enabled build (~2 GB). Patience required on the first install.

---

## 3. Project setup

Create a new folder for this experiment:

```
hf_basic/
├── main.py
└── requirements.txt
```

I named the folder `hf_basic`.

---

## 4. The simplest usage — `pipeline()`

`pipeline()` is the highest-level entry point — abstracts almost everything:

```python
from transformers import pipeline

pipe = pipeline(
    "text-generation",                 # task type
    model="google/gemma-3-4b-it",      # repo_id on HF
)

messages = [
    {"role": "user", "content": "What animal is on the candy?"},
]

result = pipe(text=messages)
print(result)
```

That's it. Six lines for a working LLM call.

> [!NOTE]
> **What's going on in those six lines**
> `pipeline(...)` is essentially saying "I want to use this model" (the same one approved earlier via [[03 - Accessing Gated Models]]). The `messages` list is again the **ChatML** format — `{"role": "user", "content": "..."}` — the same pattern used everywhere else in the course.

---

## 5. What's happening under the hood

```
Python: pipe(text=messages)
            │
            ▼
   transformers library:
   1. Read 'messages' (ChatML format)
   2. Apply the model's chat template → raw prompt string
   3. Tokenize the prompt → tensor of token IDs
   4. Forward pass through the model
   5. Sample next tokens (autoregressive loop)
   6. Decode token IDs back to text
   7. Return as a Python dict
            │
            ▼
   result = [{
       "generated_text": [
           {"role": "user", "content": "..."},
           {"role": "assistant", "content": "<the reply>"},
       ]
   }]
```

The library handles all the pieces from Section 1 — tokenization, transformer forward passes, autoregressive sampling, detokenization — behind one call.

---

## 6. The `pipeline()` task types

The first argument controls behavior:

| Task | Purpose |
|---|---|
| `"text-generation"` | What this note uses — chat / completion |
| `"text-classification"` | Sentiment, topic, intent |
| `"token-classification"` | NER (named entity recognition) |
| `"question-answering"` | Extractive QA |
| `"summarization"` | Document → summary |
| `"translation"` | Source language → target |
| `"feature-extraction"` | Embeddings |
| `"image-classification"` | Vision classification |
| `"image-to-text"` | Captioning |
| `"automatic-speech-recognition"` | Speech-to-text |

For chat / instruction-following / completion, the right task is **`"text-generation"`**.

---

## 7. The first run — model download

The first time `pipeline()` runs with a new model:

1. **HF auth check** — uses the token from [[04 - Hugging Face CLI Setup and Login]].
2. **Download** model weights from HF Hub → `~/.cache/huggingface/hub/`.
3. **Load** weights into memory.
4. **Run** inference.

For Gemma 3 (4B parameters), this means downloading **~4–8 GB of weights** on the first call. Cached for next time. The first run is "wait while ~4 GB downloads + the machine heats up"; subsequent runs skip the download entirely.

---

## 8. The heat / slowness problem

Running a 4B-parameter model on CPU is **slow** (1–5 seconds per token) and **hot** (all cores pegged).

What actually happened on my machine:
- Download started fine.
- Model loaded.
- Inference began.
- Laptop fans spun up hard.
- I killed the run with Ctrl-C before getting a full result — CPU inference on a 4B model is just too much sustained load for this laptop.

The key takeaway: the first run downloads the model; from the next run onwards it's cached, no download needed, just inference time.

### Practical workarounds

| Approach | Detail |
|---|---|
| **Smaller model** | Use Gemma 1B or Phi-3-mini (~3 GB) instead of 4B |
| **Quantized model** | 4-bit Gemma is much smaller and faster (see GGUF / `bitsandbytes`) |
| **Use Ollama** | Section 5's approach — pre-quantized, optimized inference |
| **Use GPU** | If available, set `device=0` in `pipeline()` |
| **Use Apple MPS** | On M-series Macs: `device="mps"` |
| **Use HF Inference API** | Paid alternative — HF runs the model on their hardware |

> [!TIP]
> **For a hands-on demo without overheating**
> The simplest fix: pick a **1B-parameter** model like `microsoft/Phi-3-mini-4k-instruct` or `Qwen/Qwen2.5-1.5B-Instruct`. Both run reasonably fast on CPU and don't melt laptops.

---

## 9. The cache location

By default, models go to:

| OS | Path |
|---|---|
| **macOS / Linux** | `~/.cache/huggingface/hub/` |
| **Windows** | `%USERPROFILE%\.cache\huggingface\hub\` |

Inspect with:

```bash
huggingface-cli scan-cache
```

Output shows repos, sizes, and last-used times. Useful for tracking which models are eating disk space.

Free up space:

```bash
huggingface-cli delete-cache
```

Interactive prompt to delete specific repos.

> [!WARNING]
> **Models add up fast**
> A few mid-size models can eat 50+ GB of disk. **Quantized variants** (GGUF) take less, but still: regular cache cleanup is wise.

---

## 10. The full code

```python
# main.py
from transformers import pipeline

pipe = pipeline(
    "text-generation",
    model="google/gemma-3-4b-it",   # or any chat-tuned model
)

messages = [
    {"role": "user", "content": "What animal is on the candy?"},
]

result = pipe(text=messages)
print(result)
```

Run with:

```bash
python main.py
```

Expected timeline (first run):
- 30s – 5min: download model from HF Hub.
- 5–30s: load model into memory.
- 5–60s per response: inference (CPU only).
- Total first call: minutes.

Second call: just the inference time (~5–60s on CPU).

---

## 11. Useful extras

### Setting `device` explicitly

```python
pipe = pipeline(
    "text-generation",
    model="google/gemma-3-1b-it",
    device=0,         # GPU 0 (CUDA)
    # device="mps",   # Apple Silicon
    # device="cpu",   # CPU
)
```

### Generation parameters

```python
result = pipe(
    text=messages,
    max_new_tokens=200,         # cap reply length
    temperature=0.7,            # sampling temperature
    do_sample=True,             # sampling (vs greedy)
    top_p=0.95,                 # nucleus sampling
    return_full_text=False,     # only return generated text
)
```

### Loading the model + tokenizer separately (more control)

```python
from transformers import AutoTokenizer, AutoModelForCausalLM

model_id = "google/gemma-3-1b-it"
tokenizer = AutoTokenizer.from_pretrained(model_id)
model = AutoModelForCausalLM.from_pretrained(model_id, device_map="auto")

# Format messages using the model's chat template
inputs = tokenizer.apply_chat_template(
    [{"role": "user", "content": "Hello"}],
    return_tensors="pt",
    add_generation_prompt=True,
).to(model.device)

# Generate
outputs = model.generate(inputs, max_new_tokens=100)
print(tokenizer.decode(outputs[0], skip_special_tokens=True))
```

More verbose but unlocks full control over tokenization, sampling, batching, etc.

---

## 12. `transformers` vs Ollama — when to use which

At this point both options are available. When to pick which:

| Need | Use |
|---|---|
| Laptop chat with a few models | **Ollama** |
| Fine-tuning a model | **transformers** |
| Custom inference loop | **transformers** |
| OpenAI-compatible API | **Ollama** (built-in) |
| Bleeding-edge model just released | **transformers** (HF has it day-zero) |
| Production serving at high QPS | **vLLM** (built on transformers) |
| Embedding-only workload | **transformers** + `sentence-transformers` |
| Hot-swapping models | **Ollama** |
| Specific quantization (GGUF Q4) | **Ollama** or `llama.cpp` |
| Multi-modal (vision + text) | **transformers** |

Both tools draw from the same HF model registry; they're different consumption layers.

---

## 13. State after this step

| Component | Status |
|---|---|
| HF account | ✅ |
| Gated model approved | ✅ |
| HF CLI logged in | ✅ |
| `transformers` installed | ✅ |
| `torch` installed | ✅ |
| First model downloaded | ✅ (cached in `~/.cache/huggingface/hub/`) |
| Inference run | ✅ (with patience) |
| **Section 6 complete** | ✅ |

---

## 14. End of Section 6

This wraps up **Section 6: Running LLMs via Hugging Face Hub**:

| Note | Topic |
|---|---|
| 01 | Intro to Hugging Face |
| 02 | Setting up Hugging Face Account |
| 03 | Accessing Gated Models |
| 04 | Hugging Face CLI Setup and Login |
| 05 | Using the Transformers Package (this note) |

The local model stack is now **fully understood at two layers**:
- **Ollama** (Section 5): the easy curated layer.
- **Hugging Face + `transformers`** (Section 6): the raw, full-control layer.

Either path delivers the same outcome: an open-source model running locally, callable from Python.

**Next**: Section 7 — **Building AI Agents and Agentic Workflows**. The patterns from [[07 - Automating Chain of Thought]] (the loop) finally meet **tool calling** to produce agents that take actions in the world.

---

## 15. Main takeaways

- **`transformers`** is HF's universal Python entry point to any Hub model.
- Install: **`pip install transformers torch`**.
- Simplest API: **`pipeline(task, model=...)`** → call with `messages` in ChatML format.
- First run **downloads weights** to `~/.cache/huggingface/hub/` — slow but one-time per model.
- Subsequent runs reuse the cache.
- CPU-only inference is **slow and hot** for anything above ~2B parameters.
- **`device=0`** for CUDA GPU, **`device="mps"`** for Apple Silicon.
- For laptop demos, prefer **1B–3B parameter models** (Phi-3-mini, Qwen 2.5 1.5B, Gemma 1B).
- `huggingface-cli scan-cache` / `delete-cache` manage disk space.
- Lower-level APIs (`AutoTokenizer`, `AutoModelForCausalLM`) give full control for fine-tuning and custom serving.
- For most chat use cases: **Ollama is easier; `transformers` is more flexible**.

---

## 16. Things I still want to figure out

- What's the **right way** to do quantized inference with `transformers` on consumer hardware?
- How does `transformers` compare to **vLLM** for serving throughput?
- For Apple Silicon, what's the **best inference backend** — MPS via `transformers`, or `mlx`, or Ollama?
- How does **`device_map="auto"`** work for models bigger than VRAM?
- For fine-tuning a 1B-7B model on a single GPU, what's the recommended workflow (LoRA, QLoRA)?
- How does the **`pipeline()`** chat template handle multi-turn correctly?
- What's the inference cost difference between local CPU and HF Inference API for the same model?

---

## 17. Things to dig into

- **`transformers` docs**: https://huggingface.co/docs/transformers
- **`pipeline()` reference**: https://huggingface.co/docs/transformers/main_classes/pipelines
- **Chat templates guide**: https://huggingface.co/docs/transformers/main/en/chat_templating
- **Quantization guide**: https://huggingface.co/docs/transformers/main/en/quantization
- **vLLM**: https://github.com/vllm-project/vllm — production-grade serving on the same model weights.
- **Hands-on**: pick a 1B-parameter model, run a few prompts, compare reply quality with Ollama's `gemma:2b`.

---

## 18. Next up

End of Section 6. Next:

- [ ] **Section 7: Building AI Agents and Agentic Workflows** — combine LLM, tools, and the loop pattern from [[07 - Automating Chain of Thought]] into agents that *do* things.

---

## Related
- [[04 - Hugging Face CLI Setup and Login]] — the auth this step relies on.
- [[03 - Accessing Gated Models]] — the gate this download passes through.
- [[03 - ChatML Prompting]] — the message format used.
- [[06 - Connecting FastAPI to Ollama]] — the parallel pattern with Ollama.
- [[01 - Why Run LLMs Locally]] — section context.
- [[07 - Automating Chain of Thought]] — the loop pattern that will become an agent.

## Sources
- **`transformers` docs**: https://huggingface.co/docs/transformers
- **`pipeline()` reference**: https://huggingface.co/docs/transformers/main_classes/pipelines
- **Chat templates guide**: https://huggingface.co/docs/transformers/main/en/chat_templating
- **Quantization guide**: https://huggingface.co/docs/transformers/main/en/quantization
- **vLLM**: https://github.com/vllm-project/vllm
