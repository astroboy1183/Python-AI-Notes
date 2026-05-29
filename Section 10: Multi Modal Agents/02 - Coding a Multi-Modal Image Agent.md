---
title: Coding a Multi-Modal Image Agent
date: 2026-05-29
source: "Section 10 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 10: Multi Modal Agents"
tags:
  - multimodal
  - vision
  - openai
  - python
  - image-captioning
  - hands-on
related:
  - "[[01 - What is Multi-Modal AI]]"
---

# Coding a Multi-Modal Image Agent

> [!NOTE]
> **TL;DR**
> Build the smallest possible vision agent: create an OpenAI client, then call `client.chat.completions.create` with a **multi-modal `content` array** — one `text` part ("generate a caption for this image in ~50 words") and one `image_url` part pointing at a publicly hosted photo. Pick a model that supports image input (GPT-4o / 4.1 mini). The response comes back as **text** describing the picture. For a coding-themed stock photo, the model returned something like *"A cheerful young man proudly holds up a sticky note with the word 'code' written on it, emphasizing his passion for programming."* — an accurate description of the image it was given. Local files work too, via **base64**, but a public URL is the cleaner default.

> [!NOTE]
> **Where this fits**
> Second note of **Section 10: Multi Modal Agents**, and the hands-on follow-up to [[01 - What is Multi-Modal AI]]. It turns the "content can be an array" idea into a running script.

---

## 1. The goal

Send a model **two things in one message** — an instruction *and* an image — and get back a written caption. That's the entire exercise, and it's the canonical "hello world" of multi-modal work.

```
[ "caption this" + image ]  ──►  [ GPT-4.1 mini ]  ──►  "A cheerful young man holding a 'code' note..."
```

---

## 2. Project skeleton

A fresh folder, one file:

```
image/
├── main.py
└── .env          # OPENAI_API_KEY=sk-...
```

`.env` holds the key; it gets loaded into the environment so the client picks it up automatically.

> [!WARNING]
> **Keep the key out of git**
> Add `.env` to `.gitignore`. Never hardcode the key in `main.py`. If a key ever leaks, **revoke it** and mint a fresh one from the API dashboard — old keys can and should be rotated.

---

## 3. The boilerplate

```python
# main.py
from dotenv import load_dotenv
load_dotenv()                 # read .env into environment variables

from openai import OpenAI

client = OpenAI()             # API key auto-read from OPENAI_API_KEY env var
```

Nothing new here versus earlier sections — `load_dotenv()` first, then construct the client. The key is read implicitly from the environment, so it never appears in code.

---

## 4. Picking the image

Any publicly reachable image URL works. A stock-photo site (Pexels, Wikimedia, etc.) is an easy source — search a theme (e.g. "coding"), open a photo, and copy its direct image link.

> [!IMPORTANT]
> **It must be a *direct, public* image URL**
> The URL has to point straight at the image file and be reachable without login. A good sanity check: paste the URL into a fresh browser tab — if the raw image loads, the model can fetch it too. A link to a *webpage that contains* the image is not the same as the image's own URL.

---

## 5. The full script

```python
# main.py
from dotenv import load_dotenv
load_dotenv()

from openai import OpenAI

client = OpenAI()

IMAGE_URL = "https://images.pexels.com/photos/.../coding.jpeg"

response = client.chat.completions.create(
    model="gpt-4.1-mini",                  # must support image input
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "Generate a caption for this image in about 50 words.",
                },
                {
                    "type": "image_url",
                    "image_url": {"url": IMAGE_URL},
                },
            ],
        }
    ],
)

print(response.choices[0].message.content)
```

Run it:

```bash
cd image
python main.py
```

After a short pause (the model fetches and "looks at" the image), it prints a caption.

---

## 6. Anatomy of the multi-modal message

The one structural difference from a plain text call is the `content` **array**:

| Part | Field | Purpose |
|---|---|---|
| Text part | `{"type": "text", "text": "..."}` | The instruction / question |
| Image part | `{"type": "image_url", "image_url": {"url": "..."}}` | The picture to analyze |

