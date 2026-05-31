---
title: Preference Tuning - RLHF and DPO
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 21: Fine-Tuning & Model Adaptation"
tags:
  - fine-tuning
  - rlhf
  - dpo
  - alignment
  - foundations
related:
  - "[[02 - How Fine-Tuning Works]]"
  - "[[03 - PEFT - LoRA and QLoRA]]"
---

# Preference Tuning - RLHF and DPO

> [!NOTE]
> **TL;DR**
> Supervised fine-tuning (note 02) teaches a model to imitate "good" answers, but it can't easily teach **preferences** — that answer A is *better* than answer B when both are plausible. That's the job of **alignment / preference tuning**, the step that turns a raw instruction-following model into a helpful, harmless chat model. The classic method is **RLHF (Reinforcement Learning from Human Feedback)**: collect human rankings of outputs → train a **reward model** to predict preferences → use RL (PPO) to optimize the LLM against that reward. It works but is **complex and unstable**. **DPO (Direct Preference Optimization)** is the modern simplification: skip the separate reward model and RL loop entirely, and train directly on **preference pairs** (chosen vs rejected) with a simple classification-style loss. DPO gets similar results with far less complexity, which is why it's now widely used.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 21** — the **alignment** stage from the lifecycle in [[02 - How Fine-Tuning Works]]. Mostly conceptual: app builders rarely run RLHF, but understanding it explains *why* chat models behave as they do.

---

## 1. Why SFT isn't enough

SFT trains the model to **reproduce** ideal responses. But "ideal" is often a **comparison**, not a single target:

```
Question: "Explain recursion."
Answer A: clear, concise, correct        ← humans prefer this
Answer B: correct but rambling and dense
```

Both A and B are valid completions, so SFT can't express "prefer A's *style*." Capturing **relative preference** — helpfulness, tone, harmlessness, honesty — needs a different signal: human **comparisons**.

---

## 2. RLHF — the classic three-stage pipeline

```
1. SFT          start from an instruction-tuned model (note 02)
        ▼
2. REWARD MODEL collect human rankings: given a prompt, humans rank outputs
                (A > B > C). Train a model to PREDICT this preference → a "reward".
        ▼
3. RL (PPO)     optimize the LLM to maximize the reward model's score,
                with a constraint (KL penalty) so it doesn't drift too far from SFT.
```

> [!IMPORTANT]
> **RLHF is how ChatGPT-style models got "helpful"**
> The leap from a raw text-completion model to a genuinely helpful, well-mannered assistant came largely from RLHF — aligning the model to **human preferences** rather than just imitation. It's the third lifecycle stage (alignment) that makes a model pleasant and safe to talk to.

The downside: three models in play (policy, reward, reference), an RL loop (PPO) that's **finicky and unstable**, lots of moving parts and compute.

---

## 3. DPO — direct preference optimization

DPO's insight: you don't actually need a separate reward model and an RL loop. You can optimize the LLM **directly** on preference data with a simple loss.

```
data: (prompt, CHOSEN response, REJECTED response)   ← human-preferred vs not
DPO loss: increase the model's relative likelihood of CHOSEN over REJECTED
          (with a reference model to anchor, preventing drift)
```

| | RLHF | DPO |
|---|---|---|
| Reward model | separate, trained | **none** (implicit) |
| RL loop (PPO) | yes (unstable) | **no** — plain supervised-style training |
| Complexity | high | **low** |
| Data | rankings | **preference pairs** (chosen/rejected) |
| Stability | finicky | much more stable |

> [!TIP]
> **DPO made preference tuning accessible**
> By collapsing the reward-model + RL stages into one straightforward training step on chosen/rejected pairs, DPO gives RLHF-like results with a fraction of the complexity. It's the default modern approach for preference tuning, and it composes with **LoRA** (note 03) so it can run cheaply.

---

## 4. Where preference data comes from

```
prompt → generate 2+ responses → humans (or an AI judge) pick the better → (chosen, rejected) pair
```

- **Human labelers** rank/choose — high quality, expensive.
- **AI feedback (RLAIF)** — an LLM judge (§17) provides the preference instead of humans — cheaper, scalable, increasingly common.
- Existing preference datasets exist for general alignment.

---

## 5. Do app builders do this?

> [!NOTE]
> **Mostly conceptual for app builders — but worth knowing**
> Running RLHF/DPO is usually the **model provider's** job; building on top of GPT/Claude, you inherit their alignment. You'd reach for DPO yourself only for **specialized behavior tuning** on an open model (e.g. enforce a very specific style/safety profile) — and then DPO + LoRA is the practical combo. The main value of knowing this: it explains *why* base ("foundation") models behave differently from instruction/chat models, and what "aligned" actually means.

Related techniques worth a mention: **Constitutional AI / RLAIF** (use AI feedback guided by a set of principles instead of pure human labels), and **ORPO/KTO** (further-simplified preference-tuning variants).

---

## 6. The full picture

```
PRE-TRAIN → SFT (imitate good answers) → PREFERENCE TUNE (RLHF or DPO: prefer better answers)
   base          instruct model                 chat / aligned model
            (notes 02, 03)                       (this note)
```

SFT teaches *what* a good answer looks like; preference tuning teaches *which* of two good answers is better — together they produce the assistants we use.

---

## 7. Main takeaways

- **SFT imitates** good answers; it can't express **relative preference** between valid answers.
- **Preference/alignment tuning** teaches "A is better than B" — the step that makes models helpful/harmless.
- **RLHF**: human rankings → **reward model** → **RL (PPO)** to optimize the LLM. Powerful but **complex/unstable**.
- RLHF is largely **why chat models feel helpful**.
- **DPO** skips the reward model + RL, training directly on **chosen/rejected pairs** — simpler, stabler, similar results.
- Preference data comes from **humans** or **AI judges (RLAIF)**.
- App builders rarely run this (you inherit the provider's alignment); DPO+LoRA is the route if you do.

---

## 8. Things I still want to figure out

- How much **preference data** does DPO need for a noticeable shift?
- RLAIF (AI feedback) vs human labels — quality gap in practice?
- How do ORPO/KTO differ from DPO, and when to pick them?

---

## 9. Things to dig into

- **InstructGPT / RLHF** paper (the original pipeline).
- **DPO** paper; **Constitutional AI** (Anthropic).
- Hugging Face **TRL** `DPOTrainer` (+ LoRA).
- Next: [[05 - Quantization]].

---

## 10. Next up in this section

- [ ] [[05 - Quantization]] — shrinking models to run/fine-tune them cheaply.

---

## Related
- [[02 - How Fine-Tuning Works]] — SFT, the stage before alignment.
- [[03 - PEFT - LoRA and QLoRA]] — DPO composes with LoRA.
- [[03 - LLM-as-a-Judge]] — the AI-feedback (RLAIF) source.

## Sources
- [InstructGPT / RLHF paper](https://arxiv.org/abs/2203.02155)
- [DPO paper](https://arxiv.org/abs/2305.18290)
