---
title: Few-Shot Prompting
date: 2026-05-28
source: "Section 3 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 3: Advanced Prompt Engineering Techniques"
tags:
  - prompts
  - few-shot
  - prompt-engineering
  - examples
  - system-prompt
  - foundations
  - hands-on
related:
  - "[[02 - What is Prompting]]"
  - "[[03 - Zero-Shot Prompting]]"
---

# Few-Shot Prompting

> [!abstract] TL;DR
> **Few-shot prompting** = zero-shot instructions **plus a handful of concrete input/output examples** embedded in the prompt. The model learns the task pattern from the examples and applies it to new inputs. Dramatically improves accuracy over zero-shot for specialized, format-sensitive, or nuanced tasks. Real-world few-shot prompts often use **50–60 examples** for production accuracy. Cost: more tokens per call. Benefit: ~5–50× accuracy improvement on the right kinds of tasks. Upgrading the coding-only Alexa assistant with examples makes the model refuse non-coding questions much more reliably.

> [!info] Where this fits
> Fourth note of **Section 3: Advanced Prompt Engineering Techniques**. Direct evolution of [[03 - Zero-Shot Prompting]]: same skeleton, plus examples baked into the system prompt. The next note ([[05 - Structured Output with Few-Shot Prompting]]) shows how the examples can also lock down the **output format**, not just behavior.

---

## 1. The definition

> **Few-shot prompting:** the model is provided with a few examples (Q/A pairs) before being asked to generate a response for a new input.

So:
- **Zero-shot** = "do X."
- **Few-shot** = "do X. Here are 5 examples of doing X correctly. Now do it for this new input."

The examples are commonly called **shots** — hence "few-shot" (a few examples) vs. "zero-shot" (none) vs. "one-shot" (exactly one).

---

## 2. Why examples help

Three reasons:

1. **Pattern recognition** — the model is a pattern-matcher at heart. Show it the pattern, and it imitates.
2. **Disambiguation** — natural-language instructions are often ambiguous; examples nail down what they actually mean.
3. **Format conditioning** — if every example outputs JSON in a specific shape, the new output usually conforms too.

In the zero-shot version of Alexa, asking *"explain (A + B) whole square"* sometimes still got an answer. With an example that explicitly marks that question as non-coding and shows the refusal, the model now refuses correctly. Examples raise the accuracy of the whole prompt.

---

## 3. The pattern

```python
system_prompt = """
<<< instructions (same as zero-shot) >>>

Examples:

Question: <<< example input 1 >>>
Answer: <<< example output 1 >>>

Question: <<< example input 2 >>>
Answer: <<< example output 2 >>>

...
"""
```

The examples can be:
- **Inside the system prompt** (most common, simplest).
- **As alternating user/assistant messages** (more aligned with how the model "sees" turns — sometimes more effective).

The first approach is what's used below.

---

## 4. Worked example — coding-only assistant with examples

Upgrading the Alexa assistant from [[03 - Zero-Shot Prompting]]:

`prompts/01_few_shot.py`:

```python
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
client = OpenAI()

system_prompt = """
You should only and only answer coding related questions.
Do not answer anything else.
Your name is Alexa.
If user asks something other than coding, just say sorry.

Examples:

Question: Can you explain (A + B) whole square?
Answer: Sorry, I can only help with coding-related questions.

Question: Hey, write a code in Python for adding two numbers.
Answer:
def add(a, b):
    return a + b
"""

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": "Can you explain (A + B) whole square?"},
    ],
)

print(response.choices[0].message.content)
```

### Result
```
Sorry, I can only help with coding-related questions.
```

Compared to plain zero-shot (where the same model sometimes still answered the math question), the example made the refusal pattern **explicit** and the model followed it reliably.

> [!tip] Why this works
> The math question matches the first example almost exactly. The model sees the pattern "math question → polite refusal" and copies it.

---

## 5. The two ways to embed examples

