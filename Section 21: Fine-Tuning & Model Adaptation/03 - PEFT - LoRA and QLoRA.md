---
title: PEFT - LoRA and QLoRA
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 21: Fine-Tuning & Model Adaptation"
tags:
  - fine-tuning
  - peft
  - lora
  - qlora
  - efficiency
related:
  - "[[02 - How Fine-Tuning Works]]"
  - "[[05 - Quantization]]"
---

# PEFT - LoRA and QLoRA

> [!NOTE]
> **TL;DR**
> Full fine-tuning updates **all** of a model's weights — too much memory/compute for most people. **PEFT (Parameter-Efficient Fine-Tuning)** sidesteps this by **freezing the original weights** and training only a tiny set of new parameters. The dominant method is **LoRA (Low-Rank Adaptation)**: instead of updating a big weight matrix, it learns two small "low-rank" matrices whose product is added to it — training **~0.1–1%** of the parameters while matching much of full fine-tuning's quality. The frozen base is untouched, so the result is a small **adapter** file (megabytes, not gigabytes) you can swap per task. **QLoRA** goes further: **quantize** the frozen base model to 4-bit (note 05) so it fits in far less GPU memory, then train LoRA adapters on top — enabling fine-tuning of large models on a single consumer GPU. PEFT is what makes fine-tuning practical.

> [!NOTE]
> **Where this fits**
> Third note of **Section 21**, solving the cost problem raised in [[02 - How Fine-Tuning Works]]. QLoRA leans on quantization from [[05 - Quantization]].

---

## 1. The problem PEFT solves

Full fine-tuning (note 02) updates every weight → needs GPU memory for the model + gradients + optimizer state (several × model size), and produces a full model copy per task.

```
full fine-tune:  update ALL ~billions of params  → huge memory, GBs per task
PEFT:            freeze the base, train a tiny add-on → small memory, MBs per task
```

PEFT = **freeze the pre-trained weights; train only a small number of new parameters.**

---

## 2. LoRA — Low-Rank Adaptation

The key trick. A weight update during fine-tuning is itself a big matrix ΔW. LoRA's insight: that update is **low-rank** (its essential information lives in a much smaller space), so approximate it as the product of two **small** matrices:

```
ΔW  ≈  B · A      where A is (r × k) and B is (d × r),  r is tiny (e.g. 8, 16)

frozen W (d×k)  ──┐
                  ├─►  output = W·x  +  (B·A)·x
trainable A, B ───┘        (base, frozen)   (LoRA, trained)
```

- Only **A** and **B** are trained; the original **W** stays frozen.
- **r** (the "rank") is small, so A and B together have **far fewer** parameters than W.
- Result: train **~0.1–1%** of the parameters, often with quality close to full fine-tuning.

