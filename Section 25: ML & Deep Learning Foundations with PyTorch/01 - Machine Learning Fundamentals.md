---
title: Machine Learning Fundamentals
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 25: ML & Deep Learning Foundations with PyTorch"
tags:
  - machine-learning
  - fundamentals
  - supervised-learning
  - foundations
related:
  - "[[02 - Neural Networks and Backpropagation]]"
  - "[[01 - What is an LLM]]"
---

# Machine Learning Fundamentals

> [!NOTE]
> **TL;DR**
> Everything I've used (LLMs, embeddings) sits on a base of **machine learning**: programs that **learn patterns from data** instead of being explicitly coded. The main paradigms: **supervised** (learn from labeled input→output examples — classification & regression), **unsupervised** (find structure in unlabeled data — clustering, dimensionality reduction; embeddings live here-ish), and **reinforcement** (learn from reward — the basis of RLHF, §21). The core workflow: split data into **train / validation / test**, fit a model to minimize a **loss** on training data, tune on validation, and report on the held-out test set. The central tension is **overfitting vs underfitting** (the bias-variance trade-off) — memorizing the training data vs failing to learn it. This is the conceptual bedrock under deep learning (note 02) and the transformer (§1).

> [!NOTE]
> **Where this fits**
> First note of **Section 25: ML & Deep Learning Foundations with PyTorch** — the "go beyond API-level into how models work" section. It grounds the LLM concepts from §1 in classic ML before building up to neural nets (note 02) and PyTorch (note 04).

---

## 1. What ML is

Traditional programming: a human writes **rules** (`if/else`) that map input → output. Machine learning **inverts** this — you give it **examples** (input + output) and it learns the rules (a **model**) itself.

```
traditional:  rules + input  → output      (human writes the rules)
ML:           input + output → rules/model (the machine learns the rules from data)
```

The LLM is an extreme case: nobody wrote rules for language — it learned them from text (§1).

---

## 2. The three paradigms

| Paradigm | Learns from | Goal | Examples |
|---|---|---|---|
| **Supervised** | **Labeled** data (input→output) | Predict the label for new input | classification, regression |
| **Unsupervised** | **Unlabeled** data | Find structure | clustering, dimensionality reduction, embeddings |
| **Reinforcement** | **Reward** signal from actions | Maximize cumulative reward | game playing, **RLHF** (§21) |

### Supervised — the workhorse
- **Classification**: predict a **category** (spam/not-spam, ticket label).
- **Regression**: predict a **number** (house price, temperature).

LLM next-token prediction is essentially **supervised** (predict the next token given the previous ones), self-supervised on raw text.

### Unsupervised
No labels — discover patterns. **Embeddings (§1/§8)** are related: representations learned so similar things are near each other.

### Reinforcement
Learn by trial and reward. **RLHF/DPO (§21)** aligns LLMs using preference signals — RL applied to language models.

---

## 3. The model-building workflow

```
data → split (train / validation / test)
     → train: fit model to MINIMIZE LOSS on the training set
     → validate: tune hyperparameters on the validation set
     → test: report final performance on the held-out test set (never trained on)
```

> [!IMPORTANT]
> **The train/val/test split is sacred**
> - **Train**: the model learns from this.
> - **Validation**: tune choices (hyperparameters, model size) — checked during development.
> - **Test**: touched **once**, at the end, to estimate real-world performance.
>
> If you evaluate on data the model trained on, you measure **memorization**, not **generalization**. This is exactly why the eval suites (§17) and fine-tuning workflows (§21) insist on **held-out** sets — it's the same principle.

---

## 4. Loss — the thing being minimized

A **loss function** measures how wrong the model's predictions are. Training = adjusting the model to **minimize loss** (more in note 03).

```
prediction vs truth → loss (a number; lower = better) → adjust model to reduce it
```

Examples: **cross-entropy** for classification (and next-token prediction in LLMs), **mean squared error** for regression.

---

## 5. Overfitting vs underfitting — the central tension

```
underfit ◄─────────────── just right ───────────────► overfit
too simple,              learns the pattern,          memorizes training data,
fails on train+test      generalizes to new data      fails on new (test) data
(high bias)                                            (high variance)
```

| | Underfitting | Overfitting |
|---|---|---|
| Symptom | Bad on **both** train & test | Great on **train**, bad on **test** |
| Cause | Model too simple / undertrained | Model too complex / overtrained / too little data |
| Fix | bigger model, train longer, better features | more data, regularization, simpler model, early stopping |

> [!TIP]
> **The gap between train and test performance is the key diagnostic**
> Train accuracy high but test accuracy low → **overfitting** (memorizing). Both low → **underfitting**. This same signal drives fine-tuning decisions (§21: watch train vs validation loss). Generalization — doing well on **unseen** data — is the whole goal; train performance alone is meaningless.

---

## 6. Features and data

- **Features**: the input variables. Classic ML needs **feature engineering** (hand-crafting inputs); **deep learning** (note 02) learns features automatically from raw data — a key reason it dominates for text/images.
- **Data quality + quantity** usually matters more than model cleverness (echoing the fine-tuning lesson, §21): garbage in, garbage out.

---

## 7. Main takeaways

- **ML learns rules from data** (vs humans writing rules).
- Paradigms: **supervised** (labeled → classify/regress), **unsupervised** (structure/embeddings), **reinforcement** (reward → RLHF, §21).
- **LLM next-token prediction** ≈ self-supervised; **RLHF** ≈ reinforcement.
- Workflow: **train / validation / test** split; minimize **loss**; report on **held-out test**.
- Never evaluate on training data — measure **generalization**, not memorization (same rule as eval §17 / FT §21).
- **Loss** measures wrongness (cross-entropy, MSE); training minimizes it (note 03).
- Central tension: **overfitting vs underfitting**; the **train-vs-test gap** is the diagnostic.
- **Deep learning learns features** automatically (note 02); data quality dominates.

---

## 8. Things I still want to figure out

- How big should validation/test splits be?
- Regularization techniques (dropout, weight decay) in detail — where they fit (note 02)?
- Where exactly do embeddings (§8) sit between supervised/unsupervised?

---

## 9. Things to dig into

- **scikit-learn** for classic ML hands-on (classification/regression).
- Bias-variance trade-off; cross-validation.
- Connect to: eval (§17), fine-tuning (§21).
- Next: [[02 - Neural Networks and Backpropagation]].

---

## 10. Next up in this section

- [ ] [[02 - Neural Networks and Backpropagation]] — how deep learning models actually learn.

---

## Related
- [[01 - What is an LLM]] — the ML system this grounds.
- [[01 - Why Evaluation Matters]] — train/test discipline applied to LLM apps.

## Sources
- [scikit-learn user guide](https://scikit-learn.org/stable/user_guide.html)
- [Google ML Crash Course](https://developers.google.com/machine-learning/crash-course)
