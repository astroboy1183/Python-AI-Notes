---
title: Accessing Gated Models
date: 2026-05-28
source: "Section 6 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 6: Running LLMs via Hugging Face Hub"
tags:
  - hugging-face
  - gated-models
  - license
  - access-control
  - gemma
  - google
  - llama
  - meta
  - acceptable-use
  - foundations
related:
  - "[[02 - Setting up Hugging Face Account]]"
  - "[[04 - Hugging Face CLI Setup and Login]]"
---

# Accessing Gated Models

> [!NOTE]
> **TL;DR**
> Not every model on Hugging Face is freely downloadable. **Gated models** require **explicitly accepting the model's license** through the HF web UI before access is granted. The big ones: **Google Gemma (all sizes)**, **Meta Llama 3 / 3.1**, **Mistral's "Large" series** — anything from a major lab that wants to track usage or enforce acceptable-use policies. Process: visit the model page → click **Accept License** → fill in name/affiliation if asked → wait for automatic approval (usually seconds, sometimes hours). After acceptance, the same HF token used by the CLI ([[04 - Hugging Face CLI Setup and Login]]) and `transformers` library can download the gated model. The concrete example here is **Gemma 3** from Google.

> [!NOTE]
> **Where this fits**
> Third note of **Section 6: Running LLMs via Hugging Face Hub**. The gate has to be cleared before the actual model can be downloaded and run. The next two notes cover the CLI ([[04 - Hugging Face CLI Setup and Login]]) and the `transformers` library ([[05 - Using the Transformers Package]]) — both of which need authenticated access.

---

## 1. What "gated" means

Some models are **publicly visible** (you can see the model card, read the description, etc.) but **not freely downloadable**. To download or use them, an extra step is required:

> Visit the model page → see a banner saying **"Access restricted"** or **"You need to acknowledge the license to access this model."** → click **Accept** → wait briefly for approval.

After approval, the model behaves exactly like an open one for the approved user.

> [!NOTE]
> **In plain terms**
> A gated model is one where the model page is visible to everyone, but the **weights themselves** are locked behind a license acknowledgment. Some models are fully open; others require explicit permission before they can be downloaded.

---

## 2. Why models get gated

Model authors gate their releases for several reasons:

| Reason | Detail |
|---|---|
| **Track usage** | Authors want to know who's using their model (research, commercial, etc.) |
| **Enforce acceptable use** | "No deepfakes," "no weapons applications," etc. |
| **Comply with regulations** | EU AI Act, US export controls |
| **Limit liability** | License explicitly disclaims warranties + assigns responsibility |
| **Differentiate research vs commercial** | Some licenses allow research but require permission for commercial use |
| **Withdraw rights** | Author can revoke access if license is violated |

Common license families:

| License | Examples | Commercial use? |
|---|---|---|
| **Apache 2.0** | Mistral 7B base, many community models | ✅ Yes |
| **MIT** | Phi-2, lots of small models | ✅ Yes |
| **Gemma Terms of Use** | Gemma 1 / 2 / 3 | ✅ Yes (with terms) |
| **Llama 2 Community License** | Llama 2 family | ✅ Yes (with restrictions on > 700M MAU) |
| **Llama 3 Community License** | Llama 3 / 3.1 | ✅ Yes (with similar restrictions) |
| **Custom non-commercial** | Many research models | ❌ Research only |
| **OpenRAIL** | Stable Diffusion 2+, some others | ✅ Yes (with use restrictions) |

---

## 3. Gated vs ungated models — examples

| Model | Status | Notes |
|---|---|---|
| **Mistral 7B base** | Ungated | Apache 2.0; just download |
| **Llama 3 8B** | Gated | Need to accept Meta's terms |
| **Llama 3.1 405B** | Gated | Same Meta terms |
| **Gemma 2 / 3 (any size)** | Gated | Google's terms |
| **Phi 3** | Ungated | MIT license |
| **Qwen 2.5** | Ungated | Apache 2.0 |
| **DeepSeek V3 / R1** | Ungated | MIT-ish |
| **Stable Diffusion 1.5** | Ungated | OpenRAIL |
| **Stable Diffusion 3** | Gated | Stability AI terms |

> [!TIP]
> **Pattern recognition**
> **Models from the big labs (Google, Meta, Anthropic, Stability AI) are usually gated.** Models from upstart companies (Mistral, DeepSeek, Alibaba) and Microsoft are usually ungated. Smaller community fine-tunes are almost always ungated.

---

## 4. The acceptance flow — walkthrough

