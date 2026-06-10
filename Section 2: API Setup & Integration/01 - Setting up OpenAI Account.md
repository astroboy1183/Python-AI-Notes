---
title: Setting up OpenAI Account
date: 2026-05-28
source: "Section 2 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 2: API Setup & Integration"
tags:
  - openai
  - api
  - account-setup
  - billing
  - api-keys
  - platform
  - dashboard
  - playground
  - foundations
  - hands-on
related:
  - "[[01 - What is an LLM]]"
  - "[[02 - How LLMs Work - Decoding GPT]]"
  - "[[04 - What is a Token]]"
---

# Setting up OpenAI Account

> [!NOTE]
> **TL;DR**
> Before any Python code can call GPT, the account groundwork needs to be done at **platform.openai.com**. Sign in with Google (or email), land on the **Dashboard**, then visit four key areas: **Playground** (try prompts visually), **Usage** (track token spend), **API keys** (the credentials code will use), and **Billing → Add credits** (mandatory: minimum **$5** to use the API). Once topped up and an API key is generated, the credential gets pasted into project code (typically via an environment variable). Based on my own experimentation, **$5 is more than enough for the whole course**.

> [!NOTE]
> **Where this fits**
> First note of **Section 2: API Setup & Integration** — the section's whole purpose is going from "LLM theory" (everything in Section 1) to **actually calling a real LLM from code**. This note covers the account / billing / credentials side. The next note ([[02 - Using OpenAI API in Python]]) puts those credentials to work.

> [!WARNING]
> **Cost — heads-up**
> The OpenAI API is **not free**. Every call costs money (per-token pricing), and the minimum top-up is **$5**. I've used about a few cents across many experiments — but it's still real money. If avoiding any payment is required, Gemini's API is free (covered in [[03 - Setting up Gemini API - Free Alternative]]).

---

## 1. The URL

> **platform.openai.com**

That's the landing page for everything OpenAI-related on the **developer / API** side. Not the same as `chatgpt.com`, which is the consumer chat UI.

Sign-in options:
- Continue with Google (probably easiest).
- Continue with Microsoft.
- Email + password.

Once signed in → the **Dashboard** is the central hub.

---

## 2. Dashboard tour — what's where

After login, the Dashboard exposes several sections. The ones that matter for this course:

| Section | Purpose |
|---|---|
| **Playground** | Web UI to try prompts against any model without writing code. Useful for prototyping. |
| **Usage** | Tracks tokens used, dollars spent, broken down by model and time. |
| **API keys** | Where credentials get created / revoked. The code side of the API uses keys from here. |
| **Billing** | Where money gets added. **The API doesn't work without credits.** |
| **Chat prompts** | Reusable saved prompts. Nice-to-have. |
| **Logs** | Recent API calls — what was sent, what came back. Helpful for debugging. |

---

## 3. Playground — quick visual prompting

The Playground is a graphical interface for experimenting:

- Pick a model (GPT-4o, GPT-4.1, GPT-3.5, etc.).
- Type a prompt → get a response.
- Tweak parameters like **temperature**, **max tokens**, **top_p**.
- Useful for iterating on a prompt **before** putting it into Python code.

The Playground is also there just in case I want to play around with something without writing any code.

> [!TIP]
> The Playground is the fastest way to compare two prompts side-by-side, or to gauge how a prompt will behave before committing to it in code. Iteration cycle: ~5 seconds in the Playground vs ~30 seconds in a code+run loop.

---

## 4. Usage — tracking token spend

The **Usage** page is the budget watchdog:

- Daily/weekly/monthly cost breakdown.
- Tokens consumed (input + output) per model.
- Useful for catching runaway costs from accidentally-looping scripts.

> [!NOTE]
> **Typical course-relevant costs (illustrative)**
>
> | Activity | Approx cost |
> |---|---|
> | Single "hello world" prompt with GPT-4o | < $0.001 |
> | Run all this section's experiments 10× | a few cents |
> | Build a small RAG demo with 100 chunks | ~$0.10 |
> | Heavy iteration on long prompts | $0.50 - $2 |
>
> Realistically, **$5 covers all of Section 2 plus a lot more**. Topping up more than that is rarely needed for solo learning.

Pricing reference (approximate, mid-2020s):

| Model | Input ($/M tokens) | Output ($/M tokens) |
|---|---|---|
| GPT-4o | ~$2.50 | ~$10.00 |
| GPT-4o-mini | ~$0.15 | ~$0.60 |
| GPT-4.1 | ~$2.00 | ~$8.00 |
| GPT-3.5-turbo | ~$0.50 | ~$1.50 |
| o3-mini | varies | varies |

> [!NOTE]
> Token counts come from the same tokenization seen in [[04 - What is a Token]]. Counting tokens *before* sending (with [[05 - Coding our Own Tokenizer|tiktoken]]) lets cost get estimated up front.

---

## 5. Billing — adding credits (mandatory step)

The most important step: **add money before any code can call the API.**

Path: **Settings → Billing → Add to credit balance**

Steps:
1. Click **Add credits** (or "Add to credit balance").
2. Pick an amount — **$5 minimum**.
3. Link a card (or use an existing one).
4. Pay → credits show up immediately.

The API is not free to use — every call costs money based on tokens consumed. The minimum top-up amount is **$5**, and throughout this entire course, $5 is more than enough.

After payment, the dashboard shows a **credit balance** that ticks down with each API call.

> [!WARNING]
> **Watch for auto-recharge**
> OpenAI's billing settings have an "auto-recharge when balance falls below X" option. **Default it to OFF** unless real production usage is happening. Otherwise an accidental loop could blow through hundreds of dollars without manual intervention.

