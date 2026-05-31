---
title: How Diffusion Models Work
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 26: Generative Models - Diffusion & Image Generation"
tags:
  - diffusion
  - generative-models
  - image-generation
  - foundations
related:
  - "[[01 - Generative Models Overview]]"
  - "[[03 - Text-to-Image Generation]]"
---

# How Diffusion Models Work

> [!NOTE]
> **TL;DR**
> Diffusion has two processes. **Forward (training-time)**: take a real image and **add a little Gaussian noise** repeatedly over many steps until it's pure static — a fixed, easy process. **Reverse (generation)**: train a neural network (usually a **U-Net**) to **predict and remove the noise** at each step, so you can start from **pure random noise** and **iteratively denoise** it into a coherent image. Generating = run the reverse process for N steps. The big efficiency trick behind Stable Diffusion is **latent diffusion**: do all this in a compressed **latent space** (via a VAE, note 01) instead of full-resolution pixels — far cheaper. The number of **denoising steps** trades speed vs quality. This is the engine; text conditioning (how a *prompt* steers it) is note 03.

> [!NOTE]
> **Where this fits**
> Second note of **Section 26**, detailing the dominant family from [[01 - Generative Models Overview]]. How text prompts guide the denoising is [[03 - Text-to-Image Generation]].

---

## 1. The two processes

```
FORWARD (fixed, used in training):
  image ─► +noise ─► +noise ─► ... ─► pure noise
  (gradually destroy structure — an easy, defined process)

REVERSE (learned, used to generate):
  pure noise ─► −noise ─► −noise ─► ... ─► image
  (gradually recover structure — the NN learns THIS)
```

Diffusion's whole idea: **destroying** an image with noise is trivial and well-defined; **creating** one is hard — so train a model to **reverse the destruction**, step by step.

---

## 2. Forward process — adding noise

Start with a real image and add a small amount of **Gaussian noise** repeatedly over many timesteps (e.g. hundreds/thousands). After enough steps the image becomes **indistinguishable from random noise**.

```
x0 (clean) → x1 → x2 → ... → xT (pure noise)
             each step adds a bit more noise (a fixed schedule)
```

This requires **no learning** — it's a defined mathematical process. Its purpose is to create training pairs: "here's a noisy image at step t; here's the noise that was added."

---

## 3. Reverse process — learning to denoise

The model learns to **undo** one noise step: given a noisy image at step *t*, predict the noise (so it can be subtracted to get a slightly cleaner image at step *t−1*).

```
train:  show the model xt (noisy) → it predicts the noise → compare to the real noise added → loss → backprop (§25)
```

> [!IMPORTANT]
> **The model's job is "predict the noise"**
> Diffusion training reduces to a simple objective: at a random timestep, the network predicts the noise present in the image. Subtracting predicted noise repeatedly walks from static back to a clean image. It's trained by the same loop from §25 (forward → loss → backprop → gradient descent) — just predicting noise instead of a label.

---

## 4. Generation — denoise from pure noise

To **create** a new image, skip the forward process entirely and start from **random noise**, then run the learned reverse process for N steps:

```
random noise → [denoise step] → [denoise step] → ... (N steps) → new image
```

Each step removes a bit of predicted noise; after N steps a coherent image emerges. Because you start from *random* noise, every run produces a **different** image (controllable via a **seed** for reproducibility).

---

## 5. The denoising network: U-Net (typically)

The model that predicts the noise is usually a **U-Net** — a convolutional encoder-decoder with skip connections, well-suited to image-to-image tasks (input: noisy image; output: predicted noise). (Some modern systems use transformer-based variants — "diffusion transformers.") It's trained by the §25 loop. The text prompt is injected into this network to steer denoising (note 03).

---

## 6. Latent diffusion — the efficiency breakthrough

> [!IMPORTANT]
> **Stable Diffusion runs the diffusion in a *latent* space, not pixels**
> Running diffusion on full-resolution pixels is hugely expensive. **Latent diffusion** (the basis of Stable Diffusion) first uses a **VAE** (note 01) to **compress** the image into a much smaller **latent representation**, runs the entire noise/denoise process **there**, then **decodes** the final latent back to a full image. This cuts compute by orders of magnitude — it's why high-quality diffusion can run on consumer GPUs.

```
image ─VAE encode─► latent (small) ─► [diffusion: noise↔denoise in latent space] ─► latent ─VAE decode─► image
```

---

## 7. Sampling steps — speed vs quality

The reverse process is iterative, so the **number of denoising steps** is a direct **speed/quality knob**:

```
few steps  → fast, lower quality
many steps → slow, higher quality
```

**Schedulers/samplers** (DDPM, DDIM, and faster variants) control how the denoising is done and how few steps can be used while keeping quality — analogous to optimizers in §25, but for sampling. Fewer-step samplers have made generation much faster.

---

## 8. Why diffusion won

- **Quality + diversity**: beats GANs, doesn't mode-collapse.
- **Stable training**: a simple "predict the noise" objective vs GANs' adversarial instability (note 01).
- **Controllable**: the iterative process is a natural place to inject **guidance** (text prompts, note 03; also img2img, inpainting, ControlNet).

The trade-off is **speed** (many steps) and **compute** — mitigated by latent diffusion + fast samplers.

---

## 9. Main takeaways

- Diffusion = **forward** (add noise to an image until it's static — fixed) + **reverse** (learn to denoise — the model).
- The model's objective: **predict the noise** at a given step; trained by the §25 loop.
- **Generate** by starting from **random noise** and running the reverse process for **N steps** → a new image (seed controls reproducibility).
- The denoiser is typically a **U-Net** (some use transformers).
- **Latent diffusion** (Stable Diffusion) runs the process in a **VAE-compressed latent space** → far cheaper → consumer-GPU feasible.
- **Denoising steps** trade speed vs quality; **schedulers/samplers** let you use fewer steps.
- Diffusion won on **quality, diversity, stability, controllability**; cost is speed/compute.

---

## 10. Things I still want to figure out

- DDPM vs DDIM vs fast samplers — practical step counts?
- How much quality does latent (vs pixel) diffusion cost, if any?
- U-Net vs diffusion-transformer backbones — trade-offs?

---

## 11. Things to dig into

- The **DDPM** paper + **Latent Diffusion / Stable Diffusion** paper.
- Hugging Face **diffusers** schedulers.
- Lil'Log "What are diffusion models?".
- Next: [[03 - Text-to-Image Generation]].

---

## 12. Next up in this section

- [ ] [[03 - Text-to-Image Generation]] — how a text prompt steers the denoising.

---

## Related
- [[01 - Generative Models Overview]] — where diffusion sits among the families.
- [[05 - Training a Model in PyTorch]] — the training loop diffusion uses (§25).

## Sources
- [DDPM paper](https://arxiv.org/abs/2006.11239)
- [Latent Diffusion / Stable Diffusion paper](https://arxiv.org/abs/2112.10752)