Walking through this for **`google/gemma-3-4b-it`** (illustrative model name; the exact variant doesn't matter).

### Step 1 — Navigate to the model page
Search "gemma 3" on Hugging Face → click into a specific Gemma 3 variant.

### Step 2 — See the gate banner
At the top of the model card, a yellow banner says:

> **"Access to this model is restricted. You need to share your contact information to access this model. Acknowledge license to access the repository."**

### Step 3 — Read the license terms
Click through to read what the user agrees to. For Gemma:
- No use for "harmful, deceptive, malicious purposes."
- No weapons / surveillance / etc.
- Compliance with Google's prohibited-use policy.
- Standard liability disclaimers.

### Step 4 — Fill in any required info
Some gated models ask for:
- Affiliation (company / university / "individual").
- Country of residence.
- Intended use (research / commercial / hobby).

For Gemma: minimal — mostly just acknowledgment.

### Step 5 — Click Accept
Two clicks usually: an Accept on the form, then a confirmation. Once both go through, the page shows a "you have been granted access to this model" banner.

### Step 6 — Wait for approval
Usually **instantaneous** for Gemma and similar self-serve gates. Some labs (e.g., Stability for SD 3) take hours or days. A banner appears confirming access.

### Step 7 — Done
The model is now usable by anything authenticated as this HF account: CLI downloads, `transformers` library, Inference Endpoints, etc.

---

## 5. What "access granted" means technically

After approval, HF associates the **account** with the **approved-models list**:

```
user: jayanth
├── approved_models:
│   ├── google/gemma-3-4b-it
│   ├── google/gemma-2-2b
│   └── meta-llama/Meta-Llama-3-8B-Instruct
└── (any other gates accepted)
```

Any **HF access token** generated under this account can now download those models. Tokens generated **before** the acceptance also gain access automatically.

> [!WARNING]
> **Access is per-account, not per-token**
> Multiple tokens under one account share the same approved-models set. But two **different accounts** must each accept the license separately.

---

## 6. Browsing all approved gates

To see what gates have been accepted: **Settings → Gated repositories you have access to**. Useful for:
- Auditing which approvals exist.
- Confirming approval went through after submitting.
- Discovering when an approval is **pending** (some gates require manual review).

---

## 7. When access is denied or revoked

Some scenarios:

| Situation | What happens |
|---|---|
| Acceptance pending manual review | Banner says "Your request is pending" — wait |
| Country restricted | Some models can't be accessed from certain countries (export controls) |
| License terms violated | Author can revoke access at any time |
| Email unverified | Some gates require a verified work email |
| Bot suspicion | If too many models accepted too fast, HF may flag the account |

---

## 8. The path forward

After this step, the account should have at least **one Gemma 3 variant approved**. That model becomes the target for [[05 - Using the Transformers Package]].

> [!NOTE]
> **Specific model to accept**
> Going with **`google/gemma-3-4b-it`**. Any Gemma 3 instruction-tuned variant works:
> - `google/gemma-3-1b-it` — smallest, fastest.
> - `google/gemma-3-4b-it` — middle ground (the one I'll use).
> - `google/gemma-3-12b-it` — larger, slower.
> - `google/gemma-3-27b-it` — biggest, needs GPU.
>
> For a laptop, pick the **1B or 4B** size.

---

## 9. Alternative — completely ungated models

For learning, if dealing with gates feels like friction:

| Recommendation | Why |
|---|---|
| **`microsoft/Phi-3-mini-4k-instruct`** | MIT license; small (3.8B); good quality |
| **`Qwen/Qwen2.5-1.5B-Instruct`** | Apache 2.0; tiny; multilingual |
| **`mistralai/Mistral-7B-Instruct-v0.3`** | Apache 2.0; the original instruction-tuned Mistral |
| **`HuggingFaceTB/SmolLM2-1.7B-Instruct`** | HF's own small instruction-tuned model |

All work with the same `transformers` library calls — drop-in alternative to Gemma 3 if accepting the Google license is undesirable.

---

## 10. Common gotchas

> [!WARNING]
> **Issues to watch for**

| Symptom | Cause | Fix |
|---|---|---|
| "Access denied" after acceptance | Caching | Wait a minute, refresh |
| Approval pending forever | Manual-review gate | Email the model author or move on to a different model |
| Token doesn't work | Token created before gate accepted, but actually it should still work — try regenerating |
| Country error | Export restriction | Use an alternative model |
| "401 Unauthorized" in `transformers` | Token missing or expired | Re-login via CLI ([[04 - Hugging Face CLI Setup and Login]]) |

---

## 11. Main takeaways

- **Gated models** require explicit license acceptance before download.
- Common gated models: **Gemma (all sizes)**, **Llama 3 family**, **some Stability AI models**.
- Acceptance is **per-account, not per-token**.
- The flow: model page → accept license → wait for approval → download as normal.
- Approval is usually **instant** for self-serve gates; manual-review ones take hours/days.
- After acceptance, the model works with any tool authenticated to the account: CLI, `transformers`, Inference Endpoints.
- **Ungated alternatives** exist (Phi-3, Qwen 2.5, Mistral 7B) if the gate is undesirable.
- Pattern: big-lab models gated; community / Microsoft / Chinese-lab models usually ungated.

---

## 12. Things I still want to figure out

- For **commercial production use**, which gates have the strictest revocation language?
- How does Meta's "700M MAU" clause on Llama actually get enforced?
- Are there gates that **expire** and need re-acceptance?
- What's the **automation policy** — can a CI/CD pipeline accept gates programmatically?
- What's the right model card field to check for **commercial use** allowed without gate?
- Does HF rate-limit acceptances? (Suspect yes — accepting 100 in 10 minutes probably flags the account.)

---

## 13. Things to dig into

- **Gemma terms**: https://ai.google.dev/gemma/terms
- **Llama 3 license**: https://llama.meta.com/llama3/license/
- **OpenRAIL licenses**: https://www.licenses.ai
- **Hugging Face license docs**: https://huggingface.co/docs/hub/repositories-licenses

---

## 14. Next up in this section

With the gate cleared, the next step is authenticated CLI access:

- [ ] [[04 - Hugging Face CLI Setup and Login]] — install `huggingface-cli` and log in with an access token.

---

## Related
- [[02 - Setting up Hugging Face Account]] — must be logged in to accept gates.
- [[04 - Hugging Face CLI Setup and Login]] — token-based auth that uses the accepted gates.
- [[05 - Using the Transformers Package]] — actually download and run the gated model.

## Sources
- **Gemma terms**: https://ai.google.dev/gemma/terms
- **Llama 3 license**: https://llama.meta.com/llama3/license/
- **OpenRAIL licenses**: https://www.licenses.ai
- **HF licenses docs**: https://huggingface.co/docs/hub/repositories-licenses
- **HF gated repos docs**: https://huggingface.co/docs/hub/models-gated
