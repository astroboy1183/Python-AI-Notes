---
title: What are AI Agents
date: 2026-05-28
source: "Section 7 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 7: Building AI Agents and Agentic Workflows"
tags:
  - agentic-ai
  - agents
  - llm-tools
  - tool-calling
  - microservices
  - brain-body-analogy
  - foundations
related:
  - "[[01 - Section Intro - Welcome to Agentic AI]]"
  - "[[01 - What is an LLM]]"
  - "[[03 - The Transformer - Predicting the Next Token]]"
---

# What are AI Agents

> [!NOTE]
> **TL;DR**
> An **AI agent** = an LLM **plus the ability to take actions** through tools. Conceptual setup: traditional software has microservices (auth, orders, payments, shipping) accessed by humans — and **human customer-support agents** sit between users and those services to take actions on the user's behalf (cancel orders, check shipping, etc.). The question agentic AI asks: *can an LLM replace those human support agents?* Default answer is no — an LLM by itself is "a dumb piece of code that takes text in and gives text out," with no access to anything. The fix: give the LLM **tools** (API access, DB access, function-call ability) so it can do the same actions as the human agent. **The brain analogy**: an LLM is a brain in a box — fully capable of thinking but can't *do* anything. Give it arms, legs, and senses (tools) → it becomes an agent.

> [!NOTE]
> **Where this fits**
> Second lecture of **Section 7: Building AI Agents and Agentic Workflows**. Pure conceptual setup. The next lecture ([[03 - Building a Weather Agent]]) builds the first real agent. This note's analogies are the mental model for everything that follows.

---

## 1. The traditional setup — humans use software directly

```
                   ┌────────────────────────────────────────┐
                   │              Users                      │
                   └───────────────┬────────────────────────┘
                                   │
                                   ▼
                   ┌────────────────────────────────────────┐
                   │          Reverse Proxy / Gateway        │
                   └───────────────┬────────────────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        ▼            ▼             ▼            ▼             ▼
   ┌──────────┐  ┌────────┐  ┌────────┐  ┌────────────┐  ┌──────────┐
   │ Payment  │  │  Auth  │  │ Orders │  │  Shipping  │  │    ...   │
   │  Service │  │ Service│  │Service │  │   Service  │  │          │
   └─────┬────┘  └────┬───┘  └────┬───┘  └─────┬──────┘  └─────┬────┘
         │            │           │            │                │
         ▼            ▼           ▼            ▼                ▼
   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
   │ MongoDB  │  │ Postgres │  │ MongoDB  │  │ Postgres │  │   ...    │
   └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘
```

A typical microservice architecture. Users hit a gateway → routed to services → services talk to databases. None of this involves AI yet.

---

## 2. The human-support-agent layer

Then a business need emerges: customer support. Imagine Amazon — when an order arrives broken, the user calls a support agent.

```
   ┌──────────────────────────────────────────────────────┐
   │                     Users                             │
   └────────────────────────┬─────────────────────────────┘
                            │  "where is my order?"
                            ▼
   ┌──────────────────────────────────────────────────────┐
   │             Human Support Agents                      │
   │              1   2   3   4   5   ...                  │
   └────────────────────────┬─────────────────────────────┘
                            │  uses internal tools to:
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   Orders Service      Payments Service    Shipping Service
```

What the human support agent does:
- Listens to the user's natural-language query.
- **Interprets intent** ("they want to cancel this order").
- Looks up information across services.
- Sometimes **takes actions** (refund, cancel, escalate).
- Communicates back in natural language.

These human support agents have access to the system — orders, profile, shipping info, payments. They sit idle until a query comes in ("hey, I just placed an order and it hasn't arrived yet — what's the status?"), then use the internal services to pull up the user's private information and respond.

That's a real, working **agent pattern** — except powered by a human. The question agentic AI asks: *can an LLM do this?*

---

## 3. The naive attempt — drop in an LLM

```
                  ┌────────────────┐
                  │      User      │
                  └────────┬───────┘
                           │
                           ▼
                  ┌────────────────┐
                  │  GPT-4o / Gemini│
                  │  (LLM API)      │
                  └────────────────┘
                           │
                           ▼
                  Text reply only.
                  No service access.
                  No actions taken.
                  Just chats.
```

