---
title: Practical Fine-Tuning Workflow
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 21: Fine-Tuning & Model Adaptation"
tags:
  - fine-tuning
  - workflow
  - data
  - evaluation
  - hands-on
related:
  - "[[02 - How Fine-Tuning Works]]"
  - "[[03 - PEFT - LoRA and QLoRA]]"
  - "[[01 - Why Evaluation Matters]]"
---

# Practical Fine-Tuning Workflow

> [!NOTE]
> **TL;DR**
> Fine-tuning is **90% data and evaluation, 10% training**. The end-to-end loop: **(1) confirm you should fine-tune** (prompt+RAG insufficient, per §21.01) and set a target metric; **(2) build a dataset** of high-quality `(prompt, ideal_response)` pairs from real traffic, split into train/validation; **(3) pick an approach** — hosted API (easy) or self-hosted **LoRA/QLoRA** (control); **(4) train**, watching training/validation loss for overfitting; **(5) evaluate** the fine-tuned model against the base + prompt-only baseline on a held-out set (§17) — *this is the gate*; **(6) iterate** on data (the highest-leverage fix), not hyperparameters; **(7) deploy + monitor** (§24), feeding production failures back into the dataset. The recurring lesson: dataset quality dominates outcomes, and **without eval you can't tell if fine-tuning helped or hurt.**

> [!NOTE]
> **Where this fits**
> Final note of **Section 21**, tying together [[02 - How Fine-Tuning Works]] (mechanism), [[03 - PEFT - LoRA and QLoRA]] (efficient method), and evaluation (§17) into one workflow. It's the "how do I actually do this" capstone.

---

## 1. The end-to-end loop

```
1. DECIDE      → should I fine-tune at all? (prompt+RAG first, §21.01) + define target metric
2. DATA        → build (prompt, ideal_response) pairs; train/val split
3. APPROACH    → hosted API  OR  self-hosted LoRA/QLoRA
4. TRAIN       → watch train vs val loss (overfitting)
5. EVALUATE    → vs base + prompt-only baseline on held-out set (§17)  ← the GATE
6. ITERATE     → fix the DATA (not hyperparams) and repeat
7. DEPLOY      → ship, monitor (§24), feed failures back into the dataset
```

---

## 2. Step 1 — decide (don't skip)

