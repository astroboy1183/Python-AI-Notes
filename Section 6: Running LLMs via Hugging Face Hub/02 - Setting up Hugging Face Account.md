---
title: Setting up Hugging Face Account
date: 2026-05-28
source: "Section 6 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 6: Running LLMs via Hugging Face Hub"
tags:
  - hugging-face
  - account-setup
  - signup
  - foundations
  - hands-on
related:
  - "[[01 - Intro to Hugging Face]]"
  - "[[03 - Accessing Gated Models]]"
---

# Setting up Hugging Face Account

> [!abstract] TL;DR
> Quick setup chore — sign up at **huggingface.co**, solve the captcha, choose username + full name, confirm via email. Account is free for all basic use (browsing models, downloading open weights, light Spaces usage). Paid tiers exist for **PRO** (better Spaces, faster inference) and **Enterprise** (compliance, private models). A free account is sufficient for everything in this section. After login, the account unlocks: pulling models that require authentication ([[03 - Accessing Gated Models]]), generating API tokens ([[04 - Hugging Face CLI Setup and Login]]), pushing models, creating Spaces.

> [!info] Where this fits
> Second note of **Section 6: Running LLMs via Hugging Face Hub**. Pure account-setup chore. The interesting work starts in [[03 - Accessing Gated Models]].

---

## 1. Why an account is needed at all

Most actions on Hugging Face **can** be done without an account:
- Browsing models, datasets, spaces.
- Reading docs.
- Downloading **fully open** models.
- Using public Spaces (limited).

But many useful actions require login:

| Action | Account required? |
|---|---|
| Browse | ❌ |
| Download fully-open models | ❌ |
| **Download gated models** (Gemma, Llama 3, etc.) | ✅ |
| **Generate API tokens** (for CLI / `transformers`) | ✅ |
| **Push** models / datasets / Spaces | ✅ |
| **Comment** in discussions | ✅ |
| **Run higher-tier Spaces** | ✅ (often paid) |
| **Inference Endpoints** (managed API hosting) | ✅ (paid) |

The main reason here is the **gated models** (next note) — Google's Gemma, Meta's Llama, and others require license acceptance, which needs a logged-in account.

---

## 2. The sign-up flow

### Step 1 — Visit huggingface.co
Click **Sign Up** in the top right.

### Step 2 — Captcha
A bot-detection puzzle ("select all images with hats" or similar). Standard reCAPTCHA-style flow — click through until it's satisfied.

### Step 3 — Email + password
Pick an email account that gets checked (the confirmation email arrives there). Set a strong password.

### Step 4 — Username + full name
- **Username**: globally unique, becomes part of any model/space URL (e.g., `huggingface.co/jayanth/my-model`). Choose carefully — changes later are painful.
- **Full name**: shows on the profile. Can be a pseudonym.
- Other fields (bio, company, etc.) are optional.

### Step 5 — Optional avatar
HF includes an **AI-generated avatar** generator. Type a prompt (e.g. *"tech octopus wearing specs"*) → a unique avatar is produced. Or upload a custom image. Both fine.

### Step 6 — Accept terms → submit

### Step 7 — Email confirmation
HF sends a confirmation link. Click it. Account is now active and verified.

---

## 3. Suggested settings to configure right away

After login, two settings panels are worth visiting once:

| Setting | Why |
|---|---|
| **Profile → Edit profile** | Add a one-line bio. Makes the account look real, not abandoned. |
| **Settings → Notifications** | Default notification volume is high — adjust if email gets noisy. |
| **Settings → Access Tokens** | Needed in [[04 - Hugging Face CLI Setup and Login]]. Worth bookmarking the page. |
| **Settings → SSH Keys** | For pushing repositories via SSH (not needed for this course). |
| **Settings → Billing** | Confirms free tier; only relevant if upgrading. |

---

## 4. Free vs paid tiers

| Tier | Cost | Includes |
|---|---|---|
| **Free** | $0 | Browse, download, push models/Spaces, basic Inference API |
| **PRO** | ~$9/mo | Higher Inference API rate limits, ZeroGPU access for Spaces, early features |
| **Enterprise Hub** | Custom | Private model registries, compliance, audit logs, SSO |
| **Inference Endpoints** | Pay-per-use | Managed model serving on dedicated hardware |
| **Spaces with GPU** | ~$0.40 – $4 per hour | Higher hardware tiers for Spaces |

For everything in this section → **Free tier is enough**.

---

## 5. Username choice — practical advice

Since the username becomes a permanent part of any URL:

- Use the same handle as GitHub / Twitter when possible (recognizability).
- Avoid version numbers or dates (`-2024`, `-v2`) — they age badly.
- Keep it short — URLs include it: `huggingface.co/<username>/<repo>`.
- Avoid underscores — hyphens are more URL-friendly.
- Don't use temp emails for the account — if recovery is needed later, a real email matters.

If a really cool username is already taken, claim variations early (the username "namesquatting" problem is real on HF too).

---

## 6. Multi-factor authentication (recommended)

HF supports **TOTP-based 2FA** (Settings → Account → Two-factor authentication). Worth enabling, because:
- The account gains value over time (custom models pushed, tokens generated).
- Stolen access tokens can be used to read private repos.
- A 2FA prompt is a 5-second cost for a meaningful security boost.

---

## 7. State after this step

| Component | Status |
|---|---|
| HF account | ✅ Created |
| Email confirmed | ✅ |
| Profile basics | ✅ |
| Access tokens | ❌ (Note 04) |
| Gated model access | ❌ (Note 03) |
| Local CLI / library | ❌ (Notes 04 / 05) |

---

## 8. Common gotchas

> [!warning] First-time sign-up issues

| Symptom | Cause | Fix |
|---|---|---|
| Captcha keeps failing | Borderline image classification | Try again; switch network if VPN is interfering |
| Confirmation email not arriving | Spam folder / wrong email typed | Check spam, or trigger resend |
| Username taken | Common name | Add a small unique suffix |
| Forgot password | Common | "Forgot password" link works fine |
| Region-restricted access | Some countries have restrictions on certain models | Use VPN if blocked, or skip those models |
| Login loop after MFA | Browser cookies | Clear cookies, retry |

---

## 9. Main takeaways

- Sign-up at **huggingface.co** is quick — captcha, email, username, confirm.
- **Free tier** covers everything in this section.
- Username becomes part of all repo URLs → choose deliberately.
- Account is needed for **gated models**, **API tokens**, and pushing artifacts.
- Worth enabling **2FA** right away.
- After this, the account can:
  - Accept license terms for gated models ([[03 - Accessing Gated Models]]).
  - Generate access tokens for the CLI ([[04 - Hugging Face CLI Setup and Login]]).
  - Be used by `transformers` to download authenticated models ([[05 - Using the Transformers Package]]).

---

## 10. Things to dig into

- **HF settings docs**: https://huggingface.co/docs/hub/account-management
- **Access tokens guide**: https://huggingface.co/docs/hub/security-tokens
- **HF organizations**: free for teams; useful if collaborating.

---

## 11. Next up

- [ ] [[03 - Accessing Gated Models]] — get permission to use Google's Gemma 3.

---

## Related
- [[01 - Intro to Hugging Face]] — what HF is.
- [[03 - Accessing Gated Models]] — first thing to do with the new account.

## Sources
- **HF account management docs**: https://huggingface.co/docs/hub/account-management
- **HF access tokens guide**: https://huggingface.co/docs/hub/security-tokens
- **HF pricing**: https://huggingface.co/pricing
