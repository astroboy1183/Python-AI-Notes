---
title: Guardrails and Output Validation
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 19: Safety, Security & Guardrails"
tags:
  - security
  - guardrails
  - validation
  - pydantic
  - llm-security
related:
  - "[[02 - Prompt Injection and Jailbreaks]]"
  - "[[04 - Structured Outputs with Pydantic]]"
---

# Guardrails and Output Validation

> [!NOTE]
> **TL;DR**
> **Guardrails** are programmatic checks that sit on the **input** and **output** of an LLM and enforce rules the model itself can't be trusted to follow. **Input guardrails**: block off-topic/abusive/injection-laden input before it reaches the model. **Output guardrails**: validate the model's response before it's used — is it valid JSON / schema-conforming, on-topic, free of PII/toxicity, not leaking the system prompt, not unsafe code? The key principle from §19: **never trust raw model output** — validate at the boundary, the same way you validate any external input. Implement with simple **Pydantic validation** (you already do this in §7), structured-output enforcement, dedicated frameworks (**Guardrails AI**, **NeMo Guardrails**), and **classifier "guard" models** (e.g. Llama Guard). On failure: block, regenerate, or fall back to a safe default.

> [!NOTE]
> **Where this fits**
> Third note of **Section 19** — the enforcement layer for the threats in [[02 - Prompt Injection and Jailbreaks]]. It extends the Pydantic structured outputs from [[04 - Structured Outputs with Pydantic]] into a security control.

---

## 1. What a guardrail is

A guardrail is **code around the model** that checks input/output against rules and acts on violations. The model is a probabilistic component; guardrails are the **deterministic boundary** that makes its behavior safe enough to ship.

```
input ─► [INPUT GUARDRAILS] ─► LLM ─► [OUTPUT GUARDRAILS] ─► use
          block / sanitize          validate / block / retry
```

---

## 2. Input guardrails

Checks **before** the prompt reaches the model:

| Check | Catches |
|---|---|
| Topic / relevance | off-topic abuse, scope creep |
| Injection patterns | "ignore previous instructions…" ([[02 - Prompt Injection and Jailbreaks]]) |
| Toxicity / abuse | hostile users |
| PII detection | users pasting sensitive data ([[04 - PII, Privacy and Content Moderation]]) |
| Length / cost | DoS via huge prompts |

Action on hit: **reject**, **sanitize**, or **route** to a safe handler. Cheaper to stop a bad request than to clean up after it.

---

## 3. Output guardrails — the critical ones

> [!IMPORTANT]
> **Never trust raw model output**
> The model can hallucinate, leak the system prompt, emit invalid JSON, produce toxic or off-brand text, or generate unsafe code. Output guardrails are the boundary that catches this **before** the output is shown, executed, or passed downstream.

| Check | Why |
|---|---|
| **Schema validation** | Is it valid JSON matching the expected shape? (Pydantic) |
| **Groundedness** | Is the answer supported by the provided context? (anti-hallucination, [[05 - Hallucination Mitigation]]) |
| **Toxicity / safety** | No harmful, biased, or unsafe content |
| **PII leakage** | Not exposing personal/secret data ([[04 - PII, Privacy and Content Moderation]]) |
| **Topic adherence** | Stayed on the allowed subject |
| **Prompt-leak check** | Didn't reveal the system prompt |
| **Code safety** | Generated code isn't destructive (before any execution!) |

---

## 4. The simplest guardrail: Pydantic validation

You already use this in [[04 - Structured Outputs with Pydantic]] — it's also a security control. If output must conform to a schema, **enforce it** and reject/retry on failure:

```python
from pydantic import BaseModel, field_validator

class SupportReply(BaseModel):
    answer: str
    category: str
    escalate: bool

    @field_validator("category")
    @classmethod
    def known_category(cls, v):
        if v not in {"billing", "technical", "general"}:
            raise ValueError("invalid category")
        return v

# validate model output; on ValidationError → regenerate or fall back
reply = SupportReply.model_validate_json(llm_output)
```

