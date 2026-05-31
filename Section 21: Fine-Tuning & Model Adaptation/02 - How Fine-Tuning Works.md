---
title: How Fine-Tuning Works
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 21: Fine-Tuning & Model Adaptation"
tags:
  - fine-tuning
  - training
  - instruction-tuning
  - foundations
related:
  - "[[01 - Prompt vs RAG vs Fine-Tuning]]"
  - "[[03 - PEFT - LoRA and QLoRA]]"
---

# How Fine-Tuning Works

> [!NOTE]
> **TL;DR**
> Fine-tuning continues training a **pre-trained** model on a smaller, task-specific dataset, nudging its **weights** so it behaves the way the examples demonstrate. It uses the same machinery as pre-training — feed input, compare prediction to the desired output via a **loss**, backpropagate, update weights — just on far less data. This sits in the model lifecycle: **pre-training** (learn language from trillions of tokens, very expensive) → **fine-tuning / instruction tuning** (teach it to follow instructions and do tasks) → **alignment** (RLHF/DPO, make it helpful/safe — note 04). For app builders, the relevant kind is **supervised fine-tuning (SFT)**: a dataset of `(prompt, ideal_response)` pairs. The catch: full fine-tuning updates *all* weights — huge memory/compute — which is why **parameter-efficient** methods (LoRA, note 03) exist. Risks: **catastrophic forgetting** and **overfitting** on small data.

> [!NOTE]
> **Where this fits**
> Second note of **Section 21**, following the decision framework in [[01 - Prompt vs RAG vs Fine-Tuning]]. It explains the mechanism; [[03 - PEFT - LoRA and QLoRA]] makes it affordable, [[04 - Preference Tuning - RLHF and DPO]] covers alignment.

---

## 1. The model lifecycle

```
1. PRE-TRAINING      learn language on trillions of tokens (next-token prediction)
                     → a "base" model: knows language, not how to follow instructions
        ▼
2. FINE-TUNING /     train on (instruction → response) examples
   INSTRUCTION TUNE  → learns to follow instructions, do tasks (an "instruct" model)
        ▼
3. ALIGNMENT         RLHF / DPO on human preferences (note 04)
                     → helpful, harmless, honest (a "chat" model)
```

The ChatGPT/Claude-style models I use are the **end** of this pipeline. **Fine-tuning** is me adding a step 2/3 of my own on top of an existing model, with my data.

---

## 2. What training actually does

Fine-tuning reuses the core training loop (foundations in §25):

```
for each (prompt, ideal_response) example:
    prediction = model(prompt)
    loss = difference(prediction, ideal_response)   # how wrong was it?
    gradients = backprop(loss)                       # which weights to blame
    update weights in the direction that lowers loss
repeat over the dataset for a few epochs
```

> [!IMPORTANT]
> **Fine-tuning *adjusts* existing weights — it doesn't start from scratch**
> The model already knows language from pre-training. Fine-tuning makes **small adjustments** so its behavior shifts toward the examples. That's why it needs far less data than pre-training (thousands of examples, not trillions of tokens) — it's *steering*, not *teaching from zero*.

---

## 3. Supervised fine-tuning (SFT) — the app-builder kind

The practical form: a dataset of **prompt → ideal completion** pairs in the chat format.

```jsonl
{"messages": [{"role":"user","content":"Classify: 'refund my order'"},
              {"role":"assistant","content":"{\"category\":\"billing\"}"}]}
{"messages": [{"role":"user","content":"Classify: 'app keeps crashing'"},
              {"role":"assistant","content":"{\"category\":\"technical\"}"}]}
... (hundreds–thousands of examples)
```

The model learns to **reproduce the assistant responses** for that kind of prompt — internalizing the format, style, or task. This is what hosted fine-tuning APIs (OpenAI, etc.) accept.

---

## 4. Data quality is everything

