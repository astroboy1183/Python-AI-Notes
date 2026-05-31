---
title: Latency and Streaming
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 20: Cost, Caching & Latency Optimization"
tags:
  - latency
  - streaming
  - performance
  - ttft
  - optimization
related:
  - "[[03 - Semantic Caching]]"
  - "[[05 - Model Routing and Optimization Strategies]]"
---

# Latency and Streaming

> [!NOTE]
> **TL;DR**
> LLM latency has two parts: **time-to-first-token (TTFT)** — how long until output *starts* — and **inter-token latency** — how fast tokens then stream. Total time ≈ TTFT + (output_tokens × time_per_token), so **longer outputs are slower** (and costlier, §1). The single biggest UX lever is **streaming**: send tokens to the user as they're generated so they see a response *immediately* instead of staring at a spinner for the whole generation — same total time, vastly better perceived speed. Real latency reductions come from: **smaller/faster models**, **shorter outputs** (`max_tokens`, concise prompts), **less input** (reranking/§18, prompt caching/§2), **parallelizing** independent calls, and **caching** (§3). For agents, latency compounds across steps — minimize the number of sequential LLM calls.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 20**. Cost (notes 1–3) and latency share many levers; this note focuses on time. It connects to streaming TTS (§15) and serving (§24).

---

## 1. Two latency metrics

```
request ──[ TTFT ]──► first token ──[ token, token, token... ]──► done
          (prefill +                  (decode: inter-token latency
           queue + network)            × number of output tokens)
```

| Metric | What it is | Driven by |
|---|---|---|
| **TTFT** (time-to-first-token) | Delay before output starts | Prompt length (prefill), queueing, network |
| **Inter-token latency** | Time between streamed tokens | Model size/speed, load |
| **Total latency** | TTFT + decode of all output tokens | Both + **output length** |

> [!IMPORTANT]
> **Output length dominates total latency**
> Generation is sequential — each token waits for the previous. So total time scales with the **number of output tokens**. A concise answer is both **cheaper** (§1) and **faster**. Capping `max_tokens` and prompting for brevity is a two-for-one win.

---

## 2. Streaming — the perception win

Normally the API returns the full completion at once → the user waits for the entire generation. **Streaming** emits tokens as they're produced:

```
no streaming:  [········ 4s wait ········] "Here is your full answer."
streaming:     "Here" "is" "your" ...        ← user reads as it appears (feels instant)
```

> [!TIP]
> **Streaming doesn't reduce total time — it reduces *perceived* time**
> The generation takes just as long, but the user sees progress immediately (after TTFT, not after the whole completion). For chat UIs this is the difference between "fast" and "frozen." It's the same idea behind streaming TTS in the voice agent (§15) — start delivering before the whole result is ready.

```python
stream = client.chat.completions.create(model=..., messages=..., stream=True)
for chunk in stream:
    token = chunk.choices[0].delta.content or ""
    print(token, end="", flush=True)   # render as it arrives
```

---

## 3. Real latency reductions

| Lever | Effect |
|---|---|
| **Smaller/faster model** | Lower inter-token latency + TTFT (also cheaper, §5) |
| **Shorter output** (`max_tokens`, "be concise") | Fewer tokens to generate → less total time |
| **Less input** (rerank §18, fewer/cleaner chunks) | Faster prefill → lower TTFT |
| **Prompt caching** (§2) | Cached prefix isn't recomputed → lower TTFT |
| **Semantic cache hit** (§3) | ~0 latency (skip the call) |
| **Parallelize** independent calls | Wall-clock = slowest, not sum |
| **Faster serving** (vLLM, batching, §24) | Higher throughput, lower queueing |

---

## 4. Parallelize independent work

If steps don't depend on each other, run them concurrently instead of sequentially:

```
sequential:  call A (2s) → call B (2s) → call C (2s) = 6s
parallel:    [A, B, C] all at once               = ~2s
```

Use `asyncio.gather` / concurrent requests for independent retrievals, multi-query (§18), or fan-out subtasks. Only sequential dependencies must wait.

---

## 5. Agent latency compounds

> [!WARNING]
> **Every agent step adds a full round-trip**
> An agent loop (§7) that takes 5 LLM calls to finish has ~5× the latency of a single call. Latency is often the hidden tax of agentic designs. Mitigations: minimize loop steps, use a fast model for routing/intermediate steps and a strong one only where needed (§5), parallelize independent tool calls, and stream the final answer. For multi-step workflows, show **intermediate progress** so the wait feels productive.

---

## 6. The latency/cost/quality triangle

```
        quality
         /   \
   (big model, more steps, more context)
       /         \
   cost ───────── latency
   (all three pull against each other)
```

Most optimizations trade along this triangle: a smaller model cuts cost *and* latency but may cost quality; more context/steps raise quality but cost both. **Eval (§17)** is what lets you move on this triangle deliberately instead of blindly.

---

## 7. Main takeaways

- Latency = **TTFT** + (**output tokens** × inter-token time); **output length dominates**.
- **Streaming** improves *perceived* speed massively (same total time) — essential for chat UIs.
- Real reductions: **smaller model, shorter output, less input, caching, parallelize**.
- **Cap `max_tokens`** + prompt for brevity → faster *and* cheaper.
- **Parallelize independent** calls (`asyncio.gather`); only sequential deps wait.
- **Agent loops compound latency** — minimize steps, use fast models for intermediate ones, stream the end.
- Cost, latency, quality form a **triangle** — eval lets you trade deliberately.

---

## 8. Things I still want to figure out

- Typical **TTFT** differences between model tiers?
- How much does **prompt caching** actually cut TTFT for long prompts?
- Best pattern to **stream** through a multi-step agent (partial updates)?

---

## 9. Things to dig into

- Provider **streaming** APIs (SSE) and async clients.
- **vLLM** / continuous batching for serving (§24).
- Measuring TTFT / p95 latency in observability (§17).
- Next: [[05 - Model Routing and Optimization Strategies]].

---

## 10. Next up in this section

- [ ] [[05 - Model Routing and Optimization Strategies]] — send each request to the cheapest model that's good enough.

---

## Related
- [[03 - Semantic Caching]] — a cache hit is ~0 latency.
- [[08 - TTS and the Conversational Loop]] — streaming applied to voice.

## Sources
- [OpenAI streaming](https://platform.openai.com/docs/api-reference/streaming)
- [vLLM](https://docs.vllm.ai/)