This doesn't work because the LLM is, by default, isolated:
- Can't call APIs.
- Can't query databases.
- Can't take actions in the world.
- Can only produce text.

An LLM by itself is a dumb piece of code sitting on a server — text in, text out. Nothing else.

So a plain LLM **can't replace a human support agent** any more than a brain in a jar can take phone calls.

---

## 4. The brain-and-body analogy

The central metaphor:

```
    Just an LLM            =    Just a brain
    (no tools)                  (no body)
    
            
    ┌─────────────┐
    │   Brain     │   →  Can think, predict, reason
    │  (in a box) │
    └─────────────┘
    
            +
    
    ┌─────────────┐
    │             │
    │   Arms 🦾   │   →  Can manipulate objects
    │   Legs 🦵   │   →  Can move
    │   Eyes 👁  │   →  Can perceive
    │   Voice 📢  │   →  Can communicate
    └─────────────┘
    
            =
    
    ┌─────────────┐
    │   AGENT     │   →  A full person
    └─────────────┘
```

Picture a fully functional brain kept in a box. Can it do anything? Can it teach? Can it code? No — because while the brain can process inputs and produce signals as output, it needs a body to actually act on the world. That's exactly what an LLM is: a brain without a body. The job as a developer is to take this brain and give it one.

| Real world | LLM world |
|---|---|
| Brain | LLM |
| Eyes / ears | Input channels (text, image, audio) |
| Mouth | Text output |
| Arms / hands | **Tools** — functions the LLM can call |
| Legs | **Tools** — functions the LLM can call |
| Memory | Conversation history, [[00 - Types of Memory in LLMs]] |

**Agent = LLM + body (tools).** That single equation is what this section turns into code.

---

## 5. What is a "tool", concretely

A tool is **a Python function** the LLM is allowed to invoke. Examples:

```python
def get_weather(city: str) -> str:
    """Return current weather for the given city."""
    response = requests.get(f"https://wttr.in/{city}?format=3")
    return response.text

def send_email(to: str, subject: str, body: str) -> None:
    """Send an email."""
    ...

def query_database(sql: str) -> list[dict]:
    """Run a SQL query and return results."""
    ...

def run_command(cmd: str) -> str:
    """Run a Linux command and return its stdout."""
    return os.popen(cmd).read()
```

Each function:
- Takes structured inputs (`str`, `int`, JSON).
- Performs some action (HTTP request, DB query, file write).
- Returns a result the LLM can read.

The agent's job: **decide which tool to call, with what arguments, and what to do with the result.**

---

## 6. The augmented architecture

With tools, the picture becomes:

```
                  ┌────────────────┐
                  │      User      │
                  └────────┬───────┘
                           │ natural language
                           ▼
                  ┌────────────────┐
                  │   LLM (brain)  │
                  └────────┬───────┘
                           │ tool calls
       ┌───────────────────┼───────────────────┐
       ▼                   ▼                   ▼
   Auth Service       Orders Service     Shipping Service
       │                   │                   │
       ▼                   ▼                   ▼
   Auth DB             Orders DB          Shipping DB
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │ tool results
                           ▼
                  ┌────────────────┐
                  │   LLM (brain)  │
                  └────────┬───────┘
                           │ final reply (natural language)
                           ▼
                  ┌────────────────┐
                  │      User      │
                  └────────────────┘
```

The LLM is now:
- **Reading** user intent.
- **Choosing** the right tool.
- **Calling** it (just outputting structured JSON the runner executes).
- **Reading** the result.
- **Continuing** (more tools? more reasoning?) or **finishing** with a natural-language reply.

That's the agent loop. The whole rest of Section 7 is **building this picture in code**.

---

## 7. What makes an agent autonomous

The "agentic" part is **autonomy in tool selection**:

| Decision | Who makes it in an agent |
|---|---|
| Which tool to call | **The LLM** |
| What arguments to pass | **The LLM** |
| Whether to call another tool after seeing the result | **The LLM** |
| When to stop and reply | **The LLM** |

The application code just **executes** the tool calls and feeds the results back. It doesn't decide what to call. That's a key distinction from a regular API client where the developer writes the call.

