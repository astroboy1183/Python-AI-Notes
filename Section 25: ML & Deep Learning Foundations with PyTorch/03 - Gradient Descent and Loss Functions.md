---
title: Gradient Descent and Loss Functions
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 25: ML & Deep Learning Foundations with PyTorch"
tags:
  - deep-learning
  - gradient-descent
  - loss
  - optimization
  - foundations
related:
  - "[[02 - Neural Networks and Backpropagation]]"
  - "[[04 - PyTorch Basics]]"
---

# Gradient Descent and Loss Functions

> [!NOTE]
> **TL;DR**
> Training a network means **minimizing a loss function** — and **gradient descent** is the algorithm that does it. The loss is a landscape over the weights; the **gradient** (from backprop, note 02) points in the direction of steepest *increase*, so we step the **opposite** way to go downhill toward lower loss. The **learning rate** controls step size — too big overshoots/diverges, too small crawls. In practice we don't use the whole dataset per step (too slow); we use **mini-batches** (**SGD** — stochastic gradient descent), and an **epoch** is one full pass over the data. Smarter optimizers like **Adam** adapt the step per-parameter and are the common default. The loss function depends on the task: **cross-entropy** for classification/next-token (LLMs), **MSE** for regression. This is the engine that trains everything from a toy net to a transformer (§1) to a fine-tune (§21).

> [!NOTE]
> **Where this fits**
> Third note of **Section 25**, detailing the "update" step from the training loop in [[02 - Neural Networks and Backpropagation]]. PyTorch wires this up automatically (note 04).

---

## 1. Training = minimizing loss

From note 01: the **loss** measures how wrong predictions are. Training searches for the **weights that minimize it**.

```
goal:  find weights W that make loss(W) as small as possible
```

Picture loss as a hilly **landscape** over the weight values; training is **walking downhill** to a valley (low loss).

---

## 2. Gradient descent — walking downhill

The **gradient** (∂loss/∂weights, computed by backprop, note 02) points in the direction the loss **increases** fastest. To **decrease** loss, step the **opposite** direction:

```
new_weight = old_weight − learning_rate × gradient
                          └── step downhill (negative gradient) ──┘
```

```
loss
 │   •  start (high loss)
 │    \
 │     \•  step
 │      \•   step
 │       \_•__ minimum (low loss)
 └──────────────► weight value
```

Repeat: compute gradient → step → repeat → loss falls toward a minimum.

---

## 3. Learning rate — the critical knob

> [!IMPORTANT]
> **Learning rate sets the step size — and it's easy to get wrong**
> - **Too large** → overshoot the minimum, bounce around, or **diverge** (loss explodes).
> - **Too small** → painfully slow training; may get stuck.
> - **Just right** → steady descent to a good minimum.
>
> The learning rate is often the **most important hyperparameter**. This is also why fine-tuning (§21) uses a **low** learning rate — to gently steer a pre-trained model without blowing away its knowledge (catastrophic forgetting).

```
too big:   loss ↗↘↗↘ (unstable / diverges)
too small: loss ↓ (very slowly)
good:      loss ↓↓↓ (steady)
```

Often paired with a **learning-rate schedule** (warm up, then decay) for stability.

---

## 4. Batches, SGD, and epochs

Computing the gradient over the **entire** dataset each step is accurate but slow. Instead:

| Term | Meaning |
|---|---|
| **Batch (full) GD** | Gradient over all data per step — accurate, slow |
| **SGD** (stochastic) | Gradient over one / a few examples — fast, noisy |
| **Mini-batch GD** | Gradient over a small **batch** (e.g. 32) — the practical default |
| **Epoch** | One full pass over the whole dataset |
| **Step / iteration** | One weight update (one batch) |

```
for epoch in range(num_epochs):        # passes over the data
    for batch in data:                 # mini-batches
        forward → loss → backward → update   (one step)
```

The **noise** from mini-batches actually helps — it can jostle the model out of poor minima.

---

## 5. Optimizers — smarter stepping

Plain SGD uses one global learning rate. Modern **optimizers** adapt the step intelligently:

