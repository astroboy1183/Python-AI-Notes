---
title: Tracing and Observability
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 17: Evaluation & Observability"
tags:
  - observability
  - tracing
  - langsmith
  - langfuse
  - llmops
  - monitoring
related:
  - "[[04 - Evaluating RAG with RAGAS]]"
  - "[[01 - Why Evaluation Matters]]"
---

# Tracing and Observability

> [!NOTE]
> **TL;DR**
> Evaluation tells me if my app is good on a **fixed test set**; **observability** tells me what's actually happening on **live traffic**. The core primitive is a **trace** — a structured record of one request as it flows through every step (prompt → retrieval → tool calls → LLM calls → response), with inputs, outputs, token counts, latency, and cost captured at each **span**. Tools like **LangSmith** and **Langfuse** capture these automatically and give dashboards for debugging ("why did *this* request fail?"), monitoring (latency/cost/error trends), and **online eval** (collect 👍/👎 feedback, sample-judge production outputs). The big win: when an agent misbehaves in production, a trace shows the **exact step** that broke — invaluable for the multi-step agents, RAG, and LangGraph workflows built earlier.

> [!NOTE]
> **Where this fits**
> Final note of **Section 17**. Where [[01 - Why Evaluation Matters]] covered offline eval, this covers the **online/production** half — and closes the loop by feeding real failures back into the test set.

---

## 1. Eval vs observability

| | Evaluation | Observability |
|---|---|---|
| Question | "Is it good on my test set?" | "What's happening in production?" |
| Data | Curated, fixed | Live, real traffic |
| Output | A score | Traces, metrics, alerts |
| Use | Gate changes pre-ship | Debug, monitor, catch drift |

They're complementary: eval **before** shipping, observability **after**. Production traces also *become* new eval cases.

---

## 2. The core primitive: a trace

A **trace** records one end-to-end request as a tree of **spans** (sub-steps):

```
TRACE: "user asks about refund policy"        (2.4s, $0.003, 1,850 tokens)
├─ span: embed query                          (40ms)
├─ span: vector search (Qdrant)               (90ms, 5 chunks)
├─ span: rerank                               (120ms → top 3)
├─ span: LLM call (gpt-4.1-mini)              (2.1s, 1,850 tok, $0.003)
│    ├─ input:  system + context + question
│    └─ output: "Our refund policy is..."
└─ span: guardrail check                      (30ms, pass)
```

Each span captures **input, output, latency, token usage, cost, metadata**. The trace makes a black-box request **inspectable**.

> [!IMPORTANT]
> **Tracing is the debugger for LLM apps**
> A multi-step agent that gives a wrong answer is nearly impossible to debug from the final output alone. A trace shows *which* step failed — the retriever returned junk, the tool call had bad args, the prompt was malformed. Without it, debugging is guesswork.

---

## 3. What to capture

| Signal | Why it matters |
|---|---|
| **Inputs/outputs per step** | Debug *where* it went wrong |
| **Token usage** | Cost tracking (§20) |
| **Latency per span** | Find the slow step |
| **Cost** | Per-request, per-user, per-feature spend |
| **Errors / retries** | Reliability monitoring (§24) |
| **Tool calls** | Did the agent pick the right tool/args? |
| **User feedback** (👍/👎) | Online quality signal |
| **Metadata** (user, session, version) | Slice metrics; trace per user |

---

## 4. The tools

| Tool | Notes |
|---|---|
| **LangSmith** | From the LangChain team; deep LangChain/LangGraph integration; tracing + eval + datasets |
| **Langfuse** | Open-source, self-hostable; tracing, eval, prompt management, analytics |
| **OpenTelemetry (GenAI)** | Vendor-neutral standard; emerging semantic conventions for LLM spans |
| **Phoenix (Arize)** | OSS LLM observability + eval |

Integration is usually light — a callback handler, a decorator, or an SDK wrapper:

```python
# conceptual — Langfuse-style
from langfuse.decorators import observe

@observe()
def answer(question: str) -> str:
    ctx = retrieve(question)      # auto-captured as a span
    return llm(ctx, question)     # auto-captured as a span
```

For LangChain/LangGraph apps, enabling tracing is often just setting env vars — every chain/node step then shows up as spans automatically.

---

## 5. Online evaluation — closing the loop

Observability platforms double as **online eval**:

- **Explicit feedback**: capture 👍/👎 or ratings from users, attach to traces.
- **Implicit signals**: did the user retry, rephrase, abandon, or accept?
- **Sampled LLM-judge**: run [[03 - LLM-as-a-Judge]] on a sample of production traffic for a continuous quality score.
- **Drift detection**: watch metrics over time; a quality/latency/cost drop triggers investigation.

```
prod traffic → traces + feedback → find failures → add to OFFLINE test set
                                                     ↑
                                        (the loop from note 01)
```

> [!TIP]
> **Production is your richest dataset**
> Real failures captured in traces are the best material for growing the eval set. Observability + evaluation form one continuous loop, not two separate activities.

---

## 6. Monitoring & alerting

Beyond per-request debugging, aggregate metrics power dashboards/alerts:

- **Latency** (p50/p95/p99) — is the app getting slower?
- **Cost** — daily spend, cost per user/feature (feeds §20).
- **Error rate** — failed calls, timeouts, rate-limit hits.
- **Quality** — rolling judge score / feedback ratio.
- **Volume** — requests/min, token throughput.

Alerts on these catch regressions **before** users complain in bulk.

---

## 7. Main takeaways

- **Observability** = understanding the app on **live traffic** (vs eval on a fixed set).
- The core primitive is a **trace**: a tree of **spans** with input/output/latency/tokens/cost.
- Tracing is the **debugger** for multi-step agents/RAG — it localizes failures.
- Tools: **LangSmith, Langfuse, OpenTelemetry, Phoenix**; integration is usually lightweight.
- Doubles as **online eval**: feedback, implicit signals, sampled judging, drift detection.
- **Production failures feed the offline test set** — eval + observability are one loop.
- Aggregate metrics (latency, cost, error rate, quality) drive **monitoring & alerts**.

---

## 8. Things I still want to figure out

- Cost/overhead of tracing **every** request vs sampling?
- Self-host (Langfuse) vs managed (LangSmith) trade-offs?
- How to **redact PII** from captured traces (ties to §19)?
- Best way to wire **user feedback** back into traces in a real UI?

---

## 9. Things to dig into

- **LangSmith**: https://docs.smith.langchain.com/
- **Langfuse**: https://langfuse.com/docs
- **OpenTelemetry GenAI semantic conventions**.
- Cross-links: cost (§20), reliability/monitoring (§24).

---

## 10. Section wrap-up

Section 17 establishes the **measurement layer**: *why* eval matters, *how* to score outputs (metrics, LLM-judge), how to evaluate **RAG** specifically (RAGAS), and how to observe everything in **production** (tracing). With this, every later improvement — advanced RAG, safety, cost, fine-tuning — becomes something I can **measure** rather than guess at.

---

## Related
- [[01 - Why Evaluation Matters]] — the offline counterpart; the loop closes here.
- [[04 - Evaluating RAG with RAGAS]] — eval metrics that run over traces.

## Sources
- [LangSmith docs](https://docs.smith.langchain.com/)
- [Langfuse docs](https://langfuse.com/docs)