Structured-output / function-calling modes that *guarantee* schema-valid JSON are themselves a guardrail — they remove a whole class of "malformed output" failures.

---

## 5. The remediation strategies

When a guardrail fails, choose a response:

| Strategy | When |
|---|---|
| **Block** | Hard violation (toxic, unsafe) → refuse / safe message |
| **Regenerate** | Fixable (bad JSON, off-topic) → re-prompt, maybe with the error |
| **Fix/sanitize** | Mechanical (strip PII, redact) |
| **Fallback** | Return a safe default / escalate to human |

```python
for attempt in range(MAX_RETRIES):
    out = llm(prompt)
    try:
        return SupportReply.model_validate_json(out)   # passes guardrail
    except ValidationError as e:
        prompt = add_error_feedback(prompt, e)          # regenerate
return SAFE_FALLBACK                                    # give up safely
```

---

## 6. The tools

| Tool | Role |
|---|---|
| **Pydantic** | Schema/type validation (you already have it) |
| **Guardrails AI** | Declarative validators (structure, PII, toxicity) + auto-reask |
| **NeMo Guardrails** (NVIDIA) | Programmable conversational rails (topics, flows) |
| **Llama Guard / Prompt Guard** | Classifier models for input/output safety + injection |
| **Provider moderation APIs** | Toxicity/category classification (OpenAI Moderation, etc.) — see [[04 - PII, Privacy and Content Moderation]] |

> [!TIP]
> **Guardrails cost latency — place them wisely**
> Each check (especially classifier-model or LLM-judge guardrails) adds latency and cost. Use cheap deterministic checks (regex, schema) first and reserve model-based guards for what truly needs them. Run independent guards in **parallel** where possible. Tie failures into observability (§17) so you can see what's being blocked.

---

## 7. Defense in depth (recap with §19)

No single guardrail is enough — combine with the structural defenses from [[02 - Prompt Injection and Jailbreaks]]:

```
input guards → hardened prompt → least-privilege tools → output guards → human approval → monitoring
```

Guardrails are the **validation** layers; least privilege + approval limit the **blast radius**; monitoring catches what slips through.

---

## 8. Main takeaways

- **Guardrails** = deterministic code around the model enforcing rules it can't be trusted to follow.
- **Input guardrails**: block off-topic/abusive/injection input before the model.
- **Output guardrails**: validate before use — schema, groundedness, toxicity, PII, prompt-leak, code safety.
- **Never trust raw model output** — validate at the boundary.
- Simplest guardrail = **Pydantic** schema validation (you already use it).
- On failure: **block / regenerate / sanitize / fallback**.
- Tools: **Guardrails AI, NeMo Guardrails, Llama Guard**, moderation APIs.
- Guards cost latency — **cheap checks first, model guards sparingly, in parallel**.
- Combine with **least privilege + human approval + monitoring** (defense in depth).

---

## 9. Things I still want to figure out

- Best way to check **groundedness** cheaply at runtime (not full RAGAS)?
- How much latency do classifier guards (Llama Guard) add?
- Build vs adopt — when is **Guardrails AI/NeMo** worth the dependency?

---

## 10. Things to dig into

- **Guardrails AI**: https://www.guardrailsai.com/
- **NeMo Guardrails** (NVIDIA).
- **Llama Guard** model card.
- Next: [[04 - PII, Privacy and Content Moderation]].

---

## 11. Next up in this section

- [ ] [[04 - PII, Privacy and Content Moderation]] — handling personal data and harmful content.

---

## Related
- [[02 - Prompt Injection and Jailbreaks]] — threats these guardrails defend against.
- [[04 - Structured Outputs with Pydantic]] — the validation primitive, as a security control.

## Sources
- [Guardrails AI](https://www.guardrailsai.com/)
- [NeMo Guardrails](https://github.com/NVIDIA/NeMo-Guardrails)
