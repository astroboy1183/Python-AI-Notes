---
title: Training a Model in PyTorch
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 25: ML & Deep Learning Foundations with PyTorch"
tags:
  - pytorch
  - training-loop
  - deep-learning
  - hands-on
related:
  - "[[04 - PyTorch Basics]]"
  - "[[06 - From MLP to Transformer]]"
---

# Training a Model in PyTorch

> [!NOTE]
> **TL;DR**
> This puts notes 01–04 together into a **complete training loop** — the canonical "hello world" of deep learning (e.g. classifying handwritten digits). The pieces: a **`Dataset` + `DataLoader`** to feed mini-batches (note 03), a **model** (`nn.Module`, note 04), a **loss** + **optimizer** (note 03), then the **epoch loop**: for each batch, forward → loss → `zero_grad` → `backward` → `step`, while tracking training loss. After each epoch, switch to **`eval()`** and measure **validation** accuracy (note 01's held-out discipline) — watching for **overfitting** (train loss ↓ but val accuracy stalls/drops). The exact same loop, scaled to billions of parameters and text data, trains a transformer (§1) — and is what fine-tuning (§21) runs under the hood. Understanding this loop demystifies every "the model is training" moment in the course.

> [!NOTE]
> **Where this fits**
> Fifth note of **Section 25**, assembling the primitives from [[04 - PyTorch Basics]]. It's the concrete realization of the theory in notes 01–03, and the bridge to seeing the transformer (§1) as "the same loop, bigger" — [[06 - From MLP to Transformer]].

---

## 1. The full pipeline

```
DATA → Dataset/DataLoader (batches) → MODEL (nn.Module) → LOSS + OPTIMIZER
   → EPOCH LOOP: forward → loss → zero_grad → backward → step
   → after each epoch: eval() on validation set → track accuracy / overfitting
```

Every deep-learning training script, from a toy classifier to an LLM, follows this shape.

---

## 2. Data: `Dataset` and `DataLoader`

PyTorch separates **what the data is** (`Dataset`) from **how it's batched/shuffled** (`DataLoader`).

```python
from torch.utils.data import DataLoader

# (datasets like MNIST come ready via torchvision; conceptually:)
train_loader = DataLoader(train_dataset, batch_size=64, shuffle=True)
val_loader   = DataLoader(val_dataset,   batch_size=64)
```

- `batch_size` → the **mini-batch** size (note 03).
- `shuffle=True` on training → different batch order each epoch (helps generalization).
- The `DataLoader` yields `(inputs, targets)` batches in the loop.

---

## 3. Model, loss, optimizer (from note 04)

```python
import torch, torch.nn as nn

device = "cuda" if torch.cuda.is_available() else "cpu"

model = MLP().to(device)                  # nn.Module from note 04
loss_fn = nn.CrossEntropyLoss()           # classification loss (note 03)
optimizer = torch.optim.AdamW(model.parameters(), lr=1e-3)   # note 03
```

---

## 4. The training loop

```python
EPOCHS = 5
for epoch in range(EPOCHS):
    model.train()                          # training mode (note 04)
    running_loss = 0.0
    for inputs, targets in train_loader:   # mini-batches (note 03)
        inputs, targets = inputs.to(device), targets.to(device)

        preds = model(inputs)              # 1. FORWARD (note 02)
        loss = loss_fn(preds, targets)     # 2. LOSS (note 03)

        optimizer.zero_grad()              #    clear grads (note 04 gotcha!)
        loss.backward()                    # 3. BACKWARD = backprop (note 02)
        optimizer.step()                   # 4. UPDATE = gradient descent (note 03)

        running_loss += loss.item()
    print(f"epoch {epoch}: train loss {running_loss/len(train_loader):.4f}")

    validate(model, val_loader, device)    # measure generalization (below)
```

> [!IMPORTANT]
> **This loop is the entire act of "training"**
> Strip away the framework sugar and *every* neural network — including the transformer (§1) and any fine-tune (§21) — learns via exactly this: iterate over batches, forward, compute loss, backprop, step. Scale changes (more data, more parameters, more GPUs, distributed training), but the **loop is the same**. The "loss going down" you see while fine-tuning (§21) is `running_loss` here.

---

## 5. The validation step

After each epoch, measure performance on the **held-out validation set** (note 01) — in `eval()` mode, no gradients:

```python
def validate(model, val_loader, device):
    model.eval()                           # inference mode (note 04)
    correct = total = 0
    with torch.no_grad():                  # no autograd → faster (note 04)
        for inputs, targets in val_loader:
            inputs, targets = inputs.to(device), targets.to(device)
            preds = model(inputs)
            predicted = preds.argmax(dim=1)
            correct += (predicted == targets).sum().item()
            total += targets.size(0)
    print(f"  val accuracy: {correct/total:.3f}")
```

---

## 6. Reading the training curves (overfitting check)

> [!TIP]
> **Watch train loss vs validation accuracy together**
> - Train loss ↓ **and** val accuracy ↑ → learning well.
> - Train loss ↓ **but** val accuracy stalls/drops → **overfitting** (note 01) — stop early, add regularization (dropout/weight decay, note 02), or get more data.
> - Train loss not falling → **underfitting** / learning rate too low (note 03), or a bug.
>
> This is the exact same diagnostic used when fine-tuning LLMs (§21) — the loop and the curves transfer directly.

```
good:        train loss ↓↓↓ , val acc ↑↑↑
overfitting: train loss ↓↓↓ , val acc ▔▔▔ then ↓
```

---

## 7. Common bugs (the greatest hits)

| Bug | Symptom | Fix |
|---|---|---|
| Forgot `zero_grad()` | Loss erratic / won't converge | Zero grads each step (note 04) |
| Forgot `eval()`/`no_grad()` | Wrong/inconsistent val results, OOM | Switch modes at inference |
| Wrong tensor **shapes** | Runtime shape error | Print shapes; check layer dims |
| Data not on **same device** | Device mismatch error | `.to(device)` inputs *and* model |
| Learning rate too high | Loss → NaN / diverges | Lower LR (note 03) |
| Labels wrong dtype/range | Loss error | Match loss fn expectations |

---

## 8. Where it goes from here

This toy loop scales to real systems via:
- **More data + bigger models** (the transformer, §1 / note 06).
- **GPUs + distributed training** (multi-GPU, §24 serving's cousin).
- **Checkpointing** (save/resume weights), LR schedules, mixed precision.
- **Fine-tuning** (§21) = this loop on a pre-trained model with `(prompt, response)` data — often via Hugging Face `Trainer`/TRL which wraps exactly this.

You rarely write the raw loop for LLMs (HF `Trainer`/TRL do it), but knowing it means none of it is a black box.

---

## 9. Main takeaways

- A full PyTorch training script = **Dataset/DataLoader → model → loss+optimizer → epoch loop → validate**.
- **`DataLoader`** feeds shuffled **mini-batches** (note 03).
- The loop: **forward → loss → `zero_grad` → `backward` → `step`** (maps to notes 02–03).
- **This loop *is* training** — the transformer (§1) and fine-tuning (§21) use the same one, just scaled.
- Validate each epoch in **`eval()` + `no_grad()`** on a **held-out** set (note 01).
- **Watch train loss vs val accuracy** to catch **overfitting/underfitting** (same as §21 FT curves).
- Classic bugs: missing `zero_grad`, wrong mode, shape/device mismatches, LR too high.
- HF `Trainer`/TRL wrap this loop for LLMs (§21) — now it's not a black box.

---

## 10. Things I still want to figure out

- Hands-on: train an MNIST/CIFAR classifier end to end and read the curves.
- LR schedules + mixed precision in the loop?
- How HF `Trainer` maps onto this loop (§21)?

---

## 11. Things to dig into

- **PyTorch** MNIST/CIFAR tutorials (run the loop yourself).
- `torchvision` datasets; checkpointing (`state_dict`).
- HF `Trainer` / TRL `SFTTrainer` (§21) as this loop, wrapped.
- Next: [[06 - From MLP to Transformer]].

---

## 12. Next up in this section

- [ ] [[06 - From MLP to Transformer]] — connecting this loop back to the LLMs from §1.

---

## Related
- [[04 - PyTorch Basics]] — the primitives assembled here.
- [[06 - Practical Fine-Tuning Workflow]] — this loop applied to LLM fine-tuning (§21).

## Sources
- [PyTorch training tutorial](https://pytorch.org/tutorials/beginner/basics/optimization_tutorial.html)
- [torchvision datasets](https://pytorch.org/vision/stable/datasets.html)