| Optimizer | Idea |
|---|---|
| **SGD (+ momentum)** | Adds "velocity" to roll through small bumps |
| **Adam / AdamW** | **Adapts the learning rate per-parameter** using gradient history; the common **default** |

> [!TIP]
> **Default to Adam/AdamW**
> Adam combines momentum + per-parameter adaptive rates, making it robust and a strong default for most deep learning (and what most LLM training/fine-tuning uses). You'll pick an optimizer in one line in PyTorch (note 04). Start with AdamW and a modest learning rate.

---

## 6. Loss functions — match to the task

The loss encodes "what does wrong mean" for the task:

| Task | Loss | Notes |
|---|---|---|
| **Classification** | **Cross-entropy** | Penalizes confident wrong class predictions |
| **Next-token (LLM)** | Cross-entropy | LLMs predict a distribution over the vocab → cross-entropy (§1) |
| **Regression** | **Mean Squared Error (MSE)** | Penalizes squared distance from the target |
| Others | hinge, contrastive, etc. | task-specific |

> [!IMPORTANT]
> **LLM training is cross-entropy on next-token prediction**
> An LLM outputs a probability distribution over the vocabulary for the next token; cross-entropy measures how far that distribution is from the true next token. Minimizing it via gradient descent is **exactly** how LLMs (and your fine-tunes, §21) are trained. The "loss going down" you watch during fine-tuning (§21) is this number.

---

## 7. Local minima, saddle points, convergence

- The loss landscape is **non-convex** (many valleys) — gradient descent finds a **good** minimum, not provably the global one. In practice, good-enough minima abound for large nets.
- **Convergence**: loss flattens out → training is done (or learning rate too high to settle).
- Watch **training vs validation loss** (notes 01–02): val loss rising while train falls = overfitting → stop (early stopping).

---

## 8. The full picture (connecting notes 02–03)

```
forward (note 02) → LOSS (this note: cross-entropy/MSE)
                  → backprop (note 02): gradients = ∂loss/∂weights
                  → gradient descent (this note): weights −= lr × gradient (via Adam)
                  → repeat over mini-batches / epochs → loss ↓ → learned
```

Note 04 expresses this in PyTorch; note 05 runs it on a real example.

---

## 9. Main takeaways

- Training = **minimize the loss**; **gradient descent** is the algorithm.
- The **gradient** (backprop, note 02) points uphill → step the **opposite** way to lower loss.
- **Learning rate** = step size — too big diverges, too small crawls; the key hyperparameter (and why FT uses a low one, §21).
- Use **mini-batches** (**SGD**); an **epoch** = one full pass; a **step** = one batch update.
- **Optimizers**: SGD+momentum, **Adam/AdamW** (adaptive, the default).
- **Loss matches the task**: **cross-entropy** (classification / **LLM next-token**), **MSE** (regression).
- **LLM training = cross-entropy on next-token prediction** via gradient descent — the loss you watch when fine-tuning (§21).
- Landscapes are non-convex; aim for a **good** minimum; watch **train vs val loss** to stop.

---

## 10. Things I still want to figure out

- How to pick an initial learning rate (LR finder, schedules)?
- Adam vs SGD trade-offs for different tasks?
- Why mini-batch noise helps generalization?

---

## 11. Things to dig into

- Gradient descent visualizations; LR schedules (warmup/cosine).
- Cross-entropy vs MSE intuition.
- Implement it: [[04 - PyTorch Basics]] → [[05 - Training a Model in PyTorch]].

---

## 12. Next up in this section

- [ ] [[04 - PyTorch Basics]] — tensors, autograd, and `nn.Module`.

---

## Related
- [[02 - Neural Networks and Backpropagation]] — backprop produces the gradients used here.
- [[06 - Practical Fine-Tuning Workflow]] — the train/val loss you watch (§21).

## Sources
- [Gradient descent (Google ML Crash Course)](https://developers.google.com/machine-learning/crash-course/reducing-loss/gradient-descent)
- [Adam paper](https://arxiv.org/abs/1412.6980)