Both live inside the **same** user message's `content` list. The model reads them together — instruction + image as one combined prompt. Note the nesting: `image_url` is a key whose value is itself an object `{"url": ...}` (not just the raw string) — an easy thing to get wrong.

```
messages
└── { role: "user",
      content: [                      ← array, not a string
        { type: "text",      text: "Generate a caption..." },
        { type: "image_url", image_url: { url: "https://..." } }
      ] }
```

---

## 7. Reading the response

The response shape is identical to a normal chat completion — the image was only an *input*; the output is plain text:

```python
response.choices[0].message.content
```

For the coding-themed photo, the result was along the lines of:

> A cheerful young man proudly holds up a sticky note with the word "code" written on it, emphasizing his passion for programming.

That's a faithful description of the supplied image — proof the model actually "saw" the picture rather than guessing from the prompt alone.

---

## 8. Local files — the base64 alternative

If the image isn't hosted anywhere and lives only on disk, encode it to **base64** and pass a `data:` URL instead of an `http` URL:

```python
import base64

def to_data_url(path: str, mime: str = "image/jpeg") -> str:
    with open(path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("utf-8")
    return f"data:{mime};base64,{b64}"

# ...
{
    "type": "image_url",
    "image_url": {"url": to_data_url("local_photo.jpg")},
}
```

| Approach | Pros | Cons |
|---|---|---|
| **Public URL** | Tiny request, simplest | Image must be hosted & reachable |
| **Base64 data URL** | Works for purely local files, no hosting | Bloats the request (base64 is ~33% larger than the raw bytes) |

The URL route is the cleaner default; base64 is the fallback when there's no public URL to point at.

---

## 9. Common gotchas

> [!WARNING]
> **Vision request issues**

| Symptom | Cause | Fix |
|---|---|---|
| Error / image ignored | Model doesn't support image input | Use GPT-4o / 4.1 mini, not 3.5 Turbo |
| `content` rejected | Sent a string instead of the array of parts | Use the typed-parts list |
| Model "can't access" the image | URL needs login / isn't a direct image link | Use a public, direct image URL |
| `AuthenticationError` | Key missing/revoked | Refresh `.env`, mint a new key |
| `image_url` malformed | Passed a bare string instead of `{"url": ...}` | Wrap it in the object form |
| Huge/slow request | Base64 of a large image | Prefer a hosted URL, or downscale first |

---

## 10. Main takeaways

- A vision call is a normal `chat.completions.create` with a **multi-modal `content` array**.
- The array mixes a `text` part (the instruction) and an `image_url` part (the picture).
- The chosen **model must support image input** (GPT-4o / 4.1 mini).
- `image_url` takes a nested object: `{"url": "..."}`, not a bare string.
- The **response is plain text** — read it from `response.choices[0].message.content`.
- Images can be a **public URL** (preferred) or a **base64 data URL** (local files).
- Sanity-check a URL by opening it in a browser — if the raw image loads, the model can fetch it.
- Keep the API key in `.env`, gitignored, and revoke/rotate if leaked.

---

## 11. Things I still want to figure out

- Can I send **multiple images** in one message and have the model compare them?
- How does **prompt phrasing** change caption quality (tone, length, focus)?
- What's the **token/cost** impact of an image versus a text-only prompt?
- Does image **resolution** noticeably change accuracy or cost?
- How to make captions **structured** (e.g. force JSON with objects, colours, text-found)?

---

## 12. Things to dig into

- **OpenAI vision guide**: https://platform.openai.com/docs/guides/vision
- **Structured outputs** — combine vision with a Pydantic schema for typed image analysis.
- **Hands-on**: swap in my own photo, then try base64 with a local file; compare request size and latency.

---

## Related
- [[01 - What is Multi-Modal AI]] — the concept this note implements.

## Sources
- [OpenAI vision guide](https://platform.openai.com/docs/guides/vision)
- [OpenAI chat completions reference](https://platform.openai.com/docs/api-reference/chat)