> [!TIP]
> **The mindset shift**
> Writing an agent ≠ writing a workflow. A workflow is "run step 1, then step 2, then step 3." An agent is "give the LLM the tools, the goal, and the loop, and let it figure out the steps."

---

## 8. The three modes of LLM use — a spectrum

| Mode | Who controls the steps | Example |
|---|---|---|
| **Pure chat** | The user, turn by turn | ChatGPT conversation |
| **Workflow** | The developer in code | Pipeline: tokenize → call LLM → parse → save |
| **Agent** | The LLM itself | "Plan a trip to Tokyo" → LLM searches flights, hotels, restaurants → returns itinerary |

Section 7 is about the third mode.

---

## 9. Concrete preview of Section 7 builds

The next three notes make all this real:

| Build | Tools | Action taken |
|---|---|---|
| **Weather agent** ([[03 - Building a Weather Agent]]) | `get_weather(city)` | Fetch real-time weather; LLM picks the city from natural language |
| **Pydantic upgrade** ([[04 - Structured Outputs with Pydantic]]) | (same tools) | Reliability fix — typed JSON responses |
| **CLI coding assistant** ([[05 - Building a CLI Coding Assistant]]) | `run_command(cmd)` | Vibe-code a todo app — agent writes files, runs commands, debugs |

Each adds one capability. By the end: a working agent that writes code on disk.

---

## 10. The agentic pattern (formalized)

The pattern that emerges:

```
1. System prompt:
   - Describe the agent's identity and goal.
   - List available tools (name, signature, description).
   - Specify output JSON schema (steps: start / plan / tool / observe / output).

2. User message: the actual goal.

3. Loop:
   - Send all messages to LLM.
   - Parse JSON reply.
   - Dispatch on step type:
       "start"   → echo received goal.
       "plan"    → think out loud.
       "tool"    → execute the named tool; emit an "observe" message.
       "output"  → return final answer; break loop.
   - Append everything to message history.

4. Return final output to user.
```

This is exactly the call-loop-dispatch pattern from [[07 - Automating Chain of Thought]], just extended with a `tool` step.

---

## 11. Main takeaways

- **AI agent** = LLM + tools (+ a loop to dispatch them).
- Plain LLMs are "dumb pieces of code, text in → text out" — they need to be **given a body**.
- **Tools = Python functions** the LLM can invoke (weather API, file system, DB, etc.).
- The human-support-agent analogy: the LLM plays the same role the human did, with the same toolset.
- **Brain + body analogy**: brain alone can think but not act; agent = brain + body.
- The "agentic" property = the LLM **decides** which tool to call autonomously.
- The pattern is **deterministic on the application side** (call-loop-dispatch), **autonomous on the LLM side** (which step, which tool).
- This is the same pattern as [[07 - Automating Chain of Thought]] with one extra step type: `tool`.

---

## 12. Things I still want to figure out

- For complex tasks, how does the LLM "remember" which tools it has tried and failed?
- What's the **safety boundary** when an agent has destructive tools (delete files, send money)?
- How do agents handle **partial failures** (one tool errors mid-plan)?
- What's the right **timeout / max-step** cap for runaway agents?
- How does **observability** work in production agent systems (LangSmith? OpenTelemetry?)?
- What's the right way to **share tools** across multiple agents?
- For long-running agents, how is **state persisted** across crashes?

---

## 13. Things to dig into

- **Paper**: Yao et al., *ReAct: Synergizing Reasoning and Acting in Language Models* (2022) — the foundational agent paper.
- **OpenAI Function Calling** docs: https://platform.openai.com/docs/guides/function-calling
- **LangChain Agents** docs: https://python.langchain.com/docs/concepts/agents/
- **Anthropic's Tool Use** docs: https://docs.anthropic.com/claude/docs/tool-use

---

## 14. Next up in this section

Code the first real agent:

- [ ] [[03 - Building a Weather Agent]] — wire up `get_weather()` to an LLM via CoT-with-tools.

---

## Related
- [[01 - Section Intro - Welcome to Agentic AI]] — section context.
- [[07 - Automating Chain of Thought]] — the loop pattern this builds on.
- [[01 - What is an LLM]] — what's in the "brain" box.
- [[03 - The Transformer - Predicting the Next Token]] — what's happening inside the brain.

## Sources
- Section 7, Lecture 2 — *"What are AI Agents"*.
