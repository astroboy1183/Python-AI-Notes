---
title: Generative Models Overview
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 26: Generative Models - Diffusion & Image Generation"
tags:
  - generative-models
  - diffusion
  - gan
  - vae
  - foundations
related:
  - "[[02 - How Diffusion Models Work]]"
  - "[[01 - What is Multi-Modal AI]]"
---

# Generative Models Overview

> [!NOTE]
> **TL;DR**
> So far the course handled *understanding* images (vision input, §10); this section is about **generating** them. A **generative model** learns a data distribution well enough to **produce new samples** from it (new images, audio, etc.) — vs a discriminative model that just classifies. The main families: **GANs** (a generator vs a discriminator in a contest — sharp images but unstable to train), **VAEs** (encode to a latent space, decode back — stable, often blurrier), **autoregressive** models (generate piece by piece — what LLMs do for text, §1), and **diffusion models** (start from noise, iteratively denoise into an image — now the **dominant** approach for high-quality images, behind Stable Diffusion, DALL·E, Midjourney-style systems). This note maps the landscape; the rest of the section dives into diffusion and text-to-image, then using generation APIs and going beyond images.

> [!NOTE]
> **Where this fits**
> First note of **Section 26: Generative Models — Diffusion & Image Generation** — the "generation, not just understanding" gap. §10 covered image *input*; this covers image *output*. It connects to the autoregressive idea from §1.

---

## 1. Generative vs discriminative

```
discriminative:  input → LABEL          ("is this a cat?")   — learns boundaries
generative:      (prompt/noise) → DATA  ("draw a cat")        — learns the distribution
```

A **generative model** learns the underlying distribution of the data so it can **sample new, realistic examples**. The LLM is generative (it generates text); this section is about generating **images** (and other modalities).

> [!IMPORTANT]
> **§10 was understanding; §26 is creating**
> Multi-modal §10 fed images *into* a model to analyze them. Generative models do the reverse — *produce* images (or audio/video) from a prompt or noise. Different machinery, complementary capability. Together: a model that can both *see* and *create*.

---

## 2. The four families

| Family | Core idea | Strength | Weakness |
|---|---|---|---|
| **GAN** | Generator vs discriminator compete | Sharp, realistic images | **Unstable** training; mode collapse |
| **VAE** | Encode → latent → decode | Stable; smooth latent space | Often **blurrier** outputs |
| **Autoregressive** | Generate piece-by-piece (next token/pixel) | Great for sequences (text!) | Slow for high-res images |
| **Diffusion** | Noise → iteratively denoise | **State-of-the-art** image quality + diversity | Slow (many steps); compute-heavy |

---

## 3. GANs — the adversarial contest

Two networks fight:
```
Generator   → makes fake images, tries to fool the discriminator
Discriminator → judges real vs fake, tries to catch the generator
→ they train against each other; the generator gets better at realism
```
GANs produced the first wave of photorealistic faces, but are **notoriously unstable** to train (and can "mode collapse" — only generate a few variations). Largely superseded by diffusion for general image generation.

---

## 4. VAEs — encode and decode

A **Variational Autoencoder** learns to **compress** data into a **latent space** and **reconstruct** it; sampling points in the latent space generates new data.
```
image → encoder → latent vector → decoder → image
        (sample new latents → generate new images)
```
Stable and conceptually clean, with a smooth, interpolatable latent space — but outputs tend to be **blurrier** than GANs/diffusion. Importantly, VAEs power the **latent space** that modern **latent diffusion** (Stable Diffusion) runs in (note 02).

---

## 5. Autoregressive — generate piece by piece

Generate one unit at a time, each conditioned on the previous — **exactly how LLMs generate text** (§1: next-token prediction). Can be applied to images (next-pixel/next-patch), but is **slow** for high resolution. The same family as everything in the LLM part of the course.

```
LLM text:        token → token → token ...   (autoregressive, §1)
AR image:        pixel/patch → next → ...     (same idea, slower for images)
```

---

## 6. Diffusion — the current champion

> [!IMPORTANT]
> **Diffusion dominates modern image generation**
> Today's high-quality text-to-image systems (Stable Diffusion, DALL·E, Imagen, Midjourney-style) are **diffusion models**. The idea: take an image, progressively **add noise** until it's pure static, and train a model to **reverse** that — start from random noise and **iteratively denoise** into a coherent image, **guided by a text prompt**. It beats GANs on quality + diversity and is far more stable to train. Full mechanics in [[02 - How Diffusion Models Work]].

```
training:   image → add noise step by step → pure noise   (learn to reverse this)
generating: pure noise → denoise step by step → image      (guided by a prompt)
```

---

## 7. Why this matters for an AI app builder

- **New product surface**: generate images/art/assets, edit images, create variations, audio/video (note 05).
- **Multi-modal apps**: combine LLM (text) + diffusion (images) — e.g. an agent that writes copy *and* generates a matching image.
- **Mostly API-consumed**: like LLMs, you'll usually **call a generation API** (note 04) rather than train one — but understanding the families explains capabilities, costs, and limits.

---

## 8. Main takeaways

- A **generative model** learns a data distribution to **sample new data**; §10 understood images, §26 **creates** them.
- Four families: **GANs** (sharp, unstable), **VAEs** (stable, blurry, power latent diffusion), **autoregressive** (sequences/text, §1), **diffusion** (SOTA images).
- **GANs**: generator vs discriminator contest — realistic but unstable.
- **VAEs**: encode→latent→decode; smooth latent space; blurrier.
- **Autoregressive** = LLM-style next-piece generation; slow for images.
- **Diffusion dominates** image generation: noise → iterative denoising → image, guided by a prompt.
- For app builders, generation is mostly **API-consumed** (note 04), enabling **multi-modal** products.

---

## 9. Things I still want to figure out

- Why diffusion beat GANs in practice (quality + stability)?
- Where autoregressive image models (and unified text-image models) are heading?
- How VAEs feed into latent diffusion (note 02)?

---

## 10. Things to dig into

- Overviews of GAN / VAE / diffusion trade-offs.
- Hugging Face **diffusers** library (note 04).
- Next: [[02 - How Diffusion Models Work]].

---

## 11. Next up in this section

- [ ] [[02 - How Diffusion Models Work]] — the noise→denoise mechanism behind modern image gen.

---

## Related
- [[01 - What is Multi-Modal AI]] — image *understanding* (§10), the complement to generation.
- [[03 - The Transformer - Predicting the Next Token]] — autoregressive generation (§1).

## Sources
- [Hugging Face: generative model overviews](https://huggingface.co/docs/diffusers/)
- [Lil'Log: diffusion / generative models](https://lilianweng.github.io/)
