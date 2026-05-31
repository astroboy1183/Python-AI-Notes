---
title: PyTorch Basics
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 25: ML & Deep Learning Foundations with PyTorch"
tags:
  - pytorch
  - deep-learning
  - tensors
  - autograd
  - hands-on
related:
  - "[[03 - Gradient Descent and Loss Functions]]"
  - "[[05 - Training a Model in PyTorch]]"
---

# PyTorch Basics

> [!NOTE]
> **TL;DR**
> **PyTorch** is the dominant framework for building and training neural nets (and what most LLM research/fine-tuning uses). Three pillars: **Tensors** — n-dimensional arrays (like NumPy) that can live on a **GPU** for speed; **Autograd** — automatic differentiation, so PyTorch computes **backpropagation gradients for you** (set `requires_grad=True`, call `loss.backward()`, and gradients appear); and **`nn.Module`** — the base class for models, where you define layers and a `forward()` method. The training loop you'll write maps 1:1 to notes 02–03: forward → loss → `loss.backward()` (backprop) → `optimizer.step()` (gradient descent) → `optimizer.zero_grad()`. The key mental model: PyTorch builds a **computation graph** as you run operations, then differentiates it automatically — you never hand-derive gradients. This note covers the primitives; note 05 runs a full training loop.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 25** — making the theory from notes 02–03 concrete in code. It connects to the Hugging Face `transformers` work (§6), which is built on PyTorch. Note 05 trains an actual model.

---

## 1. Why PyTorch

- **Pythonic + dynamic** — feels like normal Python; build/debug models imperatively.
- **Autograd** — automatic gradients (no manual calculus).
- **GPU acceleration** — move tensors/models to GPU with `.to(device)`.
- **Ecosystem** — Hugging Face `transformers` (§6), PEFT/LoRA (§21), most research run on it.

(The other major framework is TensorFlow/Keras; PyTorch dominates research and most LLM tooling.)

---

## 2. Tensors — the core data structure

A **tensor** is an n-dimensional array — the PyTorch equivalent of a NumPy array, but GPU-capable and autograd-aware.

```python
import torch

x = torch.tensor([[1.0, 2.0], [3.0, 4.0]])   # 2x2 tensor
x.shape          # torch.Size([2, 2])
x + 1            # elementwise
x @ x            # matrix multiply
x.to("cuda")     # move to GPU (if available)
```

Everything in a neural net — inputs, weights, activations, gradients — is a tensor. Shapes (dimensions) are what you spend most debugging time on.

```python
# device pattern (CPU/GPU portable)
device = "cuda" if torch.cuda.is_available() else "cpu"
x = x.to(device)
```

---

## 3. Autograd — automatic gradients

This is PyTorch's superpower. Mark tensors with `requires_grad=True`, do operations, and PyTorch **records a computation graph**. Call `.backward()` on the result and it computes gradients (backprop, note 02) automatically.

```python
w = torch.tensor(2.0, requires_grad=True)
loss = (w - 5) ** 2          # some function of w
loss.backward()              # autograd computes d(loss)/d(w)
print(w.grad)                # gradient = 2*(w-5) = -6.0  (computed for you)
```

> [!IMPORTANT]
> **Autograd = backprop, automated**
> You never hand-derive gradients (which would be hopeless for millions of weights). PyTorch builds the graph as operations run, then `loss.backward()` applies the chain rule backward through it (note 02) and stores each parameter's gradient in `.grad`. This is *the* reason frameworks exist — define the forward pass, get backprop for free.

---

## 4. `nn.Module` — defining a model

Models subclass `nn.Module`: declare layers in `__init__`, define the **forward pass** in `forward()`.

```python
import torch.nn as nn

class MLP(nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = nn.Linear(784, 128)   # layer: 784 inputs → 128
        self.fc2 = nn.Linear(128, 10)    # layer: 128 → 10 classes

    def forward(self, x):
        x = torch.relu(self.fc1(x))      # non-linear activation (note 02)
        return self.fc2(x)               # logits for 10 classes

model = MLP().to(device)
```