Before spending effort: have I exhausted **prompting** and **RAG** (§21.01)? Is the gap **behavior/format/consistency/cost** (fine-tunable) rather than **missing knowledge** (RAG's job)? Define the **metric** I want to move and the baseline (prompt-only) score. If I can't measure it, I can't fine-tune toward it.

---

## 3. Step 2 — the dataset (where it's won or lost)

> [!IMPORTANT]
> **Dataset quality beats everything**
> From [[02 - How Fine-Tuning Works]]: with a few thousand examples, each one teaches. Priorities:
> - **Source from real traffic** — so training distribution matches production.
> - **Consistency** — same format/style across examples (the model learns the pattern).
> - **Coverage** — include edge cases and the variety of real inputs.
> - **Clean** — remove wrong/contradictory examples; they teach wrong behavior.
> - **Hold out a validation set** — never train on what you evaluate with.

```jsonl
{"messages": [{"role":"system","content":"You are a ticket classifier."},
              {"role":"user","content":"App crashes on login"},
              {"role":"assistant","content":"{\"label\":\"technical\",\"priority\":\"high\"}"}]}
```

Aim for consistency the model can latch onto; quantity matters less than quality and coverage.

---

## 4. Step 3 — choose an approach

| Approach | When | Notes |
|---|---|---|
| **Hosted fine-tuning** (OpenAI etc.) | Want easy, managed, no GPUs | Upload JSONL → train → get a model id. Runs LoRA-style under the hood |
| **Self-hosted LoRA/QLoRA** (HF PEFT/TRL) | Want control, open model, on-prem, cost | Run on your GPU (QLoRA fits big models on one GPU, §21.03/05) |

Start hosted for a quick signal; go self-hosted when you need control, privacy (§19), or to deploy an open model.

---

## 5. Step 4 — train and watch for overfitting

```
train loss ↓ and val loss ↓        → learning well
train loss ↓ but val loss ↑        → OVERFITTING (memorizing) — stop, fewer epochs / more data
```

Key knobs: **epochs** (too many → overfit/forget), **learning rate** (too high → instability/forgetting), and for LoRA: **rank r**, **target_modules** (§21.03). Default to **few epochs** and a low learning rate; fine-tuning *steers*, it shouldn't overwrite.

---

## 6. Step 5 — evaluate (the gate)

> [!IMPORTANT]
> **Eval decides ship / no-ship — fine-tuning can make a model worse**
> Run the fine-tuned model on a **held-out** set and compare against:
> 1. the **base model + your best prompt** (the baseline to beat), and
> 2. the base model alone.
>
> Use the metrics from §17 (functional checks, LLM-judge, task accuracy). Also check it **didn't regress** on general ability (catastrophic forgetting, §21.02). If it doesn't clearly beat the prompt-only baseline, **don't ship it** — you've added cost/complexity for nothing.

```
fine-tuned > (base + good prompt) on the target metric AND no general regression → ship
otherwise → iterate or abandon
```

---

## 7. Step 6 — iterate on data, not knobs

> [!TIP]
> **When results disappoint, fix the dataset first**
> The instinct is to tweak hyperparameters; the leverage is almost always in the **data** — add examples for failure cases, fix inconsistent labels, improve coverage, clean noise. Hyperparameter tuning gives small gains; data quality gives big ones. Treat production failures (step 7) as new training examples.

---

## 8. Step 7 — deploy and monitor

- Deploy the model/adapter (hosted endpoint, or serve the adapter, §24).
- **Monitor** in production (§17): quality, drift, cost, latency.
- **Close the loop**: failures → eval set → next dataset → retrain. Models drift as inputs evolve; fine-tuning isn't one-and-done.

```
prod failures → add to dataset → retrain → re-eval → redeploy   (continuous)
```

---

## 9. Common pitfalls

> [!WARNING]
> **Fine-tuning gone wrong**

| Pitfall | Fix |
|---|---|
| Fine-tuning to add **knowledge** | Use RAG instead (§21.01) |
| Tiny/inconsistent dataset | More, cleaner, consistent examples |
| No validation set | Always hold one out |
| Too many epochs | Overfits/forgets — reduce |
| No baseline comparison | Compare vs prompt-only (§17) |
| Shipping without eval | Gate on held-out metrics |
| Train data ≠ production data | Source from real traffic |

---

## 10. Main takeaways

- Fine-tuning is **90% data + eval**, 10% training.
- Loop: **decide → data → approach → train → evaluate → iterate → deploy/monitor**.
- **Decide first**: prompt+RAG insufficient, and the gap is behavior (not knowledge).
- **Dataset quality dominates**: real traffic, consistent, covered, clean, with a val split.
- Approach: **hosted** (easy) or **self-hosted LoRA/QLoRA** (control).
- **Watch train vs val loss** for overfitting; prefer few epochs + low LR.
- **Evaluate vs the prompt-only baseline** — that's the **ship gate**; FT can make things worse.
- **Iterate on data, not hyperparameters**; feed production failures back in.
- **Monitor + retrain** — models drift.

---

## 11. Things I still want to figure out

- Minimum viable dataset size per task type?
- How to detect **forgetting** with a compact general-ability eval?
- Serving fine-tuned **adapters** at scale (§24)?

---

## 12. Things to dig into

- Hosted fine-tuning data prep (OpenAI JSONL).
- Hugging Face **TRL** `SFTTrainer` + **PEFT** end-to-end.
- Eval harness design (§17) for before/after comparison.

---

## 13. Section wrap-up

Section 21 covers **model adaptation**: when to fine-tune vs prompt/RAG (§21.01), how training works (§21.02), how to do it cheaply (**LoRA/QLoRA**, §21.03), how alignment works (**RLHF/DPO**, §21.04), how to shrink models (**quantization**, §21.05), and the **end-to-end workflow** gated by eval (this note). The throughline: adapt only when needed, let **data + evaluation** drive it.

---

## Related
- [[01 - Prompt vs RAG vs Fine-Tuning]] — the decide step.
- [[03 - PEFT - LoRA and QLoRA]] — the efficient training method.
- [[01 - Why Evaluation Matters]] — the gate.

## Sources
- [OpenAI fine-tuning best practices](https://platform.openai.com/docs/guides/fine-tuning)
- [Hugging Face TRL](https://huggingface.co/docs/trl/)
