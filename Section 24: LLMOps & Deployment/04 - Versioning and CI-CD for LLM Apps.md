---
title: Versioning and CI-CD for LLM Apps
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 24: LLMOps & Deployment"
tags:
  - llmops
  - versioning
  - ci-cd
  - prompts
  - deployment
related:
  - "[[01 - LLMOps Overview]]"
  - "[[01 - Why Evaluation Matters]]"
---

# Versioning and CI-CD for LLM Apps

> [!NOTE]
> **TL;DR**
> In LLM apps, behavior is driven by **prompts and model choices**, not just code — so those must be **versioned and tested** like code. **Version everything that affects output**: prompt templates, model name + parameters (temperature, etc.), the RAG config, and few-shot examples. Treat **prompts as code** (in git, reviewed, with a changelog) or use a **prompt registry** (LangSmith/Langfuse/PromptLayer) for non-engineers to edit safely. The CI/CD twist: the test gate isn't pass/fail asserts, it's the **eval suite (§17)** — a prompt/model change runs against the eval set, and ships only if the score holds. Deploy with **canary/A-B/gradual rollout** and keep **rollback** trivial (revert the prompt/model version). The whole point: make changing a prompt as safe and reversible as changing code.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 24**, operationalizing the "prompts are deployable artifacts" idea from [[01 - LLMOps Overview]]. The CI gate is the eval suite from §17.

---

## 1. What needs versioning

Anything that changes the model's output is part of the "artifact":

```
output = f( prompt template, model + params, RAG config, few-shot examples, tools )
```

| Versioned thing | Why |
|---|---|
| **Prompt templates** | The main behavior driver — small wording changes shift output |
| **Model + parameters** | `gpt-4.1-mini` vs `gpt-4.1`, temperature, max_tokens — all change behavior |
| **RAG config** | chunking, top-k, reranker (§18) affect answers |
| **Few-shot examples** | Part of the prompt; changes shift behavior |
| **Tool definitions** | Agent capabilities (§7) |

> [!IMPORTANT]
> **A prompt change *is* a deployment**
> Editing a system prompt can change behavior as much as a code change — and can regress silently. So prompts need the discipline of code: **track versions, review changes, test before shipping, and be able to roll back.** "I just tweaked the prompt in prod" is the LLM equivalent of pushing untested code straight to main.

---

## 2. Two ways to manage prompts

| Approach | How | Best for |
|---|---|---|
| **Prompts as code** | Prompt templates live in the repo (git): reviewed in PRs, versioned, changelogged | Engineering-owned prompts |
| **Prompt registry** | A managed store (LangSmith/Langfuse/PromptLayer) with versions, edits, rollbacks via UI | Non-engineers iterating; decoupling prompt edits from deploys |

```
prompts-as-code:  git history = prompt history; deploy = release
registry:         edit prompt in UI → versioned → app fetches the pinned version
```

A **registry** lets product/ops edit prompts without a code deploy — but **pin versions** so a registry edit can't change prod unexpectedly (and so it's reviewable/rollback-able).

---

## 3. The CI/CD pipeline — eval is the gate

Normal CI runs unit tests. LLM CI runs the **eval suite (§17)**:

```
change a prompt / model / RAG config
        ▼
CI: run EVAL SUITE on the fixed test set (§17)
        ▼
score ≥ baseline?  ── no → block the merge (regression!)
        │ yes
        ▼
deploy (canary / gradual rollout, below)
```

> [!IMPORTANT]
> **The test gate is non-deterministic — use eval, not asserts**
> You can't `assert output == expected` on open-ended LLM output (§17). The CI gate is the **eval score** (functional checks + judges + task metrics) vs a **baseline**. A change ships only if it **doesn't regress** the suite. This is the concrete payoff of building eval in §17 — it becomes your merge gate. (Set a threshold; account for eval noise by averaging / requiring a margin.)

---

## 4. Safe rollout strategies

Even after eval passes, derisk the production rollout:

| Strategy | How |
|---|---|
| **Canary** | Route a small % of traffic to the new version; watch metrics (§05) before full rollout |
| **A/B test** | Run old vs new on live traffic; compare quality/cost/latency + user feedback (§17 online eval) |
| **Gradual rollout** | Ramp 1% → 10% → 100% as metrics stay healthy |
| **Shadow** | Run the new version alongside (not serving users), compare outputs offline |

```
new prompt v2: eval passes → canary 5% → metrics OK → ramp to 100% (or rollback)
```

---

## 5. Rollback — make it trivial

> [!TIP]
> **Versioning's real payoff is instant rollback**
> When a new prompt/model misbehaves in production (despite eval — real traffic surprises you), you must revert **fast**. With versioned prompts/models, rollback = "pin the previous version" — seconds, not a redeploy scramble. Always know the last-good version and have a one-step path back to it. This is why pinning (not "latest") matters.

Pin model versions too: "latest" can silently change under you when a provider updates a model — pin a specific version and upgrade deliberately (re-run eval first).

---

## 6. The full change workflow

```
1. edit prompt/model/RAG config (in git or registry, versioned)
2. open PR / change → CI runs EVAL suite (§17) vs baseline
3. eval holds? → merge; eval regresses? → block + fix
4. deploy via canary / gradual rollout
5. monitor metrics + feedback (§05/§17)
6. healthy? → full rollout.  problem? → ROLLBACK to last-good version
7. production failures → add to eval set → next change
```

This is the LLMOps lifecycle (§24.01) made concrete for shipping changes.

---

## 7. Main takeaways

- Behavior comes from **prompts + model choice**, so **version everything**: prompts, model+params, RAG config, few-shot, tools.
- **A prompt change is a deployment** — review, test, and roll it back like code.
- Manage prompts **as code (git)** or via a **registry** (LangSmith/Langfuse/PromptLayer) — but **pin versions**.
- CI gate = the **eval suite (§17)** vs a baseline, not exact-match asserts; **block regressions**.
- Roll out safely with **canary / A-B / gradual / shadow**.
- Make **rollback trivial** (pin previous version) — versioning's real payoff.
- **Pin model versions** ("latest" drifts); upgrade deliberately after re-eval.

---

## 8. Things I still want to figure out

- How to handle **eval noise** in a pass/fail CI gate (margins, repeats)?
- Prompts-as-code vs registry for a small team — which friction is worse?
- A/B testing infra for LLM outputs (assignment + metric collection)?

---

## 9. Things to dig into

- **LangSmith / Langfuse / PromptLayer** prompt versioning.
- Eval-in-CI patterns (run §17 suite on PRs).
- Canary/feature-flag tooling for gradual rollout.
- Next: [[05 - Monitoring in Production]].

---

## 10. Next up in this section

- [ ] [[05 - Monitoring in Production]] — watching health, quality, cost, and drift live.

---

## Related
- [[01 - LLMOps Overview]] — "prompts are deployable artifacts."
- [[01 - Why Evaluation Matters]] — the eval suite that gates CI.

## Sources
- [Langfuse prompt management](https://langfuse.com/docs/prompts/get-started)
- [LangSmith prompt versioning](https://docs.smith.langchain.com/)
