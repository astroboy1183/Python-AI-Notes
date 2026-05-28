---
title: Building a Weather Agent
date: 2026-05-28
source: "Section 7 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 7: Building AI Agents and Agentic Workflows"
tags:
  - agents
  - weather-agent
  - tool-calling
  - python
  - openai
  - chain-of-thought
  - dispatcher-loop
  - wttr-api
  - hands-on
related:
  - "[[02 - What are AI Agents]]"
  - "[[07 - Automating Chain of Thought]]"
  - "[[05 - Structured Output with Few-Shot Prompting]]"
---

# Building a Weather Agent

> [!abstract] TL;DR
> First real agent: ask the LLM about the weather in any city, and it actually fetches the real-time answer instead of vague pre-training knowledge. Build the pieces from scratch — no LangChain, no high-level agent framework, just the [[07 - Automating Chain of Thought|CoT loop]] from Section 3 plus a new step type called `"tool"`. Add a `get_weather(city)` Python function backed by **wttr.in** (free public weather API). Extend the system prompt with a tools section + a tool example. Add a `"tool"` case to the dispatcher: when the LLM emits `{"step": "tool", "tool": "get_weather", "input": "Delhi"}`, the runner **executes the named function** and appends an `"observe"` message with the result. The LLM then continues until it emits `"output"`. Demo: *"What's the weather in Delhi, Bangalore, and Patiala?"* → agent autonomously calls `get_weather` three times → produces a unified reply.

> [!info] Where this fits
> Third note of **Section 7: Building AI Agents and Agentic Workflows**. The first **build** in the section. Takes everything from prior sections and produces a working agent. The next note ([[04 - Structured Outputs with Pydantic]]) hardens this with Pydantic. The one after ([[05 - Building a CLI Coding Assistant]]) replaces the weather tool with a `run_command` tool that vibe-codes apps.

---

## 1. The intuition / goal

User types:
```
What's the weather in Goa?
```

Want the agent to:
1. Parse the intent — *"user wants weather, city = Goa"*.
2. Call a real weather API.
3. Return the actual current weather, not a vague pre-2024 answer.

Why this matters: it makes the **knowledge-cutoff problem disappear** for one domain (weather). Same pattern extends to any external information.

---

## 2. Step 0 — Show what fails without tools

Start by demonstrating that a plain LLM **can't** do this.

```python
# weather_agent/main.py
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
client = OpenAI()

def main():
    user_query = input("> ")

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "user", "content": user_query},
        ],
    )

    print(f"🤖 {response.choices[0].message.content}")

if __name__ == "__main__":
    main()
```

Run + ask: *"What is the current temperature in Goa right now?"*

Reply:
> *"I'm sorry but I can't provide real-time data or current weather conditions. To find the current temperature of Goa, I recommend checking a weather website or app."*

That's the gap. The LLM **knows it doesn't know**, which is honest, but useless for the user.

The LLM can't resolve this query — which makes sense. LLMs work off pre-training data, and pre-training data can never contain the current weather of Goa.

---

## 3. Step 1 — Build the tool (`get_weather`)

The plan: hit **`wttr.in`** — a free, no-auth public weather API.

Quick test in browser:
```
https://wttr.in/Goa?format=%C+%t
```

Returns something like:
```
Partly cloudy +28°C
```

Wrap as a Python function:

```python
import requests

def get_weather(city: str) -> str:
    """Return current weather for the given city."""
    url = f"https://wttr.in/{city.lower()}?format=%C+%t"
    response = requests.get(url)
    if response.status_code == 200:
        return f"The weather in {city} is {response.text}"
    return "Something went wrong"
```

Test it standalone (no LLM yet):

```python
print(get_weather("Goa"))      # "The weather in Goa is Partly cloudy +28°C"
print(get_weather("Delhi"))    # "The weather in Delhi is Mist +27°C"
```

Calling `get_weather("Goa")` returns the current Goa weather; `get_weather("Delhi")` returns Delhi's. Function works. Now wire it into the agent.