> [!IMPORTANT]
> **Why low rank works**
> Adapting a pre-trained model to a narrow task doesn't require rewriting its full knowledge — the *change* needed is small and structured (low-rank). LoRA captures that change cheaply. The base model's capabilities are preserved (it's frozen), which also reduces **catastrophic forgetting** (note 02).

---

## 3. Adapters — small, swappable, mergeable

Because only A/B are trained, the output is a tiny **adapter** (often a few MB):

```
one frozen base model
   ├── adapter: support-classifier   (MB)
   ├── adapter: sql-generator        (MB)
   └── adapter: brand-voice-writer   (MB)
```

- **Swap** adapters at runtime to switch tasks — no separate full models.
- **Merge** an adapter back into the base weights for zero inference overhead, if desired.
- **Store/share** cheaply (MBs vs GBs).

This is a huge operational win over full fine-tuning's one-model-per-task.

---

## 4. QLoRA — LoRA on a quantized base

QLoRA combines LoRA with **quantization** (note 05) to slash memory further:

```
1. QUANTIZE the frozen base model to 4-bit  → fits in much less GPU memory
2. Train LoRA adapters (in higher precision) on top of the frozen 4-bit base
```

> [!IMPORTANT]
> **QLoRA democratized fine-tuning**
> By holding the big frozen base in **4-bit** (note 05) and training only small LoRA adapters, QLoRA made it possible to fine-tune **large models on a single consumer/free-tier GPU** — something that previously needed a cluster. The base stays quantized/frozen; only the tiny adapters train. It's the technique behind most "fine-tune Llama on one GPU" tutorials.

| | Full FT | LoRA | QLoRA |
|---|---|---|---|
| Trainable params | 100% | ~0.1–1% | ~0.1–1% |
| Base weights | trained | frozen (full precision) | frozen (**4-bit**) |
| GPU memory | very high | medium | **low** |
| Output | full model | adapter (MB) | adapter (MB) |

---

## 5. Using PEFT (the ecosystem)

```python
# conceptual — Hugging Face PEFT + TRL
from peft import LoraConfig
from trl import SFTTrainer

lora = LoraConfig(r=16, lora_alpha=32, target_modules=["q_proj","v_proj"],
                  lora_dropout=0.05, task_type="CAUSAL_LM")

trainer = SFTTrainer(
    model=base_model,          # optionally loaded in 4-bit for QLoRA
    train_dataset=dataset,     # (prompt, response) pairs (note 02)
    peft_config=lora,
)
trainer.train()
trainer.save_model("./my-adapter")   # tiny adapter, not a full model
```

Key knobs: **r** (rank — capacity vs size), **lora_alpha** (scaling), **target_modules** (which layers get adapters, often attention projections), **dropout**. Hosted fine-tuning APIs run this kind of thing for you under the hood (note 02).

---

## 6. Trade-offs

| Pro | Con |
|---|---|
| Tiny memory + cheap to train | Slightly below full FT on the hardest adaptations |
| MB-sized, swappable adapters | One more concept (rank, target modules) to tune |
| Less catastrophic forgetting (base frozen) | QLoRA's 4-bit base can marginally affect quality |
| Fine-tune big models on modest hardware | Still needs a good dataset (note 02) + eval (§17) |

For the vast majority of fine-tuning, **LoRA/QLoRA is the default** — full fine-tuning is reserved for cases that genuinely need it.

---

## 7. Main takeaways

- **PEFT** freezes the base model and trains only a **tiny** set of new parameters.
- **LoRA** learns two small low-rank matrices (A, B) added to frozen weights — trains **~0.1–1%** of params.
- Low-rank works because task adaptation is a **small, structured change**; base stays frozen (less forgetting).
- Output = a tiny **adapter** (MBs): swappable per task, mergeable into the base.
- **QLoRA** = LoRA on a **4-bit quantized** frozen base → fine-tune **large models on one GPU**.
- Ecosystem: Hugging Face **PEFT** + **TRL**; hosted APIs use it internally.
- **LoRA/QLoRA is the practical default**; still needs good data + eval.

---

## 8. Things I still want to figure out

- How to choose **rank (r)** and **target_modules** for a task?
- How much does QLoRA's 4-bit base hurt quality vs LoRA in fp16?
- Serving multiple **adapters** efficiently (adapter hot-swapping)?

---

## 9. Things to dig into

- **LoRA** and **QLoRA** papers.
- Hugging Face **PEFT** + **TRL** docs.
- Quantization details → [[05 - Quantization]].
- Next: [[04 - Preference Tuning - RLHF and DPO]].

---

## 10. Next up in this section

- [ ] [[04 - Preference Tuning - RLHF and DPO]] — aligning a model to *preferred* behavior, beyond SFT.

---

## Related
- [[02 - How Fine-Tuning Works]] — the cost problem PEFT solves.
- [[05 - Quantization]] — the 4-bit base behind QLoRA.

## Sources
- [LoRA paper](https://arxiv.org/abs/2106.09685)
- [QLoRA paper](https://arxiv.org/abs/2305.14314)
- [Hugging Face PEFT](https://huggingface.co/docs/peft/)