### Style A — examples inside the system prompt

```python
messages = [
    {"role": "system", "content": """
        You are a coding assistant. Answer only code questions.

        Examples:
        Q: What's the capital of France?
        A: Sorry, I only answer coding questions.

        Q: Write a Python function to add two numbers.
        A: def add(a, b): return a + b
    """},
    {"role": "user", "content": "How do I reverse a list in Python?"},
]
```

Pros:
- Simple — one system prompt does everything.
- Easy to version-control as a single string.

Cons:
- Examples don't perfectly mirror real `role`-tagged messages.
- Some models follow turn structure more strictly than instructions.

### Style B — examples as user/assistant turns

```python
messages = [
    {"role": "system", "content": "You are a coding assistant. Answer only code questions."},

    # Example 1 — as a real turn
    {"role": "user",      "content": "What's the capital of France?"},
    {"role": "assistant", "content": "Sorry, I only answer coding questions."},

    # Example 2
    {"role": "user",      "content": "Write a Python function to add two numbers."},
    {"role": "assistant", "content": "def add(a, b): return a + b"},

    # The actual question
    {"role": "user", "content": "How do I reverse a list in Python?"},
]
```

Pros:
- Mirrors how the model "sees" turns during training (instruction-tuned models often respond better).
- Cleaner separation of instructions vs. demonstrations.

Cons:
- More verbose code.
- Harder to manage as one bag of state.

> [!tip] Practical recommendation
> For prototyping: **Style A** (everything in the system prompt). For production: try both — sometimes Style B gives noticeably better adherence.

---

## 6. The 50-60 examples rule of thumb

In real-world usage, few-shot prompts often carry **50 to 60 examples** — sometimes more. A bare prompt isn't enough; examples grow with the task over time, and that can lift accuracy by roughly 50× on the right kinds of problems.

In practice, the right number depends on:

| Factor | Push for more examples | Push for fewer examples |
|---|---|---|
| Task specificity | High — push for more | Generic — fewer fine |
| Output format strictness | Strict JSON, etc. | Free-form text |
| Model size | Smaller models need more | Bigger models need fewer |
| Token budget | Long context = more room | Tight context = trim |
| Cost per call | High cost = use fewer | Cheap = use more |
| Example diversity | High = need more to cover space | Low = fewer suffice |

A reasonable progression:
- Start: **3–5 examples**.
- Iterate: add examples for **failure modes** observed in testing.
- Production: typically **10–60 examples**, sometimes more.

> [!warning] Diminishing returns
> Going from 0 → 5 examples is often a huge accuracy jump. From 5 → 20 is smaller. From 20 → 50 smaller still. Past ~50, gains usually flatten — and may even reverse if examples become noisy or contradict each other.

---

## 7. What makes a good example

| Quality | Why it matters |
|---|---|
| **Realistic input** | Matches what real users will type. |
| **Correct output** | Wrong outputs in examples will poison the model's behavior. |
| **Cover edge cases** | Refusals, errors, ambiguous inputs all need representation. |
| **Diverse** | Don't show 10 variations of the same case — cover the space. |
| **Consistent format** | If outputs vary in format across examples, the model gets confused. |
| **Concise** | Each example costs tokens; trim filler. |

> [!tip] Source of examples
> The best examples often come from **actual usage**:
> - Past user conversations.
> - Past support tickets.
> - Hand-curated "ideal answers" from domain experts.
>
> Synthetic / made-up examples work but tend to be less robust than examples drawn from real distribution.

---

## 8. When few-shot shines

Tasks where few-shot beats zero-shot dramatically:

| Task | Why few-shot helps |
|---|---|
| **Classification** | Labels become unambiguous from examples. |
| **Extraction** | "Extract dates" — examples define what counts. |
| **Structured output** | Examples lock down JSON shape (see [[05 - Structured Output with Few-Shot Prompting]]). |
| **Tone matching** | Hard to describe a tone — easier to demonstrate it. |
| **Domain-specific replies** | Legal, medical, code-review — examples teach the conventions. |
| **Refusal patterns** | "When to say no" is much clearer from examples (the Alexa case above). |