---

## 4. Step 2 — Reuse the CoT loop from [[07 - Automating Chain of Thought]]

Recap: that loop had three step types (`start` / `plan` / `output`). The system prompt taught the LLM to emit one JSON step per response; the runner dispatched on `step`.

The agent extends this with a fourth step type: **`tool`**.

Sequence becomes:

```
start  →  plan (one or more) →  tool  →  observe  →  plan (one or more)  →  ... →  output
                                  ▲         │
                                  └─ LLM    └─ Runner adds this after executing the tool
```

- `tool` step = the LLM is asking the runner to **execute** a function.
- `observe` step = the runner **reports back** the tool's output (as a system message the LLM reads on its next turn).

---

## 5. Step 3 — The updated system prompt

```python
system_prompt = """
You are an expert AI assistant in resolving user queries using chain of thought.

You work on these steps: start, plan, tool, observe, and output.
You can call a tool if required from the list of available tools.
Only run one step at a time.

For every tool call, wait for the observe step (which is the output from the called tool).

The sequence of steps is:
  start → plan (one or more) → tool → observe → plan → output

Output JSON format:
{
  "step": "start" | "plan" | "tool" | "output",
  "content": "<string>",
  "tool": "<tool name>",          // only when step == "tool"
  "input": "<tool input>"          // only when step == "tool"
}

Available tools:
- get_weather(city: str) → str
  Takes a city name as input and returns the weather information about the city.

Example 1 (math):

Q: Can you solve 2 + 3 * 5 / 10?
A: {"step": "start", "content": "Can you solve 2 + 3 * 5 / 10?"}
A: {"step": "plan", "content": "User wants a math problem solved using BODMAS."}
A: {"step": "plan", "content": "First multiply: 3 * 5 = 15. New expression: 2 + 15 / 10."}
A: {"step": "plan", "content": "Now divide: 15 / 10 = 1.5. New expression: 2 + 1.5."}
A: {"step": "plan", "content": "Finally add: 2 + 1.5 = 3.5."}
A: {"step": "output", "content": "3.5"}

Example 2 (weather — with tool):

Q: What is the weather of Delhi?
A: {"step": "start",  "content": "What is the weather of Delhi?"}
A: {"step": "plan",   "content": "Seems like user is interested in getting the weather of Delhi, India."}
A: {"step": "plan",   "content": "From the available tools, get_weather can resolve this query."}
A: {"step": "plan",   "content": "I need to call get_weather with 'Delhi' as the city input."}
A: {"step": "tool",   "tool": "get_weather", "input": "Delhi"}
A: {"step": "observe", "tool": "get_weather", "input": "Delhi", "output": "The weather in Delhi is Cloudy +20C"}
A: {"step": "plan",   "content": "Great, got the weather info for Delhi."}
A: {"step": "output", "content": "The current weather in Delhi is cloudy with 20°C."}
"""
```

Key teaching moves embedded in the prompt:
- **List of available tools** with signature and description.
- **JSON schema** with conditional fields (`tool` and `input` only present for tool steps).
- **An end-to-end example** showing exactly how a tool call should look + how the observe step follows.
- **Explicit rule**: "wait for the observe step after every tool call."

---

## 6. Step 4 — The agent loop (with tool dispatch)

