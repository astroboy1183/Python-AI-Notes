---
title: Using Image Generation APIs
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 26: Generative Models - Diffusion & Image Generation"
tags:
  - image-generation
  - api
  - diffusers
  - python
  - hands-on
related:
  - "[[03 - Text-to-Image Generation]]"
  - "[[01 - What is Multi-Modal AI]]"
---

# Using Image Generation APIs

> [!NOTE]
> **TL;DR**
> Two ways to generate images from Python — the same managed-vs-self-hosted fork as LLMs (§24). **Managed API**: call a provider's image model (OpenAI's image API, etc.) with a prompt and get back an image — zero infra, pay-per-image, instant. **Self-hosted**: run an open model (Stable Diffusion) locally via Hugging Face **`diffusers`** — free per-image, private, customizable, but needs a **GPU**. The `diffusers` pipeline mirrors note 03's controls (prompt, negative prompt, steps, guidance scale, seed). For app builders, the big pattern is **combining LLM + image gen**: an LLM writes/expands the prompt or copy, and the image model renders it — e.g. an agent (§7) with an "generate_image" **tool**. The same security/cost/eval disciplines (§19/§20/§17) apply: validate prompts, watch per-image cost, and review outputs.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 26** — the hands-on counterpart to [[03 - Text-to-Image Generation]]. It reuses the managed-vs-self-hosted framing from §24 and the multi-modal idea from §10.

---

## 1. The familiar fork: managed vs self-hosted

```
MANAGED IMAGE API                    SELF-HOSTED (diffusers)
provider runs the model              you run Stable Diffusion locally
prompt → image over HTTP             prompt → image on your GPU
pay per image, no infra              free per image, needs a GPU
instant, easy                        private, customizable (LoRA, ControlNet)
```

Exactly the §24 serving decision, applied to image models: **managed** to start, **self-hosted** for cost-at-volume, privacy (§19), or customization.

---

## 2. Managed API (the easy path)

Call a provider's image model with a prompt; get an image back.

```python
# conceptual — managed image generation (OpenAI-style)
from openai import OpenAI
client = OpenAI()

result = client.images.generate(
    model="gpt-image-1",                 # an image model (name illustrative)
    prompt="a red fox in a snowy forest, oil painting, golden light",
    size="1024x1024",
)
# result contains image data / a URL → save or display it
```

- No GPUs, scales instantly, pay per image.
- The model/params evolve — check current provider docs for exact API + options (sizes, quality, edits).
- Providers also offer **edits/variations/inpainting** (note 03 capabilities) via the same API family.

---

## 3. Self-hosted with `diffusers`

Hugging Face **`diffusers`** runs open diffusion models (Stable Diffusion) locally. It exposes note 02/03's mechanics as parameters.

```python
# conceptual — self-hosted Stable Diffusion via diffusers
import torch
from diffusers import StableDiffusionPipeline

pipe = StableDiffusionPipeline.from_pretrained(
    "stabilityai/stable-diffusion-...",     # a model id (illustrative)
    torch_dtype=torch.float16,
).to("cuda")                                 # needs a GPU

image = pipe(
    prompt="a red fox in a snowy forest, oil painting, golden light",
    negative_prompt="blurry, deformed, watermark",   # note 03
    num_inference_steps=30,                  # steps: speed vs quality (note 02)
    guidance_scale=7.5,                      # CFG strength (note 03)
    generator=torch.Generator("cuda").manual_seed(42),  # seed: reproducible
).images[0]

image.save("fox.png")
```

> [!TIP]
> **The `diffusers` params *are* notes 02–03**
> `num_inference_steps` = denoising steps (note 02 speed/quality), `guidance_scale` = classifier-free guidance (note 03), `negative_prompt` / `prompt` = the steering (note 03), `seed` = reproducibility. Understanding the theory makes the API self-explanatory. `diffusers` also supports **img2img, inpainting, ControlNet, and LoRA** (custom styles — same LoRA idea as §21).

