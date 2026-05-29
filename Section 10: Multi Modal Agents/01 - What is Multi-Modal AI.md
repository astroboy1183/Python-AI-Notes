---
title: What is Multi-Modal AI
date: 2026-05-29
source: "Section 10 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 10: Multi Modal Agents"
tags:
  - multimodal
  - llm
  - vision
  - images
  - audio
  - foundations
related:
  - "[[02 - Coding a Multi-Modal Image Agent]]"
---

# What is Multi-Modal AI

> [!abstract] TL;DR
> **Multi-modal AI** (the "modal" with an **A** — *modality*, not "model") refers to models that can take in **more than one type of data** — text, images, audio, video — and reason across them, instead of being limited to text-in / text-out. The model I've been using so far (GPT-4.1 mini) is already multi-modal on the input side: its `content` field can be an **array** mixing a `text` part and an `image_url` part, so I can hand it a picture and ask "what's in this image?". Older models like GPT-3.5 Turbo are **text-to-text only** — they cannot see images at all. The key mental shift: a message's `content` stops being a single string and becomes a **list of typed parts**.

> [!info] Where this fits
> First note of **Section 10: Multi Modal Agents**. This one is conceptual — what "multi-modal" means and how to spot which models support it. The next note ([[02 - Coding a Multi-Modal Image Agent]]) puts it into practice by sending an image to the model and getting a caption back.

---

## 1. The word that trips everyone up: *modal* vs *model*

This is the single most important distinction in the whole topic, and it's easy to misread.

| Term | Meaning |
|---|---|
| **Multi-model** | Multiple *models* working together (an ensemble, a pipeline of several LLMs). **Not** what this is about. |
| **Multi-modal** (with an **A**) | A *single* model that accepts multiple **modalities** — text, image, audio, video. **This** is the topic. |

A **modality** is just a *type* of data. Text is one modality. An image is another. Audio is a third. "Multi-modal" = "many data types."

> [!tip] How to keep it straight
> Read it as **multi-*modality* AI**. The model understands more than one *kind* of input. The extra "A" is doing real work — it changes the meaning from "many models" to "many senses."

---

## 2. What multi-modal AI actually is

> [!note] Definition
> Multi-modal AI refers to artificial-intelligence systems that **process and integrate information from multiple data types** — such as text, images, audio, and more — within a single model.

So far my mental model of an LLM has been:

```
text in  ──►  [ LLM ]  ──►  text out
```

A multi-modal model widens the **input** side:

```
text   ┐
image  ├──►  [ multi-modal LLM ]  ──►  text out
audio  ┘
```

The model can *look* at an image, *listen* to audio, or *read* text — and then respond. Most of today's accessible models are multi-modal on **input** but still **text on output** (more on that below).

---

## 3. Input modality ≠ output modality

A subtle but important point: a model can support a modality as **input** without supporting it as **output**.

GPT-4.1 mini (and GPT-4o mini) is a good example:

| Direction | Modalities supported |
|---|---|
| **Input** | text **+ images** |
| **Output** | text only |

So I can *show* it a picture, but it can't *draw* one back — it answers in words. Generating images is a different capability (e.g. DALL·E / `gpt-image-1`), and generating audio is yet another (TTS models). "Multi-modal" doesn't automatically mean "can produce every modality" — it's worth checking input vs output support per model.

---

## 4. Spotting which models are multi-modal

On the OpenAI models page, each model lists its supported input and output modalities explicitly. The contrast is stark between generations:

| Model | Input | Output | Multi-modal? |
|---|---|---|---|
| **GPT-3.5 Turbo** (older) | text | text | ❌ text-to-text only |
| **GPT-4o mini** | text, **image** | text | ✅ input vision |
| **GPT-4.1 mini** | text, **image** | text | ✅ input vision |
| **GPT-4o** | text, **image**, **audio** | text (+ audio in realtime variants) | ✅ richer |

The lesson: **don't assume**. Before sending an image, confirm the chosen model actually lists image as a supported input — otherwise the call fails or the image is ignored.

> [!warning] Old models can't see
> If I accidentally point a vision request at something like GPT-3.5 Turbo, it has no image-input capability at all. The fix is always to pick a model whose spec sheet lists **image** (or whatever modality I need) as an input.