```python
import json
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
client = OpenAI()

# Map of tool name → Python function
available_tools = {
    "get_weather": get_weather,
}

system_prompt = """..."""    # (from previous section)

def main():
    user_query = input("🙋 > ")

    message_history = [
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": user_query},
    ]

    while True:
        response = client.chat.completions.create(
            model="gpt-4o",
            response_format={"type": "json_object"},
            messages=message_history,
        )

        raw_result = response.choices[0].message.content
        parsed = json.loads(raw_result)

        # Always append the LLM's message to history
        message_history.append({"role": "assistant", "content": raw_result})

        step = parsed.get("step")
        content = parsed.get("content")

        if step == "start":
            print(f"🔥 {content}")
            continue

        elif step == "plan":
            print(f"🧠 {content}")
            continue

        elif step == "tool":
            tool_name = parsed.get("tool")
            tool_input = parsed.get("input")
            print(f"🔧 Calling {tool_name}({tool_input!r})")

            # Execute the tool
            tool_response = available_tools[tool_name](tool_input)
            print(f"🔍 Tool result: {tool_response}")

            # Inject the observe step into history
            observe_message = {
                "step": "observe",
                "tool": tool_name,
                "input": tool_input,
                "output": tool_response,
            }
            message_history.append({
                "role": "developer",                       # or "user", depending on provider
                "content": json.dumps(observe_message),
            })
            continue

        elif step == "output":
            print(f"🤖 {content}")
            break

        else:
            print(f"⚠️ Unknown step: {step}")
            break

if __name__ == "__main__":
    main()
```

That's the whole agent — about 50 lines including the system prompt.

---

## 7. Trace — what one run looks like

Asking: *"What's the weather in Delhi and Bangalore?"*

```
🙋 > What's the weather in Delhi and Bangalore?

🔥 What's the weather in Delhi and Bangalore?
🧠 The user is asking for current weather in two cities.
🧠 The get_weather tool can resolve weather queries.
🧠 I'll need to call get_weather twice — once for each city.
🧠 Starting with Delhi.
🔧 Calling get_weather('Delhi')
🔍 Tool result: The weather in Delhi is Mist +27°C
🧠 Got Delhi's weather. Now calling for Bangalore.
🔧 Calling get_weather('Bangalore')
🔍 Tool result: The weather in Bangalore is Partly cloudy +23°C
🧠 Got both. Time to summarize for the user.
🤖 Current weather:
   - Delhi: Mist, 27°C.
   - Bangalore: Partly cloudy, 23°C.
```

The LLM autonomously:
- Recognized two cities in the query.
- Issued two tool calls.
- Processed both observations.
- Produced a unified reply.

Keep asking questions — the agent has access to real-time information. This is the first real agent: one tool given, and it's working great.

---

## 8. The key innovations vs. plain CoT

Compared to [[07 - Automating Chain of Thought]]:

| Aspect | Plain CoT | Agent |
|---|---|---|
| Step types | `start`, `plan`, `output` | + `tool`, `observe` |
| External I/O | None | Tool calls do real work |
| LLM autonomy | Thinks step-by-step | + Decides which tools to call |
| Side effects | None | Tool calls can have them (HTTP requests, file writes) |
| Loop termination | `output` step | Same |
| Application code role | Print steps | + Execute tool calls |

The leap from CoT to agent is **one extra step type** in the JSON schema. That's it. Everything else is the same pattern.

---

## 9. Handling multi-tool calls

Asking for *Delhi + Bangalore + Patiala* in one go — the agent issues `get_weather` three times. This works naturally because:

- The LLM **knows** (from training) how to plan multi-step tasks.
- The system prompt **allows** multiple tool calls between `start` and `output`.
- The loop **doesn't break** until it sees `output`.

Result:
```
🔧 Calling get_weather('Delhi')
🔍 Tool result: Mist +27°C
🔧 Calling get_weather('Bangalore')
🔍 Tool result: Partly cloudy +23°C
🔧 Calling get_weather('Patiala')
🔍 Tool result: Unknown location
🤖 Delhi: 27°C, Bangalore: 23°C, Patiala: I couldn't retrieve.
```

Even with the partial failure (Patiala unknown), the agent **handles it gracefully** because the observation told it so.

---

## 10. Wrapping in a continuous-conversation loop

Make the agent reusable — instead of exiting after one `output`, prompt for the next user query:

```python
def main():
    message_history = [
        {"role": "system", "content": system_prompt},
    ]

    while True:                                            # outer loop: keep chatting
        user_query = input("\n🙋 > ")
        if not user_query.strip():
            break

        message_history.append({"role": "user", "content": user_query})

        while True:                                        # inner loop: agent loop
            # ... same as before ...
            if step == "output":
                break

if __name__ == "__main__":
    main()
```

