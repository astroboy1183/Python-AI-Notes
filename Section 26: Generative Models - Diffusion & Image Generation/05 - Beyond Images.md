---
title: Beyond Images
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 26: Generative Models - Diffusion & Image Generation"
tags:
  - generative-models
  - audio
  - video
  - multimodal
  - foundations
related:
  - "[[04 - Using Image Generation APIs]]"
  - "[[08 - TTS and the Conversational Loop]]"
---

# Beyond Images

> [!NOTE]
> **TL;DR**
> The same generative ideas extend past images. **Audio**: text-to-speech (which you already used in the voice agent, §15), music generation, and sound effects. **Video**: text-to-video and image-to-video (diffusion extended across time — the hardest, most compute-heavy modality, advancing fast). **3D**: text-to-3D assets/scenes. **Code** generation is generative too (autoregressive LLMs, §7). And the big trend is **unified multi-modal models** that natively handle text + images + audio in/out in one model — collapsing the §10 (understand) / §26 (create) split. For an app builder the practical takeaways: most of this is **API-consumed**, the **cost/latency/safety/eval** disciplines (§17/§19/§20/§24) all still apply (more so — video is expensive and slow), and the design pattern is **orchestrating multiple generative modalities** (LLM + image + audio + video) into one product. This wraps the course's gap-fill arc.

> [!NOTE]
> **Where this fits**
> Final note of **Section 26** and of the whole gap-fill set (§17–26). It generalizes image generation ([[04 - Using Image Generation APIs]]) to other modalities and ties back to the voice agent (§15).

---

## 1. Audio generation

| Type | What it does | Already seen? |
|---|---|---|
| **Text-to-speech (TTS)** | Text → spoken audio (voices, tone) | **Yes — §15** voice agent ([[08 - TTS and the Conversational Loop]]) |
| **Music generation** | Prompt → music | new |
| **Sound effects / audio** | Prompt → SFX/ambient | new |
| **Voice cloning** | Mimic a specific voice from samples | mentioned §15 |

> [!IMPORTANT]
> **You've already done generative audio**
> The voice agent's **TTS** step (§15) is generative audio — text in, novel speech out. Music/SFX generation extend the same idea to other audio. So "generation beyond text" isn't new to the course; §15 was an instance of it.

---

## 2. Video generation — the frontier

Video = images **over time**, so it's diffusion (notes 02–03) extended to maintain **temporal consistency** across frames.

| Mode | Input → output |
|---|---|
| **Text-to-video** | prompt → video clip |
| **Image-to-video** | still image → animated clip |
| **Video editing** | transform/extend existing video |

> [!WARNING]
> **Video is the most expensive and hardest modality**
> Generating coherent video means generating many frames that stay **consistent** (objects/identity/motion) — far more compute than a single image, and temporal artifacts are hard. It's advancing rapidly but is **slow and costly**; budget and latency planning (§20/§24) matter even more. Mostly API-consumed today; clips are typically short.

---

## 3. 3D and other modalities

- **Text-to-3D**: generate 3D models/assets/scenes from prompts (games, AR/VR, product design) — newer, evolving fast.
- **Code**: generative too — autoregressive LLMs (the coding assistant, §7) generate code token by token (§1). Already part of the course.
- The pattern generalizes: pick a modality, learn its distribution, generate samples (note 01).

---

## 4. The big trend: unified multi-modal models

> [!IMPORTANT]
> **The understand/create split is collapsing**
> The course separated §10 (image **understanding**) from §26 (image **creation**), but frontier models increasingly do **both natively** — one model that takes text + images + audio **in** and produces text + images + audio **out**. This unifies multi-modal input (§10) and generation (§26) into a single system, and makes building multi-modal apps simpler (one model, one API). The concepts in §10 and §26 remain the right mental model; the *implementation* is converging into unified models.

```
old:  separate models for see / hear / read / draw / speak
new:  one model: (text + image + audio) in → (text + image + audio) out
```

---

## 5. The app-builder takeaways (constant across modalities)

Whatever the modality, the same playbook from §17–24 applies:

| Discipline | Applies to all generation |
|---|---|
| **API-consumed** | You'll mostly **call** models, not train them (managed vs self-host, §24) |
| **Cost** (§20) | Per image/second/clip — video especially; watch spend |
| **Latency** (§20/§24) | Generation is slow → **async/queue (§9)**, streaming where possible |
| **Safety** (§19) | Moderate prompts **and** outputs; deepfakes/misuse risk; provider policy |
| **Eval** (§17) | Subjective quality → human/preference eval, modality-specific proxies |
| **Provenance** | Watermarking/attribution of generated media (legal/ethical) |
| **Orchestration** | Combine modalities (LLM + image + audio + video) into one product |

> [!TIP]
> **The meta-skill is orchestration, not any single modality**
> An impressive product chains generative modalities: an LLM (§7) plans and writes, an image model illustrates (§26), a TTS voice narrates (§15), maybe a video model animates — coordinated by an agent/workflow (§7/§11/§22). The value is in the **orchestration**, which is exactly what the agent/LangGraph/multi-agent sections taught.

---

## 6. Main takeaways

- Generative ideas extend to **audio** (TTS — already done in §15 — music, SFX, voice cloning), **video** (text/image-to-video; hardest + costliest), **3D**, and **code** (LLMs, §7).
- **You've already used generative audio (§15 TTS)** and generative code (§7).
- **Video** is the frontier: frames over time with temporal consistency — expensive, slow, advancing fast.
- The big trend: **unified multi-modal models** doing understand **and** create in one — collapsing the §10/§26 split.
- App-builder playbook is **constant**: mostly **API-consumed**, with **cost/latency/safety/eval/provenance** (§17–24) all applying (more so for video).
- The meta-skill is **orchestrating multiple modalities** (LLM + image + audio + video) — the agent/workflow skills from §7/§11/§22.

---

## 7. Things I still want to figure out

- Current best **video generation** options + their cost/length limits?
- How unified multi-modal models change app **architecture** (one API vs many)?
- Practical **eval** for generated audio/video quality?

---

## 8. Things to dig into

- Text-to-video and text-to-3D model landscapes (fast-moving).
- Unified multi-modal model capabilities (text+image+audio in/out).
- Provenance/watermarking standards (e.g. content credentials).

---

## 9. Section & gap-fill wrap-up

Section 26 covers **generative models**: the families (note 01), how **diffusion** works (note 02), **text-to-image** steering (note 03), **using generation APIs** (note 04), and **beyond images** (this note). It closes the **understand vs create** gap from §10.

And it closes the **whole gap-fill arc (§17–26)**: evaluation/observability (§17), advanced RAG (§18), safety (§19), cost/caching (§20), fine-tuning (§21), multi-agent (§22), advanced reasoning (§23), LLMOps (§24), ML/DL foundations (§25), and generative models (§26) — the production-readiness and depth layers on top of the original course. The recurring throughline: **build it (course), measure it (§17), make it safe/cheap/reliable (§19/§20/§24), deepen it (§21/§23/§25), and extend it across modalities and agents (§22/§26).**

---

## Related
- [[08 - TTS and the Conversational Loop]] — generative audio you already built (§15).
- [[04 - Using Image Generation APIs]] — the image-gen counterpart.
- [[01 - What is Multi-Modal AI]] — understanding side (§10), converging with generation.

## Sources
- [Hugging Face diffusers (audio/video pipelines)](https://huggingface.co/docs/diffusers/)
- [Content provenance (C2PA)](https://c2pa.org/)
