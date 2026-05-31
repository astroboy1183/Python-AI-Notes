---
title: The AI Security Landscape
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 19: Safety, Security & Guardrails"
tags:
  - security
  - safety
  - threat-model
  - llm-security
  - foundations
related:
  - "[[02 - Prompt Injection and Jailbreaks]]"
  - "[[03 - Guardrails and Output Validation]]"
---

# The AI Security Landscape

> [!NOTE]
> **TL;DR**
> The moment an LLM app accepts untrusted input, calls tools, or touches private data, it has an **attack surface** — and LLM security is genuinely different from normal app security because the "code" is **natural language** that can't be cleanly separated from data. The flagship reference is the **OWASP Top 10 for LLM Applications**, which catalogs the big risks: **prompt injection** (#1), insecure output handling, training-data poisoning, sensitive-info disclosure, excessive agency (over-powerful tools), and more. The core defensive mindset: **never trust model input or output**, apply **least privilege** to tools, validate everything at the boundaries, and assume the model *can and will* be manipulated. This section maps the threats; the following notes go deep on the most important ones.

> [!NOTE]
> **Where this fits**
> First note of **Section 19: Safety, Security & Guardrails**. It frames the threat model; [[02 - Prompt Injection and Jailbreaks]], [[03 - Guardrails and Output Validation]], [[04 - PII, Privacy and Content Moderation]], and [[05 - Hallucination Mitigation]] drill into specifics. Especially relevant to the tool-using agents (§7), MCP (§16), and RAG (§8) already built.

---

## 1. Why LLM security is different

In normal software, **code** and **data** are separate — SQL injection is dangerous precisely because data leaks into the code channel, and we fix it with parameterization. LLMs have **no such separation**:

```
system prompt (instructions) ┐
retrieved docs (data)        ├─ all arrive as ONE blob of text
user message (data)          ┘   the model can't reliably tell which is which
```

> [!IMPORTANT]
> **Instructions and data share one channel**
> Everything an LLM sees is just tokens. A malicious instruction hidden inside "data" (a user message, a web page, a retrieved document) can be obeyed as if it were a legitimate command. There's no bulletproof equivalent of SQL parameterization yet — which is why prompt injection (note 02) is the #1 unsolved LLM risk.

---

## 2. The OWASP Top 10 for LLM Applications

OWASP maintains a community standard for LLM risks. The headline categories (names paraphrased; consult the current list for exact wording):

| Risk | What it is |
|---|---|
| **Prompt injection** | Malicious input overrides instructions (note 02) |
| **Insecure output handling** | Trusting LLM output downstream (e.g. eval'ing generated code, rendering raw HTML → XSS) |
| **Training-data poisoning** | Corrupting data the model learns from |
| **Model denial of service** | Expensive inputs that exhaust resources/budget |
| **Supply-chain risks** | Compromised models, datasets, plugins, packages |
| **Sensitive information disclosure** | Leaking PII, secrets, or other users' data (note 04) |
| **Insecure plugin/tool design** | Tools with too much power or poor input validation |
| **Excessive agency** | Agent can take high-impact actions without limits/approval |
| **Overreliance** | Trusting hallucinated output as fact (note 05) |
| **Model theft** | Exfiltrating proprietary models/weights |

---

## 3. The attack surface of my apps

Mapping the risks onto what's been built in this course:

| Component | Exposure |
|---|---|
| **RAG (§8)** | Retrieved docs are untrusted input → *indirect* prompt injection |
| **Agents + tools (§7)** | Tools = real-world actions → excessive agency, insecure tool design |
| **MCP (§16)** | Third-party tool servers → supply chain + excessive agency |
| **Memory (§13–14)** | Stores user data → sensitive-info disclosure, cross-user leakage |
| **Code assistant (§7)** | Executes commands → insecure output handling (running model output!) |
| **Any user-facing app** | User input → direct prompt injection, DoS via huge/expensive prompts |

> [!WARNING]
> **A tool-using agent multiplies the stakes**
> A chatbot that says something wrong is embarrassing. An **agent with tools** that gets hijacked can *delete files, send emails, spend money, or leak data*. The more capable the agent (MCP, command execution), the more security matters — manipulating the text now manipulates **actions**.

---

## 4. The core defensive principles

1. **Never trust model input** — user messages, retrieved docs, web content, tool outputs are all hostile until proven otherwise.
2. **Never trust model output** — validate/sanitize before using it downstream (especially before executing or rendering it).
3. **Least privilege for tools** — give an agent the minimum capability needed; scope tokens; sandbox execution.
4. **Human-in-the-loop for high-impact actions** — require approval before irreversible/expensive operations.
5. **Defense in depth** — input filters + system-prompt hardening + output validation + monitoring; no single layer is enough.
6. **Assume manipulation** — design as if the model *will* be tricked, and limit the blast radius.

```
untrusted input → [input guards] → LLM (hardened prompt, least-privilege tools)
                                      → [output guards] → [human approval?] → action
                                      → [observability/monitoring] (§17)
```

---

## 5. Safety vs security (two overlapping goals)

| | Security | Safety |
|---|---|---|
| Protects against | **Adversaries** (attackers exploiting the system) | **Harm** (toxic, biased, dangerous, off-brand output) |
| Examples | prompt injection, data exfiltration, tool abuse | hate speech, self-harm advice, PII leaks, hallucinations |
| Tools | input/output validation, least privilege, sandboxing | content moderation, guardrails, refusal training |

Both are covered in this section — they share machinery (guardrails) but answer different questions.

---

## 6. Main takeaways

- LLMs have **no separation of instructions and data** — both are just tokens.
- This makes **prompt injection** the #1 risk and SQL-style fixes inapplicable.
- The **OWASP Top 10 for LLMs** is the reference threat catalog.
- My RAG/agent/MCP/memory builds each expose specific risks.
- **Tool-using agents raise the stakes** — manipulation becomes real-world action.
- Core principles: **distrust input & output, least privilege, human-in-the-loop, defense in depth, assume manipulation.**
- **Security** (adversaries) and **safety** (harm) overlap but differ.

---

## 7. Things I still want to figure out

- How do production teams **actually scope** agent tool permissions?
- What's a sane **human-approval** UX for risky agent actions?
- How much does **defense in depth** cost in latency/UX?

---

## 8. Things to dig into

- **OWASP Top 10 for LLM Applications**: https://owasp.org/www-project-top-10-for-large-language-model-applications/
- **MITRE ATLAS** (adversarial ML threat matrix).
- **NIST AI Risk Management Framework**.
- Next: [[02 - Prompt Injection and Jailbreaks]].

---

## 9. Next up in this section

- [ ] [[02 - Prompt Injection and Jailbreaks]] — the #1 LLM risk in depth.

---

## Related
- [[02 - Prompt Injection and Jailbreaks]] — the top threat.
- [[03 - Guardrails and Output Validation]] — the main defense layer.

## Sources
- [OWASP Top 10 for LLM Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- [NIST AI RMF](https://www.nist.gov/itl/ai-risk-management-framework)
