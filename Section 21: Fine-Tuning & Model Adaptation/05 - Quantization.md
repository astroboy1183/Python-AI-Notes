---
title: Quantization
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 21: Fine-Tuning & Model Adaptation"
tags:
  - quantization
  - efficiency
  - local-llm
  - gguf
  - inference
related:
  - "[[03 - PEFT - LoRA and QLoRA]]"
  - "[[01 - Why Run LLMs Locally]]"
---

# Quantization

> [!NOTE]
> **TL;DR**
> A model's weights are numbers; by default they're stored in 16- or 32-bit floating point. **Quantization** stores them in **fewer bits** (8-bit, 4-bit, even lower), shrinking the model **2–8×** in memory with only a small quality loss. That's what lets a model that needs an expensive GPU in full precision **run on a laptop or a single consumer GPU**. It's the technology behind running local LLMs (§5 Ollama) and behind **QLoRA** (note 03). Key terms: **precision** (FP32/FP16/INT8/INT4), **post-training quantization** (quantize an already-trained model — the common case), and formats/methods like **GGUF** (the llama.cpp format Ollama uses), **GPTQ**, and **AWQ**. The trade-off is always **size/speed vs quality** — lower bits = smaller/faster but more degradation; 4-bit is the popular sweet spot.

> [!NOTE]
> **Where this fits**
> Fifth note of **Section 21**. It underpins QLoRA from [[03 - PEFT - LoRA and QLoRA]] and explains how the local models in [[01 - Why Run LLMs Locally]] (§5) actually fit on consumer hardware.

---

## 1. What's being quantized

A model is billions of **weights** — just numbers. Their storage **precision** determines model size:

```
FP32 (32-bit float)  →  4 bytes/weight   (full precision, training default)
FP16 / BF16 (16-bit) →  2 bytes/weight   (common inference default)
INT8 (8-bit)         →  1 byte/weight    (~2× smaller than FP16)
INT4 (4-bit)         →  0.5 byte/weight  (~4× smaller than FP16)
```

A 7-billion-parameter model: ~14 GB at FP16, but **~3.5–4 GB at 4-bit** — the difference between "needs a serious GPU" and "runs on a laptop."

---

## 2. The core idea

Quantization **maps** high-precision values to a smaller set of low-precision ones (with a scale factor to preserve range):

```
FP16 weight 0.7193...  ──quantize──►  nearest 4-bit bucket  ──dequantize──►  ~0.72
                        (store the bucket index, not the full float)
```

Some information is lost (rounding), but neural nets are **robust to small weight perturbations**, so done well the quality drop is modest.

> [!IMPORTANT]
> **Why it barely hurts quality**
> LLMs have enormous redundancy and tolerate noise in individual weights. Reducing precision adds small rounding errors that mostly wash out across billions of weights. The cleverness in modern methods (GPTQ/AWQ) is choosing *how* to round to minimize the error that matters — which is why 4-bit can stay close to full precision.

---

## 3. When it happens: PTQ vs QAT

| | Post-Training Quantization (PTQ) | Quantization-Aware Training (QAT) |
|---|---|---|
| When | **After** training (just convert weights) | **During** training (model learns to be robust to it) |
| Effort | Low — the common case | High — needs retraining |
| Quality | Good (esp. with GPTQ/AWQ) | Best, but rarely worth it for LLMs |

For LLMs, **PTQ** dominates — you download or convert a model to 4/8-bit and run it.

---

## 4. Formats and methods

| Name | What it is | Used by |
|---|---|---|
| **GGUF** | File format for quantized models (successor to GGML) | **llama.cpp**, **Ollama** (§5), LM Studio |
| **GPTQ** | PTQ method, GPU-focused, layer-wise error minimization | GPU inference |
| **AWQ** | Activation-aware PTQ (protects important weights) | GPU inference |
| **bitsandbytes** | On-the-fly 8/4-bit loading in PyTorch | **QLoRA** (note 03), HF Transformers |

> [!TIP]
> **GGUF "Q" levels are quantization presets**
> When downloading a GGUF model you'll see tags like `Q4_K_M`, `Q5_K_M`, `Q8_0`. The number is roughly the bits; higher = larger + higher quality. `Q4_K_M` is a popular **balance** of size and quality. This is the knob behind picking a local model size in Ollama (§5).

---

## 5. The trade-off triangle

```
        quality
         /   \
   (more bits = better, bigger, slower to load)
       /         \
   size ───────── speed
   (fewer bits = smaller + often faster, but quality drops)
```

| Precision | Size | Quality | Use |
|---|---|---|---|
| FP16/BF16 | largest | reference | full-precision inference/training |
| INT8 | ~½ | near-full | safe quantization |
| **INT4** | ~¼ | slightly lower | **popular sweet spot** (local LLMs, QLoRA) |
| <4-bit | tiny | noticeable drop | extreme constraints |

Below ~4-bit, quality degradation usually outweighs the savings.

---

## 6. Two reasons it matters here

1. **Local/cheap inference (§5):** quantization is *why* Ollama can run capable models on a laptop. Pick a quant level to trade size vs quality for your hardware.
2. **QLoRA (note 03):** holding the frozen base in **4-bit** is what lets you *fine-tune* large models on one GPU — quantization + LoRA together.

```
quantization → run big models cheaply (inference)  AND  fine-tune big models cheaply (QLoRA)
```

---

## 7. Caveats

- **Measure quality after quantizing** (eval, §17) — degradation is task-dependent; some tasks tolerate 4-bit fine, others need 8-bit.
- **Speed isn't guaranteed faster** in every setup (depends on hardware/kernels) though memory always drops.
- **Very low bits** (2–3 bit) can break the model — diminishing returns.

---

## 8. Main takeaways

- **Quantization** stores weights in **fewer bits** (FP16 → INT8 → INT4), shrinking models **2–8×**.
- Small, tolerable quality loss because nets are **robust to weight noise**.
- **PTQ** (quantize after training) is the common case for LLMs.
- Formats/methods: **GGUF** (Ollama/llama.cpp), **GPTQ**, **AWQ**, **bitsandbytes** (QLoRA).
- GGUF **`Q4_K_M`**-style tags = quantization presets (higher = bigger/better); 4-bit is the sweet spot.
- Trade-off: **size/speed vs quality** — below ~4-bit usually isn't worth it.
- It's *why* **local LLMs run on laptops (§5)** and *how* **QLoRA fine-tunes big models on one GPU (note 03)**.
- **Eval after quantizing** — degradation is task-dependent.

---

## 9. Things I still want to figure out

- GPTQ vs AWQ vs GGUF quality at the same bit-width?
- Which tasks tolerate 4-bit vs need 8-bit?
- Does quantization actually speed up inference on my hardware?

---

## 10. Things to dig into

- **llama.cpp / GGUF** quant levels; **Ollama** model tags (§5).
- **GPTQ**, **AWQ**, **bitsandbytes** docs.
- Quantize → then **eval** (§17).
- Next: [[06 - Practical Fine-Tuning Workflow]].

---

## 11. Next up in this section

- [ ] [[06 - Practical Fine-Tuning Workflow]] — putting data, training, and eval together end to end.

---

## Related
- [[03 - PEFT - LoRA and QLoRA]] — QLoRA's 4-bit base.
- [[01 - Why Run LLMs Locally]] — quantization makes local LLMs feasible.

## Sources
- [llama.cpp / GGUF](https://github.com/ggerganov/llama.cpp)
- [GPTQ paper](https://arxiv.org/abs/2210.17323) · [AWQ paper](https://arxiv.org/abs/2306.00978)
