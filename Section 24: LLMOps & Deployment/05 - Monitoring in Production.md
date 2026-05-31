---
title: Monitoring in Production
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 24: LLMOps & Deployment"
tags:
  - llmops
  - monitoring
  - observability
  - drift
  - alerting
related:
  - "[[05 - Tracing and Observability]]"
  - "[[04 - Versioning and CI-CD for LLM Apps]]"
---

# Monitoring in Production

> [!NOTE]
> **TL;DR**
> Monitoring is the "is it healthy *right now*?" layer, built on the tracing from §17. Four metric families to watch: **operational** (latency p50/p95/p99, error rate, throughput, uptime), **cost** (spend per day/user/feature, token usage — §20), **quality** (sampled LLM-judge scores, user feedback 👍/👎, fallback/refusal rates — §17), and **drift** (are inputs or outputs changing over time?). Set **alerts** on thresholds (latency spike, error surge, cost blowout, quality drop) so you catch problems **before** users flood support. Crucially, monitoring **closes the loop**: production failures captured in traces become new **eval cases** (§17) and the input to the next change (§04). The difference from classic app monitoring is the **quality** dimension — an LLM app can be "up" (200 OK, fast, cheap) yet producing **garbage**, which only quality monitoring catches.

> [!NOTE]
> **Where this fits**
> Fifth note of **Section 24**, the production-watch layer. It operationalizes the observability from [[05 - Tracing and Observability]] (§17) and feeds rollback decisions from [[04 - Versioning and CI-CD for LLM Apps]].

---

## 1. Monitoring vs observability

- **Observability** (§17): the *capability* to inspect what happened (traces, spans).
- **Monitoring**: the *ongoing practice* of watching aggregate metrics + alerting on problems.

Monitoring sits **on top of** tracing — it aggregates the per-request traces into dashboards and alerts.

---

## 2. The four metric families

### a) Operational
Standard service health:
```
latency (p50 / p95 / p99) · error rate · throughput (req/s) · uptime · timeout rate · retry/fallback rate
```
p95/p99 matter more than averages — a few very slow requests ruin UX.

### b) Cost (§20)
```
spend per day · cost per request / user / feature · token usage (in/out) · cache hit rate · rate-limit headroom
```
LLM cost can spike suddenly (a loop, a verbose prompt, abuse) — watch it closely.

### c) Quality (the LLM-specific one)
```
sampled LLM-judge score (§17) · user feedback (👍/👎) · thumbs-down rate ·
refusal rate · fallback rate · "I don't know" rate · guardrail-block rate (§19)
```

> [!IMPORTANT]
> **"Up" is not "good" — monitor quality, not just health**
> A classic app is healthy if it returns 200s quickly. An LLM app can return fast, cheap 200s that are **wrong, off-topic, or hallucinated**. Operational metrics won't catch that — only **quality** monitoring (sampled judging + user feedback) will. This is the dimension traditional monitoring lacks, and it's where LLM apps silently fail.

### d) Drift
Are things changing over time?
```
input drift:  users asking new kinds of questions (topics shift)
output drift: answers getting longer / different / lower quality
```
Drift can degrade a previously-good app without any code change (new user behavior, provider model updates). Detect it by tracking input/output distributions and quality trends.

---

## 3. Alerting

Turn metrics into action — alert on threshold breaches:

| Alert | Trigger |
|---|---|
| Latency | p95 > target |
| Errors | error/timeout rate spike |
| Cost | daily spend or per-user cost over budget |
| Quality | thumbs-down / refusal / judge-score drop |
| Rate limits | TPM/RPM headroom low |
| Drift | input/output distribution shift |

> [!TIP]
> **Alert on what users feel, before users complain**
> The goal of alerting is to find out from a **dashboard**, not from a flood of support tickets. Prioritize alerts on **quality drops** and **latency/error spikes** — the things users actually experience. Avoid alert fatigue: alert on meaningful thresholds, not every blip.

---

## 4. Closing the loop

> [!IMPORTANT]
> **Monitoring feeds eval and the next change**
> This is the recurring theme: production traces surface failures → those failures become **new eval cases (§17)** → which gate the **next prompt/model change (§04)** → deployed via canary while monitoring watches. Monitoring isn't a dead-end dashboard; it's the **source of truth** for what to fix and the **safety net** during rollouts.

```
monitor → spot failure/drift → add to eval set (§17) → fix + eval-gate (§04) → canary + monitor → ...
```

It's also the **rollback trigger**: a canary that degrades quality/latency/cost (§04) is caught here.

---

## 5. Per-segment monitoring

Aggregate metrics hide problems. Slice by:
- **User / tenant** (one customer hitting errors?)
- **Feature / endpoint** (which use case is degrading?)
- **Model / prompt version** (did v2 regress vs v1? — §04 A/B)
- **Input type** (a topic the app handles badly?)

The metadata captured in traces (§17) is what makes slicing possible — another reason to capture it.

---

## 6. Tooling

- **LLM observability** (§17): LangSmith, Langfuse, Phoenix — traces → dashboards + quality/online-eval.
- **General APM/metrics**: Prometheus + Grafana, Datadog — operational + cost metrics, alerting.
- **OpenTelemetry**: vendor-neutral instrumentation feeding either.

Often a combo: an LLM-observability tool for quality/traces + standard APM for ops/alerting.

---

## 7. Main takeaways

- **Monitoring** = ongoing watching + alerting, built on **tracing (§17)**.
- Four metric families: **operational** (latency p95/p99, errors, throughput), **cost** (§20), **quality** (judge/feedback), **drift**.
- **"Up" ≠ "good"** — only **quality monitoring** catches fast, cheap, *wrong* answers.
- **Alert** on user-felt issues (quality drops, latency/error/cost spikes) — find out before users do.
- **Closes the loop**: failures → eval cases (§17) → gate next change (§04); also the **rollback trigger**.
- **Slice by user/feature/version/input** (using trace metadata) — aggregates hide problems.
- Tools: LLM-observability (LangSmith/Langfuse) + APM (Prometheus/Grafana/Datadog).

---

## 8. Things I still want to figure out

- Right **sampling rate** for LLM-judge quality monitoring vs cost?
- Practical **drift detection** for free-text inputs/outputs?
- Alert thresholds that catch real issues without fatigue?

---

## 9. Things to dig into

- **Langfuse / LangSmith** dashboards + online eval (§17).
- **Prometheus + Grafana** for ops/cost metrics + alerting.
- Drift-detection approaches for text.
- Next: [[06 - Deployment Patterns]].

---

## 10. Next up in this section

- [ ] [[06 - Deployment Patterns]] — where and how the app actually runs.

---

## Related
- [[05 - Tracing and Observability]] — the capture layer monitoring aggregates.
- [[04 - Versioning and CI-CD for LLM Apps]] — monitoring triggers rollback.

## Sources
- [Langfuse monitoring/metrics](https://langfuse.com/docs)
- [Prometheus](https://prometheus.io/) + [Grafana](https://grafana.com/)
