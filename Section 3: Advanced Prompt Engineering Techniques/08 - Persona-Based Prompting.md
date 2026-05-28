---
title: Persona-Based Prompting
date: 2026-05-28
source: "Section 3 / Lecture 8"
type: lecture-notes
status: in-progress
section: "Section 3: Advanced Prompt Engineering Techniques"
tags:
  - prompts
  - persona
  - persona-prompting
  - tone-matching
  - few-shot
  - prompt-engineering
  - hands-on
  - clone
related:
  - "[[02 - What is Prompting]]"
  - "[[04 - Few-Shot Prompting]]"
---

# Persona-Based Prompting

> [!abstract] TL;DR
> **Persona-based prompting** = build a system prompt that makes the LLM **mimic a specific person**. Background facts + tone examples turn a generic assistant into a believable clone of someone — useful for AI tutors that "sound like" their teacher, personal-style chatbots, character bots in games, or AI versions of public figures. The recipe: (1) explicit biographical context about the person, (2) **lots of real-life examples** of how they actually talk — 100-150 examples from chat history, social posts, comments, etc., (3) optional rules for tone and refusal. Heavily relies on the [[04 - Few-Shot Prompting|few-shot]] pattern — examples > description for capturing a voice. With enough good examples, the LLM produces eerily on-brand replies.

> [!info] Where this fits
> Eighth and final note of **Section 3: Advanced Prompt Engineering Techniques**. Closes out the section. Combines lessons from [[02 - What is Prompting]] (system prompts), [[04 - Few-Shot Prompting]] (the 100+ examples rule), and a touch of personality engineering. After this, **Section 4** moves into **prompt serialization** (saving / loading / templating prompts).

---

## 1. The definition

> **Persona-based prompting:** crafting a system prompt that makes the LLM act as a specific person or character — adopting their tone, vocabulary, opinions, communication style, and conversational patterns.

The goal isn't "play a role" generically (e.g., "be a teacher") — it's "be **this specific person**" with measurable fidelity.

---

## 2. Real-world use cases

| Use case | Example |
|---|---|
| **AI tutor** | An AI version of your favorite teacher that responds in their voice |
| **Personal assistant for a public figure** | "Founder bot" that responds in the founder's known tone |
| **Character bots in games** | NPCs that talk in distinctive voices |
| **Chatbots for content creators** | AI version of a YouTuber that engages fans |
| **Customer support persona** | A consistent brand voice across all reps |
| **Practice tools** | Chat with an AI version of someone you actually know (a friend) for fun |
| **Historical figures** | Educational tools where you "talk to" Einstein, Lincoln, etc. |

> [!tip] The framing
> This pattern is used when the goal is to **clone someone** — make the AI talk in their specific tone, not just play a generic role.

---

## 3. The recipe

A persona prompt needs **three layers**:

### Layer 1 — biographical context
Who is this person? Set the stage:
```
You are an AI persona acting on behalf of Jayanth, a 25-year-old tech
enthusiast, currently a Principal Engineer. His main tech stack is
JavaScript and Python. He's actively learning Generative AI.
```

### Layer 2 — tone / behavior examples (the bulk of the work)
Show — don't describe — how the person talks:
```
Q: Hey, how's it going?
A: hey, what's up

Q: Can you explain promises in JS?
A: bruh, promises are just IOUs from JavaScript. they say "I'll get
   back to you with a value (or an error) later". async/await is
   syntactic sugar on top.
...
```
**Repeat for ~100-150 examples.**

### Layer 3 — rules and constraints (optional but useful)
```
Rules:
- Stay in character at all times.
- Be informal and concise — don't over-explain.
- If asked about topics outside tech, deflect with humor.
- Never break character or admit being an AI.
```

---

## 4. Worked example — code

`prompts/04_persona.py`:

```python
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
client = OpenAI()

system_prompt = """
You are an AI persona assistant named Jayanth.
You are acting on behalf of Jayanth, who is 25 years old, a tech
enthusiast, a Principal Engineer. His main tech stack is JS and Python
and he is learning GenAI these days.

Examples:

Q: Hey, what are you up to?
A: hey, what's up

Q: Can you teach me React?
A: yeah sure, react is super dope once it clicks. start with components,
   then state, then hooks. don't get lost in the redux rabbit hole on day 1.

Q: Tell me a joke.
A: why do programmers prefer dark mode? because light attracts bugs 🐛
"""

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": "Hey there"},
    ],
)

print(response.choices[0].message.content)
```

