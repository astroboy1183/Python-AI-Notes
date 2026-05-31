---
title: Neural Networks and Backpropagation
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 25: ML & Deep Learning Foundations with PyTorch"
tags:
  - deep-learning
  - neural-networks
  - backpropagation
  - foundations
related:
  - "[[01 - Machine Learning Fundamentals]]"
  - "[[03 - Gradient Descent and Loss Functions]]"
---

# Neural Networks and Backpropagation

> [!NOTE]
> **TL;DR**
> A **neural network** is layers of simple units (**neurons**) connected by weighted edges. Each neuron computes a **weighted sum of its inputs + a bias**, then applies a **non-linear activation** (ReLU, etc.) — and stacking these layers lets the network approximate very complex functions. **Forward pass**: data flows input → hidden layers → output (a prediction). **Loss**: measure how wrong (note 03). **Backpropagation**: use the chain rule of calculus to compute how much **each weight** contributed to the loss (the **gradients**), flowing the error backward through the layers. Then **gradient descent** (note 03) nudges every weight to reduce the loss. Repeat over the data and the network **learns**. The non-linear activations are essential — without them, stacked layers collapse into a single linear function. This is the machinery underneath the transformer (§1) and every model in this course.

> [!NOTE]
> **Where this fits**
> Second note of **Section 25**, building on ML basics ([[01 - Machine Learning Fundamentals]]). The optimization step (gradient descent/loss) is detailed in [[03 - Gradient Descent and Loss Functions]]; PyTorch makes it concrete (note 04).

---

## 1. The neuron

The atomic unit: take inputs, weight them, sum, add a bias, apply an activation.

```
inputs x1,x2,x3
   │ weights w1,w2,w3
   ▼
sum = w1·x1 + w2·x2 + w3·x3 + b      (weighted sum + bias)
   ▼
output = activation(sum)             (e.g. ReLU)
```

The **weights** and **bias** are what the network *learns*. A neuron alone is a tiny linear model + a squash; the power comes from connecting many.

---

## 2. Layers and the network

Neurons are organized into **layers**; outputs of one layer feed the next.

```
input layer → hidden layer 1 → hidden layer 2 → ... → output layer
   (raw data)   (learned features)                      (prediction)
```

- **Input layer**: the raw features (e.g. token embeddings, §1).
- **Hidden layers**: learn increasingly abstract **features** automatically (the "deep" in deep learning; recall classic ML needs hand-crafted features, note 01).
- **Output layer**: the prediction (a class, a number, next-token probabilities).

"**Deep**" learning = many hidden layers.

---

## 3. Activation functions — why non-linearity matters

> [!IMPORTANT]
> **Without non-linear activations, depth is pointless**
> A stack of purely linear layers is mathematically **equivalent to one linear layer** — no matter how many you add, it can only learn linear relationships. **Non-linear activations** (ReLU, sigmoid, tanh, GELU) between layers are what let the network model **complex, non-linear** patterns. ReLU (`max(0, x)`) is the common default — simple and effective. This is the single reason deep networks can learn rich functions.

```
linear + linear + linear         = linear (useless depth)
linear + ReLU + linear + ReLU... = arbitrarily complex function ✅
```

---

## 4. The forward pass

Run input through the network to get a prediction:

```
x → layer1 → activation → layer2 → activation → ... → output (ŷ)
```

This is just a sequence of matrix multiplications and activations. For an LLM, the forward pass turns token embeddings into next-token probabilities (§1).

---

## 5. Loss — measuring wrongness

Compare the prediction ŷ to the truth y via a **loss function** (note 03):

```
loss = how_wrong(ŷ, y)      (e.g. cross-entropy for classification / next-token)
```

Training's whole job: find weights that **minimize** this loss across the data.

---

## 6. Backpropagation — assigning blame

The key learning algorithm. Given the loss, **backprop** computes the **gradient** of the loss with respect to **every weight** — i.e., how much each weight contributed to the error — by applying the **chain rule** of calculus backward through the layers.

```
forward:   x ──► layers ──► prediction ──► LOSS
backward:  LOSS ──► ∂loss/∂weights (gradients) flow back through each layer
                    "how should each weight change to reduce the loss?"
```

> [!IMPORTANT]
> **Backprop = the chain rule, applied efficiently across layers**
> Each weight's influence on the loss passes through all the layers after it. Backpropagation computes these gradients **layer by layer, from output back to input**, reusing intermediate results so it's efficient. It doesn't *update* weights — it computes the **direction** each should move. The update is gradient descent (note 03). Modern frameworks (PyTorch, note 04) do backprop **automatically** (`autograd`) — you rarely compute gradients by hand.

---

## 7. The training loop (the whole cycle)

```
repeat (many times, over the data):
  1. FORWARD:   prediction = network(input)
  2. LOSS:      loss = how_wrong(prediction, target)
  3. BACKWARD:  gradients = backprop(loss)        ← blame each weight
  4. UPDATE:    weights -= learning_rate * gradients   ← gradient descent (note 03)
→ loss goes down → the network learns
```

This four-step loop **is** how every neural net — including the transformer (§1) and any model you fine-tune (§21) — learns. Note 04 implements it in PyTorch; note 05 runs it.

---

## 8. Regularization (avoiding overfitting)

To combat overfitting (note 01), networks use:
- **Dropout**: randomly zero some neurons during training → prevents over-reliance on any one.
- **Weight decay (L2)**: penalize large weights → simpler model.
- **Early stopping**: stop when validation loss stops improving.
- **More/augmented data**: the most reliable fix.

---

## 9. Main takeaways

- A **neuron** = weighted sum of inputs + bias → **activation**; weights/biases are learned.
- **Layers** of neurons form the network; **hidden layers learn features automatically**; "deep" = many layers.
- **Non-linear activations** (ReLU/GELU) are essential — without them, depth collapses to one linear layer.
- **Forward pass**: input → layers → prediction. **Loss**: how wrong (note 03).
- **Backpropagation**: chain rule backward → **gradient** of loss w.r.t. every weight (assigns blame); doesn't update, just computes direction.
- **Training loop**: forward → loss → backward → update (gradient descent), repeated.
- This loop underlies the **transformer (§1)** and all fine-tuning (§21).
- **Regularization** (dropout, weight decay, early stopping) fights overfitting.
- Frameworks do backprop **automatically** (PyTorch autograd, note 04).

---

## 10. Things I still want to figure out

- Why ReLU over sigmoid/tanh in practice (vanishing gradients)?
- How dropout/weight decay interact with model size?
- How backprop scales to billions of parameters (memory, §21 FT cost)?

---

## 11. Things to dig into

- **3Blue1Brown** neural network series (intuition for backprop).
- Activation functions; vanishing/exploding gradients.
- Then implement it: [[04 - PyTorch Basics]].
- Next: [[03 - Gradient Descent and Loss Functions]].

---

## 12. Next up in this section

- [ ] [[03 - Gradient Descent and Loss Functions]] — how the "update" step actually minimizes loss.

---

## Related
- [[01 - Machine Learning Fundamentals]] — loss, overfitting (used here).
- [[06 - Attention Is All You Need - Architecture Walkthrough]] — the transformer this builds toward (§1).

## Sources
- [3Blue1Brown: Neural Networks](https://www.3blue1brown.com/topics/neural-networks)
- [Deep Learning (Goodfellow et al.)](https://www.deeplearningbook.org/)