It's PyTorch (§25) under the hood, and like local LLMs (§5) benefits from **quantization** (§21.05) to fit on smaller GPUs.

---

## 4. The killer pattern: LLM + image generation

> [!IMPORTANT]
> **Combine text and image models for multi-modal apps**
> The highest-value use for an app builder isn't image gen alone — it's **chaining an LLM with an image model**:
> - LLM **expands** a short user idea into a rich image prompt (image prompt engineering, note 03), then the image model renders it.
> - An **agent (§7)** has a `generate_image` **tool** — it decides when to create an image as part of a task.
> - LLM writes **copy** + image model creates the **matching visual** (marketing, slides, product mockups).
>
> This unifies §10 (understanding), the LLM/agent work (§7), and §26 (creating) into genuinely multi-modal products.

```python
# conceptual: LLM writes the image prompt, image model renders it
img_prompt = llm("Turn this idea into a detailed image prompt: 'cozy reading nook'")
image = generate_image(img_prompt)   # managed API or diffusers
```

---

## 5. The same disciplines still apply

Image generation inherits the production concerns from earlier gap sections:

| Discipline | For image gen |
|---|---|
| **Cost** (§20) | Pay **per image** (and per step/resolution); watch spend |
| **Latency** (§20) | Diffusion is slow (many steps) — async/queue (§9/§24) for batches |
| **Safety** (§19) | Filter prompts (NSFW/abuse), moderate **outputs**, respect provider content policy |
| **Eval** (§17) | Quality is subjective — human review / preference, CLIP-similarity-to-prompt as a proxy |
| **Serving** (§24) | Self-hosted = GPU serving, cold starts (§24) |
| **Rights/provenance** | Licensing, attribution, and provenance/watermarking of generated images |

> [!WARNING]
> **Moderate prompts and outputs**
> Image models can be prompted to produce harmful/infringing content. Apply input prompt filtering and **output moderation** (§19), and honor the provider's usage policy. Generated-image **rights and provenance** are also an active legal/ethical area — relevant if you ship generated images in a product.

---

## 6. Main takeaways

- Same fork as LLMs (§24): **managed image API** (easy, per-image) vs **self-hosted `diffusers`** (free per-image, GPU, customizable).
- Managed: `client.images.generate(prompt=...)` → image; also edits/variations/inpainting.
- Self-hosted: `diffusers` `StableDiffusionPipeline`; params **are notes 02–03** (steps, guidance_scale, negative_prompt, seed).
- `diffusers` supports **img2img, inpainting, ControlNet, LoRA** (custom styles, §21).
- It's **PyTorch (§25)** under the hood; **quantization (§21.05)** helps fit GPUs.
- **Killer pattern**: **LLM + image model** — LLM writes the prompt/copy, image model renders it; agent tool (§7).
- Apply the usual disciplines: **cost/latency (§20), safety/moderation (§19), eval (§17), serving (§24)**, plus **rights/provenance**.

---

## 7. Things I still want to figure out

- Current managed image-API options + per-image pricing?
- Minimum GPU to run Stable Diffusion comfortably (with quantization)?
- A good automated **quality proxy** (CLIP score) for image eval (§17)?

---

## 8. Things to dig into

- Provider **image API** docs (generation, edits, variations).
- Hugging Face **`diffusers`** pipelines (txt2img, img2img, inpaint, ControlNet).
- **LoRA for diffusion** (custom styles) — same idea as §21.
- Next: [[05 - Beyond Images]].

---

## 9. Next up in this section

- [ ] [[05 - Beyond Images]] — audio, video, 3D, and where generative AI is heading.

---

## Related
- [[03 - Text-to-Image Generation]] — the controls these APIs expose.
- [[01 - What is Multi-Modal AI]] — understanding (§10) + generating (here) = multi-modal apps.

## Sources
- [OpenAI images API](https://platform.openai.com/docs/guides/images)
- [Hugging Face diffusers](https://huggingface.co/docs/diffusers/)