For very simple tasks (translation, summarization), few-shot often **doesn't help** much — zero-shot is fine. Don't pay the token cost for nothing.

---

## 9. The trade-off — tokens vs. accuracy

| Approach | Tokens used | Accuracy | Cost per call |
|---|---|---|---|
| Zero-shot | 50–500 | Baseline | $ |
| Few-shot (5 examples) | 500–2000 | Often +10–30% | $$ |
| Few-shot (20 examples) | 2k–8k | Often +20–50% | $$$ |
| Few-shot (50+ examples) | 8k–30k | Diminishing returns | $$$$ |

> [!note] Prompt caching reduces this cost
> OpenAI now supports **prompt caching** — repeated system prompts (including long few-shot examples) are processed once and cached. Subsequent calls only pay full price for the new user message. This makes long few-shot prompts much more cost-effective in production.

---

## 10. Anti-patterns

> [!warning] Common mistakes

| Mistake | Fix |
|---|---|
| Examples contradict the instructions | Audit examples carefully; they win over instructions in the model's mind. |
| All examples are the same kind of input | Diversify — cover refusal, success, edge cases. |
| Examples have inconsistent output format | Pick one format and apply it across all examples. |
| Examples are too long / verbose | Trim — every token costs. |
| Real user input is very different from examples | Update examples from real traffic. |
| No examples of "refuse / error / unsure" cases | Add them — otherwise the model assumes every input has a clean answer. |

---

## 11. Main takeaways

- **Few-shot prompting** = zero-shot + a handful of input/output examples.
- Examples teach the model the **task pattern**, **format**, and **edge-case behavior**.
- Aim for **50–60 examples** for real production accuracy.
- Two embedding styles: **inside the system prompt** (simple) or **as user/assistant turns** (sometimes better).
- Few-shot shines for classification, extraction, structured output, tone matching, domain replies, refusal patterns.
- Diminishing returns past ~50 examples; don't over-engineer.
- **Examples > instructions** — they often win when in conflict.
- Use **real data** for examples when possible.
- **Prompt caching** mitigates the token cost of long few-shot prompts.

---

## 12. Things I still want to figure out

- For Style A vs. Style B, are there published benchmarks showing which is better per model?
- How does **example ordering** matter? (Some research says recency bias matters.)
- What's the right number of examples per task type — any rules of thumb beyond "iterate"?
- How does few-shot interact with **chain-of-thought** (coming in [[06 - Chain of Thought Prompting]])?
- For very large context windows (1M+ tokens), is there a point where adding more examples actually hurts?
- How to **automate** generating new examples from production traffic?
- What about **negative examples** — examples of what NOT to do? Useful or confusing?

---

## 13. Things to dig into

- **Paper**: Brown et al., *Language Models are Few-Shot Learners* (2020) — the foundational paper.
- **Article**: Anthropic's *"Multishot Prompting"* guide — practical advice.
- **OpenAI prompt examples**: https://platform.openai.com/docs/examples — many are few-shot in nature.
- **Hands-on experiment**: take a task that fails in zero-shot. Add 5 examples → measure improvement. Add 20 → measure again. Find the knee in the curve for that task.

---

## 14. Next up in this section

A nice trick: few-shot examples can also **lock down the output format**, not just the behavior:

- [ ] [[05 - Structured Output with Few-Shot Prompting]] — getting consistent JSON out using examples.

---

## Related
- [[03 - Zero-Shot Prompting]] — what this note extends.
- [[02 - What is Prompting]] — system prompt foundation.
- [[02 - Using OpenAI API in Python]] — the API client.

## Sources
- Section 3, Lecture 4 — *"Few-Shot Prompting"*.