- `nn.Linear` = a fully-connected layer (the weighted sum + bias, note 02).
- `torch.relu` = the activation (note 02).
- `model.parameters()` = all learnable weights (what the optimizer updates).

This `MLP` is literally the layered network from note 02, in code.

---

## 5. Loss and optimizer — one line each

PyTorch ships the loss functions (note 03) and optimizers (note 03):

```python
loss_fn = nn.CrossEntropyLoss()                 # classification / next-token (note 03)
optimizer = torch.optim.AdamW(model.parameters(), lr=1e-3)   # Adam (note 03)
```

The optimizer is **given the model's parameters** and the **learning rate** — it will perform the gradient-descent update.

---

## 6. The training step — theory → code

The four-step loop from notes 02–03, in PyTorch:

```python
# one training step
pred = model(x)                 # 1. FORWARD pass (note 02)
loss = loss_fn(pred, y)         # 2. LOSS (note 03)
optimizer.zero_grad()           #    clear old gradients (they accumulate!)
loss.backward()                 # 3. BACKWARD = backprop (autograd, note 02)
optimizer.step()                # 4. UPDATE = gradient descent (note 03)
```

> [!WARNING]
> **`zero_grad()` is the classic gotcha**
> PyTorch **accumulates** gradients by default (adds to `.grad` each `backward()`). If you forget `optimizer.zero_grad()` before `backward()`, gradients from previous steps pile up and training breaks. Always zero the gradients each step. (Accumulation is occasionally *useful* — for simulating big batches — but by default, zero them.)

Mapping to the theory:
```
model(x)          → forward pass        (note 02)
loss_fn(pred, y)  → loss                (note 03)
loss.backward()   → backpropagation     (note 02, via autograd)
optimizer.step()  → gradient descent    (note 03)
```

---

## 7. `train()` vs `eval()` modes

```python
model.train()   # training mode: dropout active, batchnorm updates
model.eval()    # inference mode: dropout off, batchnorm frozen
with torch.no_grad():   # disable autograd for inference → faster, less memory
    preds = model(x)
```

Forgetting to switch to `eval()` / `no_grad()` at inference is another common bug (wrong results + wasted memory).

---

## 8. Main takeaways

- **PyTorch** = the dominant deep-learning framework (and what HF `transformers` §6 / PEFT §21 use).
- **Tensors** = n-dim arrays, **GPU-capable**, autograd-aware; move with `.to(device)`.
- **Autograd** = automatic backprop: `requires_grad`, run ops, `loss.backward()` → gradients in `.grad`.
- **`nn.Module`**: define layers in `__init__`, the **forward pass** in `forward()`; `nn.Linear` + activation = note 02's network.
- **Loss** (`nn.CrossEntropyLoss`) and **optimizer** (`AdamW`) are one line each (note 03).
- Training step = **forward → loss → `zero_grad` → `backward` → `step`** (maps 1:1 to notes 02–03).
- **`zero_grad()`** each step — gradients accumulate by default (classic bug).
- Use **`eval()` + `no_grad()`** at inference.

---

## 9. Things I still want to figure out

- Tensor **shape** debugging strategies (the #1 time-sink)?
- When to use `DataLoader` / `Dataset` (note 05) vs manual batching?
- GPU memory management for bigger models?

---

## 10. Things to dig into

- **PyTorch 60-minute blitz** (official tutorial).
- `torch.nn` layers; `DataLoader`/`Dataset`.
- Connect to: HF `transformers` (§6) is PyTorch under the hood.
- Next: [[05 - Training a Model in PyTorch]].

---

## 11. Next up in this section

- [ ] [[05 - Training a Model in PyTorch]] — a complete training loop end to end.

---

## Related
- [[03 - Gradient Descent and Loss Functions]] — what `backward()`/`step()` implement.
- [[05 - Using the Transformers Package]] — HF transformers, built on PyTorch (§6).

## Sources
- [PyTorch tutorials](https://pytorch.org/tutorials/)
- [PyTorch autograd](https://pytorch.org/docs/stable/notes/autograd.html)
