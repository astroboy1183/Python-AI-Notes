---
title: Text-to-Image Generation
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 26: Generative Models - Diffusion & Image Generation"
tags:
  - text-to-image
  - diffusion
  - clip
  - prompting
  - image-generation
related:
  - "[[02 - How Diffusion Models Work]]"
  - "[[04 - Using Image Generation APIs]]"
---

# Text-to-Image Generation

> [!NOTE]
> **TL;DR**
> A raw diffusion model (note 02) generates *some* image from noise; **text-to-image** makes it generate the image *you asked for*. The bridge is a **text encoder** (often **CLIP**, which was trained to align text and images in a shared embedding space) — it turns the prompt into an embedding that's **injected into the denoising U-Net** so every denoise step is steered toward the prompt's meaning. **Classifier-free guidance (CFG)** controls *how strongly* the prompt is followed (a "guidance scale": higher = more prompt-faithful but less natural). Practical levers you control: the **prompt** (subject, style, detail), a **negative prompt** (what to avoid), the **seed** (reproducibility), **steps** and **guidance scale** (note 02). Image generation also has its own **prompt engineering** — descriptive, structured prompts with style/medium/lighting cues produce far better results.

> [!NOTE]
> **Where this fits**
> Third note of **Section 26** — how a prompt steers the diffusion engine from [[02 - How Diffusion Models Work]]. Using this via APIs/code is [[04 - Using Image Generation APIs]].

---

## 1. The problem: how does text steer noise → image?

Note 02's diffusion turns noise into *an* image, but unconditioned. Text-to-image must **condition** the denoising on the prompt so the result matches it.

```
"a red fox in a snowy forest, oil painting" + random noise → [steered denoising] → matching image
```

The key question: how does a string of text influence a pixel-denoising process? Answer: a **text encoder** + **conditioning the U-Net**.

---

## 2. CLIP — aligning text and images

The bridge is a model like **CLIP**, trained on huge sets of (image, caption) pairs to put **matching text and images near each other** in a shared embedding space.

```
"a red fox"  ─CLIP text encoder─►  embedding
fox photo    ─CLIP image encoder─► embedding   (these two land close together)
```

> [!IMPORTANT]
> **CLIP gives diffusion a "meaning of the prompt" it can use**
> Because CLIP's text and image embeddings live in the **same** space, the text embedding of a prompt is a representation the image-generation process can be steered by. The prompt → CLIP → embedding → fed into the denoiser, so the model knows *what* it's supposed to be drawing. CLIP (or similar text encoders) is the translation layer between language and pixels.

---

## 3. Conditioning the denoiser

The prompt embedding is **injected into the U-Net** (note 02) at each denoising step — typically via **cross-attention** (the same attention mechanism from §1, here letting image features attend to text features).

```
each denoise step:
   noisy latent  +  prompt embedding (via cross-attention)  →  predict noise that moves toward the prompt
```

So every one of the N denoising steps is nudged toward "look more like what the prompt describes." By the final step, the image matches the prompt.

---

## 4. Classifier-free guidance (CFG) — the strength dial

How *strongly* should the model follow the prompt? **Classifier-free guidance** controls this with a **guidance scale**:

```
low guidance  → more creative/natural, but may drift from the prompt
high guidance → closely follows the prompt, but can look over-saturated/unnatural
```

Mechanically, the model predicts noise **with** and **without** the prompt and extrapolates in the prompt's direction; the **guidance scale** sets how far. A moderate value is the usual sweet spot — too high causes artifacts, too low ignores the prompt.

---

## 5. The controls you actually use

| Control | Effect |
|---|---|
| **Prompt** | What to generate (subject, style, medium, lighting, composition) |
| **Negative prompt** | What to **avoid** ("blurry, extra fingers, text") |
| **Guidance scale (CFG)** | How strictly to follow the prompt |
| **Steps** | Denoising steps — speed vs quality (note 02) |
| **Seed** | Random seed — same seed + same settings → same image (reproducibility) |
| **Size / aspect ratio** | Output dimensions |

---

## 6. Image prompt engineering

> [!TIP]
> **Image prompts reward description and structure**
> Unlike chat, image prompts work best as **dense descriptive phrases**: subject + details + **style/medium** (photo, oil painting, 3D render) + **lighting** + **composition** + quality cues. Example: *"a red fox in a snowy forest at golden hour, oil painting, soft warm light, highly detailed."* Use the **negative prompt** to remove common defects ("blurry, deformed, watermark"). This is its own skill — analogous to §3 prompt engineering, but for visual attributes.

```
weak:  "a fox"
strong: "a red fox sitting in a snowy pine forest at sunrise, oil painting style,
         soft golden light, detailed fur, shallow depth of field"
+ negative: "blurry, low quality, extra limbs, text, watermark"
```

---

## 7. Beyond plain text-to-image

The same conditioned-diffusion machinery enables more:

| Capability | What it does |
|---|---|
| **Image-to-image (img2img)** | Start denoising from an existing image (transform a photo per a prompt) |
| **Inpainting** | Regenerate a masked region (edit part of an image) |
| **Outpainting** | Extend an image beyond its borders |
| **ControlNet** | Condition on structure (pose, edges, depth) for precise control |
| **Image variations** | Generate alternatives of a given image |

These make diffusion a **editing/controllable** tool, not just text→image.

---

## 8. Main takeaways

- **Text-to-image** = diffusion (note 02) **conditioned** on a prompt so it generates what you asked.
- A **text encoder (CLIP)** maps the prompt into an embedding aligned with images — the language↔pixels bridge.
- The prompt embedding is injected into the **U-Net via cross-attention** at each denoise step.
- **Classifier-free guidance (CFG)** / guidance scale sets **how strongly** the prompt is followed (moderate = sweet spot).
- Controls: **prompt, negative prompt, guidance scale, steps, seed, size**.
- **Image prompt engineering** rewards **descriptive, structured** prompts (subject + style + lighting) + negative prompts.
- Same machinery enables **img2img, inpainting, outpainting, ControlNet, variations**.

---

## 9. Things I still want to figure out

- Typical good **guidance scale** range, and when to deviate?
- How much do **negative prompts** actually help in practice?
- ControlNet for precise layout control — how it conditions structure?

---

## 10. Things to dig into

- **CLIP** paper; **Stable Diffusion** pipeline (text encoder → U-Net → VAE decode).
- **ControlNet**, inpainting workflows.
- Prompt galleries / guides for image models.
- Next: [[04 - Using Image Generation APIs]].

---

## 11. Next up in this section

- [ ] [[04 - Using Image Generation APIs]] — generate images from Python.

---

## Related
- [[02 - How Diffusion Models Work]] — the engine this steers.
- [[07 - Vector Embeddings]] — CLIP embeddings extend the embedding idea (§1) to images.

## Sources
- [CLIP paper](https://arxiv.org/abs/2103.00020)
- [Stable Diffusion / diffusers](https://huggingface.co/docs/diffusers/)