---

## 5. The structural change: `content` becomes an array

This is the part that actually matters for code. In a normal text chat, a message looks like:

```python
{ "role": "user", "content": "Explain arrow functions in JavaScript" }
```

`content` is a plain **string**.

For multi-modal input, `content` becomes an **array of typed parts**:

```python
{
    "role": "user",
    "content": [
        { "type": "text",      "text": "What is in this image?" },
        { "type": "image_url", "image_url": { "url": "https://.../photo.jpg" } },
    ],
}
```

Each element declares its own `type`. The model reads the whole list together — it sees the question *and* the picture as one combined prompt.

```
content (string)              content (array of parts)
──────────────────            ─────────────────────────
"some text"            ──►     [ {type: text,  ...},
                                 {type: image_url, ...},
                                 {type: text,  ...}, ... ]
```

I can mix and order parts freely — multiple text parts, multiple images, interleaved. The model treats it as one coherent message.

---

## 6. Two ways to supply an image

| Method | How | When to use |
|---|---|---|
| **Public URL** | `image_url.url = "https://..."` | Image is already hosted somewhere reachable. Simplest — preferred. |
| **Base64 data URL** | Read a local file, encode to base64, pass as `data:image/jpeg;base64,...` | Image lives only on disk and isn't publicly hosted. |

The URL method is cleaner when the image is online; the base64 method is the escape hatch for local files. Both end up in the same `image_url` field — the only difference is whether the string is an `http(s)://` link or a `data:` URL. (The hands-on next note uses a public URL.)

---

## 7. Why this matters — what it unlocks

Once a model can ingest images (and beyond), a whole category of apps opens up:

- **Image captioning / description** — "describe this photo" (exactly what the next note builds).
- **OCR-style extraction** — read text out of a screenshot or scanned document.
- **Visual Q&A** — "how many people are in this picture?", "what's the error in this diagram?".
- **Chart / table understanding** — interpret a graph image.
- **Accessibility** — auto-generate alt-text.
- **Multi-modal agents** — an agent that can *look* at a screen, *read* a chart, and act on what it sees.

The trajectory is clear: input modalities keep expanding (image → audio → video), and over time more models will support more varied inputs *and* outputs.

---

## 8. Main takeaways

- **Multi-modal** = one model, many **modalities** (data types). Not "multi-model" (many models).
- A modality is a *kind* of data: text, image, audio, video.
- Most current accessible models are multi-modal on **input**, **text** on output.
- **Input support ≠ output support** — check each separately.
- Old models (GPT-3.5 Turbo) are **text-to-text only**; GPT-4o / 4.1 family can take images.
- The code change: a message's `content` goes from a **string** to an **array of typed parts** (`text`, `image_url`, …).
- Images can be supplied as a **public URL** (preferred) or a **base64 data URL** (for local files).
- This unlocks captioning, OCR, visual Q&A, chart reading, and multi-modal agents.

---

## 9. Things I still want to figure out

- How are images **tokenized / priced**? A high-res image clearly isn't "free" — how is its cost computed?
- Is there a **resolution limit** or auto-downscaling on uploaded images?
- For **audio input**, what does the `content` part look like — is it the same array pattern?
- How do **video** inputs work — frame sampling, or native video understanding?
- When does **base64** become impractical (large files, request-size limits)?

---

## 10. Things to dig into

- **OpenAI vision guide**: https://platform.openai.com/docs/guides/vision
- **Model spec pages** — practice reading the input/output modality table for several models.
- **Image input pricing** — find how image tokens are counted.
- **Hands-on**: build the captioning agent in the next note, then swap in my own image.

---

## 11. Next up in this section

Turn the concept into working code:

- [ ] [[02 - Coding a Multi-Modal Image Agent]] — pass an image URL to the model and have it generate a caption.

---

## Related
- [[02 - Coding a Multi-Modal Image Agent]] — the hands-on counterpart to this concept.

## Sources
- [OpenAI vision guide](https://platform.openai.com/docs/guides/vision)
- [OpenAI models reference](https://platform.openai.com/docs/models)