### Sample output
```
hey, what's up — how can i assist you today?
```

With just three examples it's already on tone. With 100+ examples, the fidelity becomes startling.

Three examples isn't really enough — for serious results, feed in **100 to 150 examples**. Drop in an actual chat history (with someone you talk to often) and the model will start copying the tone surprisingly well.

---

## 5. Where to get 100+ tone examples

The hard part isn't writing the prompt — it's collecting enough **authentic examples** of how the person actually talks.

Realistic sources:

| Source | What it captures |
|---|---|
| **WhatsApp / Telegram chats** | Casual, fast tone with friends |
| **LinkedIn comments** | Professional tone, networking voice |
| **Twitter / X posts** | Punchy, opinionated, public-facing |
| **YouTube comments** | Casual reactions to others' content |
| **Slack DMs (work)** | Professional internal voice |
| **Emails** | More formal correspondence |
| **Blog posts / articles** | Long-form writing voice |
| **Transcripts of talks** | Spoken-word patterns |

> [!warning] Consent matters
> Cloning **someone else's** voice without consent is ethically dicey — and possibly illegal depending on jurisdiction. Stick to:
> - Yourself.
> - Public figures with publicly-published content.
> - Friends who have explicitly consented (and aren't surprised when you show them the clone).
>
> Don't use private conversations of others without permission.

---

## 6. Anatomy of a good persona example

Each example should pack as much **voice information** as possible:

| Quality | Why it matters |
|---|---|
| **Distinctive phrasing** | "bruh", "tbh", custom slang, signature openers |
| **Sentence structure** | Short and punchy? Long and rambling? Bullet-heavy? |
| **Vocabulary level** | Casual vs technical vs jargon-heavy |
| **Use of emoji / punctuation** | Some people never use periods; some use ellipses constantly |
| **Topic-specific reactions** | How they respond when asked about tech vs personal |
| **Refusal patterns** | When and how they say "no" |
| **Humor style** | Self-deprecating? Sarcastic? Pun-y? |
| **Catchphrases** | Anything they say repeatedly |

Variety across examples is more useful than redundancy. Cover:
- Casual exchanges
- Asking for help
- Giving advice
- Disagreeing
- Joking
- Receiving compliments
- Being told they're wrong

The wider the **conversation surface**, the more robust the persona.

---

## 7. Adding personality data beyond examples

Beyond raw tone examples, useful structured data:

```text
Background:
- Born in <city>, lives in <city>.
- Education: <details>.
- Career history: <details>.
- Major projects / accomplishments.
- Strong opinions (and what they are).
- Topics they avoid.
- People they admire.
- Things they joke about often.

Preferences:
- Coffee or tea? Both? Neither?
- Morning person or night owl?
- Favorite tools / books / podcasts.

Conversational quirks:
- Often uses "bruh", "tbh", "wym".
- Replies with one-word answers when busy.
- Asks lots of follow-up questions.
- Hates being called by full name.
```

These details show up naturally in replies, making the persona feel three-dimensional rather than a flat tone copy.

---

## 8. The dispatcher pattern — multi-persona apps

For apps where one user can chat with several personas (each a clone of a friend, or a roster of characters):

```python
PERSONAS = {
    "jayanth": SYSTEM_PROMPT_JAYANTH,
    "alex":    SYSTEM_PROMPT_ALEX,
    "sam":     SYSTEM_PROMPT_SAM,
}

def chat(persona_name, user_message):
    system_prompt = PERSONAS[persona_name]
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": user_message},
        ],
    )
    return response.choices[0].message.content
```

Switching personas = switching system prompts. The rest of the pipeline doesn't care.

---

## 9. Combining with other patterns

Persona prompts compose well with everything else in this section:

| Combination | Result |
|---|---|
| Persona + JSON output | A persona that responds in structured form |
| Persona + CoT | A persona that thinks step-by-step in its own voice |
| Persona + tool use (later) | A persona-flavored agent |
| Persona + RAG (later) | A persona answering using its own knowledge base |
| Persona + memory (Section 13) | A persona that remembers you across sessions |

In practice, the most ambitious AI products (Character.AI, Replika, etc.) layer all of these together.

---

## 10. Anti-patterns

> [!warning] Persona prompt mistakes

| Mistake | Fix |
|---|---|
| Only describing the persona ("be casual, witty") without examples | Add 50+ real example exchanges. Description ≠ voice. |
| All examples are the same kind of exchange | Cover refusals, jokes, advice, disagreement, etc. |
| Persona drifts mid-conversation | Add rule: "Stay in character at all times." |
| Persona occasionally admits being an AI | Add rule: "Never break character or admit being an AI." (If product allows.) |
| Examples disagree with stated traits | Pick one; ensure examples reinforce stated personality. |
| Prompt is too short for the depth required | Real persona prompts are often **multiple pages** of context. |
| Using competitor / unauthorized voices | Stick to consent-based sources. |

---

## 11. Evaluating a persona

How to know if the persona prompt is "good"?

1. **Side-by-side test** — show a person who knows the cloned individual a real reply vs. an AI reply. Can they tell which is which?
2. **Edge cases** — ask about topics not in examples. Does the persona still feel coherent?
3. **Tone consistency** — does the persona drift over a 10-turn conversation?
4. **Refusal handling** — does the persona refuse out-of-bounds topics in character?
5. **Vocabulary check** — do signature words/phrases show up naturally?

> [!tip] The "would they say this?" test
> The cleanest gut-check: read every AI reply aloud, asking "would this person actually say this exact thing?" If the answer is consistently yes, the persona is dialed in.

---

## 12. End of Section 3

This wraps up **Section 3: Advanced Prompt Engineering Techniques**. The section covered:

| Note | Topic |
|---|---|
| 01 | Section Intro — Why Prompts Matter |
| 02 | What is Prompting (System Prompts) |
| 03 | Zero-Shot Prompting |
| 04 | Few-Shot Prompting |
| 05 | Structured Output with Few-Shot |
| 06 | Chain of Thought Prompting |
| 07 | Automating Chain of Thought |
| 08 | Persona-Based Prompting (this note) |

**What's next**: Section 4 (Prompt Serialization & Instruction Formats) handles **saving / loading / templating** prompts professionally — taking these techniques out of inline Python strings and into proper prompt management.

---

## 13. Main takeaways

- **Persona prompting** = make the LLM act as a specific person.
- Three layers: **biographical context**, **tone examples**, **rules**.
- **Examples are king** — 100-150 real examples produce eerily good fidelity.
- Best sources: WhatsApp chats, LinkedIn comments, tweets, emails, blog posts.
- Personas compose well with **CoT, structured output, RAG, memory** — the most ambitious AI products layer all of these.
- **Ethics**: only clone with consent or for public-facing public figures.
- Test by asking "would they actually say this?" repeatedly.
- Multi-persona apps just swap the system prompt; the rest stays the same.

---

## 14. Things I still want to figure out

- How does **fine-tuning** compare to persona prompting for voice mimicry?
- Best **prompt structure** for very long persona prompts — XML tags? Markdown sections? Plain text?
- How to **automate** the example-extraction process from raw chat dumps?
- What models are **best at persona fidelity** — do bigger models hold the voice better?
- How does **persona drift** behave over very long conversations?
- Can a persona be **multi-modal** (also speak in voice, generate consistent images)?
- Legal / ethical landscape — what's the line for "AI versions" of people?

---

## 15. Things to dig into

- **Character.AI's approach** — they've built the largest persona-prompt platform; their patterns are worth studying.
- **Anthropic's *Constitutional AI*** — relevant for persona-with-rules systems.
- **Fine-tuning** vs persona prompts: for very heavy production usage, fine-tuning a small model on the target voice may beat prompt-based personas.
- **Hands-on**: collect 50 personal-tone examples from own chats and write the persona prompt. Then chat with the AI clone. Notice when it feels right vs uncanny.

---

## 16. Next up

End of Section 3. Next:

- [ ] **Section 4: Prompt Serialization & Instruction Formats** — taking prompts out of inline strings into templates, files, and reusable formats.

---

## Related
- [[04 - Few-Shot Prompting]] — the foundational pattern persona relies on.
- [[02 - What is Prompting]] — system prompt fundamentals.
- [[01 - Section Intro - Why Prompts Matter]] — section overview.

## Sources
- Section 3, Lecture 8 — *"Persona-Based Prompting"*.
