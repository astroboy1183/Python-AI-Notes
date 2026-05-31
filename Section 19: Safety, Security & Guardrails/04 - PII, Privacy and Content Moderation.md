---
title: PII, Privacy and Content Moderation
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 19: Safety, Security & Guardrails"
tags:
  - security
  - privacy
  - pii
  - moderation
  - compliance
related:
  - "[[03 - Guardrails and Output Validation]]"
  - "[[09 - Building a Memory-Aware Assistant]]"
---

# PII, Privacy and Content Moderation

> [!NOTE]
> **TL;DR**
> Two related safety duties. **Privacy/PII**: LLM apps handle personal data (names, emails, payment info) and can leak it three ways — into **logs/traces**, into a **provider's API** (and possibly its training data), or **across users** (memory/RAG returning someone else's data). Defenses: **detect and redact PII** before logging or sending, **scope data per user** (the `user_id` discipline from §13), mind **data residency / retention**, and prefer providers with no-training guarantees (or self-host for sensitive data). **Content moderation**: classify input *and* output for harmful categories (hate, violence, self-harm, sexual, etc.) using moderation APIs or classifier models, and block/escalate. Both are partly **legal/compliance** matters (GDPR, etc.), not just engineering.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 19**, a specific application of the guardrails from [[03 - Guardrails and Output Validation]]. Directly relevant to the memory systems (§13–14) that *store* user data and the tracing (§17) that *logs* it.

---

## 1. Where PII leaks

```
user data ─┬─► LOGS / TRACES        (captured by observability §17)
           ├─► PROVIDER API         (sent to OpenAI/Anthropic/etc.)
           └─► OTHER USERS          (memory/RAG returns it to the wrong person)
```

| Leak path | Risk | Mitigation |
|---|---|---|
| **Logging** | PII sits in plaintext logs/traces forever | **Redact before logging**; scrub trace payloads |
| **Provider** | Data leaves your control; possible training use | Redact; pick no-train/zero-retention tiers; self-host (§5/§6) for sensitive data |
| **Cross-user** | Memory/RAG returns user A's data to user B | **Scope by `user_id`** (§13); metadata-filter retrieval (§18) |

> [!WARNING]
> **Observability and privacy are in tension**
> Tracing (§17) captures inputs/outputs at every step — exactly where PII accumulates. Capture is good for debugging, dangerous for privacy. Redact PII *before* it's stored in traces/logs, and restrict who can view them.

---

## 2. Detecting and redacting PII

Find PII, then mask it before logging/sending:

```
"Email jayanth@example.com about order 4471"
        ─► detect ─► "Email <EMAIL> about order <ORDER_ID>"
```

Tools: **Microsoft Presidio** (open-source PII detection + anonymization), cloud DLP services, or regex for structured types (emails, cards, SSNs). For reversible flows, **tokenize** (replace with a placeholder, restore after the model responds) so the model can still reason without seeing raw PII.

---

## 3. Cross-user data isolation

The memory/RAG systems built earlier *store user data* — the leak risk is returning the wrong person's data.

> [!IMPORTANT]
> **Scope every retrieval by identity**
> The `user_id` scoping from [[09 - Building a Memory-Aware Assistant]] and `thread_id` from checkpointing (§12) are **privacy controls**, not just features. Always filter memory/vector retrieval by the requesting user (metadata filter, §18). A multi-tenant RAG bot that forgets to filter by tenant will happily surface another customer's documents.

---

## 4. Data governance basics

| Concern | Question to answer |
|---|---|
| **Retention** | How long is user data / are traces kept? Auto-delete? |
| **Residency** | Where is data stored/processed (region, jurisdiction)? |
| **Training use** | Does the provider train on my API data? (Use no-train tiers) |
| **Right to deletion** | Can a user's data (incl. memories) be fully erased? |
| **Consent** | Did the user agree to this processing? |

These map to regulations like **GDPR / CCPA**. They're compliance obligations, not optional polish — design for deletion and minimal retention from the start.

---

## 5. Content moderation

Separate from PII: filtering **harmful content** in both directions.

```
user input  ─► [moderation] ─► block harmful (e.g. self-harm, abuse) → safe response
model output ─► [moderation] ─► block harmful before showing the user
```

Typical categories: hate, harassment, violence, self-harm, sexual content, illicit/dangerous instructions.

Tools:
- **Provider moderation APIs** (e.g. OpenAI Moderation) — cheap/free classifier over categories.
- **Classifier guard models** (**Llama Guard**) — open, self-hostable input/output safety classification.
- Custom classifiers for domain-specific policy.

> [!TIP]
> **Moderate input *and* output**
> Moderating only input misses cases where a benign prompt elicits harmful output (or a jailbreak succeeds). Moderating only output wastes a generation on clearly abusive input. Do both; they're cheap relative to the main LLM call. Route serious categories (e.g. self-harm) to **specialized safe responses / human escalation**, not just a generic refusal.

---

## 6. Putting it together

```
input → [PII redact] → [moderation] → LLM (user-scoped memory/RAG)
      → [PII redact] → [moderation] → output
      → traces with PII scrubbed (§17), retention-limited
```

This is the privacy/safety slice of the defense-in-depth stack from [[01 - The AI Security Landscape]].

---

## 7. Main takeaways

- PII leaks via **logs/traces**, the **provider API**, or **across users**.
- **Redact PII before logging/sending**; tokenize for reversible flows (Presidio, DLP).
- **Observability vs privacy** tension — scrub trace payloads.
- **Scope retrieval by `user_id`/tenant** — memory/RAG isolation is a privacy control.
- Mind **retention, residency, training-use, deletion, consent** (GDPR/CCPA).
- **Content moderation**: classify harmful categories on **input and output**; block/escalate.
- Tools: **OpenAI Moderation, Llama Guard**, custom classifiers.
- Much of this is **legal/compliance**, not just engineering.

---

## 8. Things I still want to figure out

- Best **PII detection** approach (Presidio vs regex vs LLM) per data type?
- How to support **right-to-deletion** across vector + graph memory cleanly?
- Which providers offer real **no-training / zero-retention** guarantees?

---

## 9. Things to dig into

- **Microsoft Presidio** (PII detection/anonymization).
- **OpenAI Moderation API**; **Llama Guard**.
- **GDPR** essentials for AI products.
- Next: [[05 - Hallucination Mitigation]].

---

## 10. Next up in this section

- [ ] [[05 - Hallucination Mitigation]] — keeping the model from confidently making things up.

---

## Related
- [[03 - Guardrails and Output Validation]] — the mechanism for these checks.
- [[09 - Building a Memory-Aware Assistant]] — `user_id` scoping as privacy control.

## Sources
- [Microsoft Presidio](https://microsoft.github.io/presidio/)
- [OpenAI Moderation](https://platform.openai.com/docs/guides/moderation)