> [!TIP]
> **Set a hard usage limit**
> Under **Settings → Limits → Monthly budget**, set a hard cap (e.g., $10/month). If usage exceeds that, the API stops working. Acts as a safety net for runaway scripts.

---

## 6. API keys — creating, using, revoking

API keys are the credentials code uses to authenticate.

### Creating a key
Path: **Dashboard → API keys → Create new secret key**

- Optional: name the key (e.g., `Test API key`, `hello_world`, `course-project`).
- Optional: scope it to a specific project (a feature OpenAI added later).
- Click **Create** → the key is shown **once**.

> [!WARNING]
> **One-time display**
> The full secret key is visible **only at the moment of creation**. Copy it immediately. If lost, the only option is revoke + create a new one.

### Using a key
The key is a string starting with `sk-...`. It goes into project code via:

- **Environment variable** (recommended): `OPENAI_API_KEY=sk-...` in a `.env` file or shell.
- **Direct constructor argument** (acceptable for quick tests, never for committed code): `OpenAI(api_key="sk-...")`.

### Revoking a key
Whenever a key is no longer needed (e.g., after finishing a demo or sharing the screen):
- **Dashboard → API keys → ⋯ → Revoke key**
- Revoked keys stop working immediately.
- **Always revoke any key shown on camera or shared accidentally.**

This key is what gets used across all projects — copy it once, paste it into a Python project, a Node.js project, whatever's needed, and revoke it later for safety.

---

## 7. Security — what NOT to do

A few hard rules that save real money + grief:

| Do                                        | Don't                                                 |
| ----------------------------------------- | ----------------------------------------------------- |
| ✅ Store keys in `.env` files              | ❌ Hardcode keys in source files                       |
| ✅ Add `.env` to `.gitignore`              | ❌ Commit `.env` to git                                |
| ✅ Use one key per project / environment   | ❌ Use one key everywhere — hard to revoke selectively |
| ✅ Set monthly budget limits               | ❌ Leave auto-recharge enabled by default              |
| ✅ Rotate keys periodically                | ❌ Reuse the same key for years                        |
| ✅ Revoke keys after demos / shared screen | ❌ Trust that "no one was watching"                    |

> [!WARNING]
> **Leaked keys are scanned**
> GitHub, GitLab, and other code hosts run **secret scanners** that flag committed API keys. OpenAI also revokes keys that appear in public repos automatically. But "automatic" is best-effort — by the time it triggers, a leaked key may have already been used to rack up charges. **Never commit keys, full stop.**

---

## 8. Pre-coding checklist

To be ready for [[02 - Using OpenAI API in Python]]:

- [ ] Signed into `platform.openai.com`.
- [ ] Familiar with the **Dashboard** layout.
- [ ] Added **at least $5** in credits.
- [ ] Generated an API key (and copied it somewhere safe).
- [ ] Read the security rules — never commit the key.
- [ ] Set a **monthly budget limit** as a safety net.

---

## 9. Main takeaways

- The developer side of OpenAI lives at **platform.openai.com** (different from `chatgpt.com`).
- The Dashboard's important sections: **Playground**, **Usage**, **API keys**, **Billing**.
- The API is **paid**. Minimum top-up is **$5**, which covers the whole course.
- The **Playground** is the fastest way to iterate on prompts without code.
- **Usage** tracks spend per model — useful for catching runaway costs.
- **API keys** are credentials; they're displayed **once at creation**.
- Keys go in **environment variables**, never hardcoded.
- **Revoke keys** when no longer needed, especially after demos.
- Set a **monthly budget limit** as protection against accidental loops.
- Free alternative: Gemini API (covered in [[03 - Setting up Gemini API - Free Alternative]]).

---

## 10. Things I still want to figure out

- What's the difference between **user keys** and **project keys** in OpenAI's newer hierarchy?
- How do **service accounts** work for production (long-lived, scoped credentials)?
- What's the actual pricing for batched requests / cached input tokens — are there big savings there?
- How does **usage tracking by tag** work for multi-tenant apps?
- What models actually need a credit balance, and which (if any) are free tier?
- How does OpenAI's **API access tier** system work — when do higher rate limits unlock?
- For a hobby project, is GPT-4o-mini "good enough" most of the time, given it's ~16× cheaper than GPT-4o?

---

## 11. Things to dig into

- **Docs**: https://platform.openai.com/docs — the authoritative reference.
- **Pricing**: https://openai.com/api/pricing/ — current model rates.
- **Rate limits**: https://platform.openai.com/docs/guides/rate-limits — important once usage scales.
- **OpenAI Cookbook**: https://cookbook.openai.com — open-source recipe collection.
- **Newer features**: Assistants API, Responses API, batch API — covered in later sections of the course.

---

## 12. Next up in this section

The next note takes the API key just generated and uses it to make the first real API call from Python:

- [ ] [[02 - Using OpenAI API in Python]] — install the `openai` package, load the key, run `chat.completions.create`.

After that:

- [ ] [[03 - Setting up Gemini API - Free Alternative]] — get a free Google AI Studio key.
- [ ] [[04 - Using Gemini through OpenAI SDK]] — the compatibility-layer trick so a single codebase can target either provider.

---

## Related
- [[01 - What is an LLM]] — the model behind the API.
- [[02 - How LLMs Work - Decoding GPT]] — the GPT name decoded.
- [[04 - What is a Token]] — what gets counted on the Usage page.
- [[05 - Coding our Own Tokenizer]] — counting tokens before sending to estimate cost.

## Sources
- OpenAI Platform docs: https://platform.openai.com/docs
- OpenAI Pricing: https://openai.com/api/pricing/