Now it's a real chat agent — keeps memory of past turns, can answer follow-up questions like *"and what about Mumbai?"* using context.

---

## 11. The "LLM with tools = agent" formula

The weather agent now has one hand — making an API call to the weather API. LLM with tools = agent. This is how to build your own agents.

The mental model crystallizes:

| Want more capability | Add another tool |
|---|---|
| Web search | `search(query)` |
| Send email | `send_email(to, subject, body)` |
| Run code | `run_python(code)` |
| Query database | `query_sql(sql)` |
| Modify file | `write_file(path, content)` |

Each tool extends the agent's "body." [[05 - Building a CLI Coding Assistant]] demonstrates this with a `run_command` tool that effectively gives the agent **infinite capability** via the shell.

---

## 12. The brittleness — preview of [[04 - Structured Outputs with Pydantic]]

This implementation has one big flaw.

```python
parsed = json.loads(raw_result)
```

This trusts the LLM to emit **valid JSON every time**. In practice:
- Sometimes the LLM emits *"Sure, here's the result: {...}"* — `json.loads` chokes.
- Sometimes fields are missing — `parsed.get("step")` returns `None` and the dispatcher silently fails.
- No way to **validate** the schema.

The next note ([[04 - Structured Outputs with Pydantic]]) replaces all of this with `client.beta.chat.completions.parse(...)` + a Pydantic model → type-safe, validated outputs.

---

## 13. Main takeaways

- **Weather agent** = LLM + `get_weather` tool + dispatcher loop.
- New step types added: **`tool`** (LLM asks runner to call function) and **`observe`** (runner reports result back).
- System prompt teaches the schema and shows an example tool-using trace.
- `available_tools` dict maps **tool name string → Python function**.
- The agent autonomously **chains multiple tool calls** when needed.
- Handles **partial failures** gracefully (one tool errors, others succeed).
- Wrap in outer `while True` for **continuous conversation**.
- This is the **canonical agent pattern** — every production agent does this in some form.
- Reliability issue: relies on `json.loads` of free-form output → fix with Pydantic next.

---

## 14. Things I still want to figure out

- What's the **right schema** for an `observe` message — what role should it use (`developer`, `user`, `tool`)?
- How to handle **tool errors** that aren't returned strings but exceptions?
- What's the **max-iterations** cap? This version doesn't add one.
- For tools with **multiple arguments**, what's the JSON shape (nested object vs flat string)?
- How does this compare to OpenAI's **native function-calling API** (with `tools=[...]` param)?
- For **complex multi-tool** workflows, when does this DIY approach break down vs frameworks like LangGraph?
- How do I **log** every step for debugging in production?

---

## 15. Things to dig into

- **OpenAI function calling**: https://platform.openai.com/docs/guides/function-calling — the "native" version of what's built here by hand.
- **wttr.in** docs: https://wttr.in — the public weather API used here.
- **ReAct pattern**: Yao et al., 2022 — foundational paper that defined the `Thought → Action → Observation → ...` loop.
- **Hands-on**: add a second tool (e.g., `get_time(city)` via `worldtimeapi.org`) and see the LLM use both for "what time and weather is it in Tokyo?"

---

## 16. Next up in this section

The agent works but is fragile. Time to fix the JSON-parsing brittleness:

- [ ] [[04 - Structured Outputs with Pydantic]] — replace `json.loads` with type-safe parsing.

---

## Related
- [[02 - What are AI Agents]] — the conceptual setup.
- [[07 - Automating Chain of Thought]] — the loop pattern this extends.
- [[05 - Structured Output with Few-Shot Prompting]] — the JSON foundation.
- [[06 - Chain of Thought Prompting]] — the underlying prompting pattern.

## Sources
- Section 7, Lecture 3 — *"Building a Weather Agent"*.
- wttr.in — https://wttr.in
- OpenAI function calling docs — https://platform.openai.com/docs/guides/function-calling