> [!IMPORTANT]
> **Garbage in, garbage out — and small data amplifies it**
> Fine-tuning on a few thousand examples means each one carries weight. Quality, consistency, and coverage matter more than raw volume:
> - **Consistent** format/style across examples (the model learns the *pattern*).
> - **Representative** of real inputs (including edge cases).
> - **Clean** — a few bad examples can teach bad behavior.
> - **Enough** — too few → overfitting; the right amount depends on task complexity.
>
> Most fine-tuning success or failure is decided by the **dataset**, not the hyperparameters.

---

## 5. The cost problem with full fine-tuning

Full fine-tuning updates **every** weight in the model:

- Needs enough GPU memory to hold the model **+ gradients + optimizer state** — often several times the model size.
- For large models, that's many high-end GPUs — impractical for most.
- Produces a **full copy** of the model per task (storage heavy).

```
full fine-tune of a 7B+ model → tens of GB of GPU memory, a full new model per task
```

This expense is exactly why **parameter-efficient fine-tuning (PEFT)** — LoRA/QLoRA — was invented (note 03): train a tiny fraction of parameters instead.

---

## 6. The risks

| Risk | What happens | Mitigation |
|---|---|---|
| **Catastrophic forgetting** | Model loses general ability while learning the narrow task | Lower learning rate, fewer epochs, mix in general data, PEFT |
| **Overfitting** | Memorizes training data, fails on new inputs | More/varied data, fewer epochs, a validation set |
| **Distribution shift** | Training data ≠ real inputs → poor production behavior | Build the dataset from real traffic |
| **Cost/iteration speed** | Each experiment is slow/expensive | PEFT (note 03); start with prompting/RAG (note 01) |

Always hold out a **validation set** and **eval (§17)** before vs after — fine-tuning can easily make a model *worse*.

---

## 7. The shape of a hosted fine-tune

```python
# conceptual (OpenAI-style hosted fine-tuning)
# 1. prepare data.jsonl of {messages:[...]} pairs
# 2. upload + create a fine-tune job on a base model
# 3. wait for training; get a fine-tuned model id
# 4. use it like any model:
client.chat.completions.create(model="ft:base:org::id", messages=[...])
# 5. EVAL it (§17) vs the base + your prompt-only baseline before shipping
```

Hosted APIs hide the GPUs and run SFT (often LoRA under the hood) for you — the easiest on-ramp.

---

## 8. Main takeaways

- Fine-tuning = **continue training** a pre-trained model on task data → adjusts **weights**.
- Lifecycle: **pre-training → fine-tuning/instruction-tuning → alignment (RLHF/DPO)**.
- It **steers** existing knowledge (small data, few epochs), not teaches from scratch.
- App-builder form = **supervised fine-tuning (SFT)**: `(prompt, ideal_response)` pairs.
- **Data quality > quantity** — most outcomes are decided by the dataset.
- **Full fine-tuning is expensive** (all weights, big GPU memory, a model per task) → motivates PEFT (note 03).
- Risks: **catastrophic forgetting, overfitting, distribution shift** — hold out a val set, eval before/after.
- Hosted APIs make SFT easy (and often use LoRA internally).

---

## 9. Things I still want to figure out

- How many examples for a typical classification/format task?
- How to detect **catastrophic forgetting** quickly (eval design)?
- Hosted fine-tuning vs self-hosted LoRA — when each?

---

## 10. Things to dig into

- **OpenAI fine-tuning** data format + jobs.
- **Hugging Face SFT** (`trl` SFTTrainer) for self-hosted (§6).
- The training loop fundamentals → §25.
- Next: [[03 - PEFT - LoRA and QLoRA]].

---

## 11. Next up in this section

- [ ] [[03 - PEFT - LoRA and QLoRA]] — fine-tune affordably by training a tiny fraction of weights.

---

## Related
- [[01 - Prompt vs RAG vs Fine-Tuning]] — when to reach for this.
- [[05 - Coding our Own Tokenizer]] / §25 — the training mechanics underneath.

## Sources
- [OpenAI fine-tuning](https://platform.openai.com/docs/guides/fine-tuning)
- [Hugging Face TRL (SFT)](https://huggingface.co/docs/trl/)
