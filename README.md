# Full Stack AI with Python — Lecture Notes

Structured, in-depth study notes covering **building AI / LLM applications end-to-end with Python** — from how LLMs work internally, through prompt engineering, local models, agents, RAG, and on to production patterns like async workers, LangGraph workflows, checkpointing, and memory layers.

Written in Obsidian Markdown — they shine in any Obsidian vault (wiki-links + callouts) but read perfectly well on GitHub too (callouts use GitHub's native alert syntax).

> **105 notes across 16 sections** — the full course. Each note is a detailed, self-contained write-up with diagrams, comparison tables, pseudocode, gotchas, and follow-up questions.

## 📚 Sections

| # | Section | Notes | What it covers |
|---|---|:---:|---|
| 1 | [Core Foundations of Generative AI](<./Section 1: Core Foundations of Generative AI>) | 9 | What an LLM is, tokens, embeddings, the Transformer, attention, positional encoding |
| 2 | [API Setup & Integration](<./Section 2: API Setup & Integration>) | 4 | OpenAI + Gemini API setup, calling models from Python, the OpenAI-compatible SDK |
| 3 | [Advanced Prompt Engineering Techniques](<./Section 3: Advanced Prompt Engineering Techniques>) | 8 | System prompts, zero/few-shot, structured output, chain-of-thought, personas |
| 4 | [Prompt Serialization & Instruction Formats](<./Section 4: Prompt Serialization & Instruction Formats>) | 4 | Prompt styles — Alpaca, ChatML, INST |
| 5 | [Local LLM Deployment & API Integration](<./Section 5: Local LLM Deployment & API Integration>) | 6 | Running LLMs locally with Docker, Ollama, Open WebUI; serving via FastAPI |
| 6 | [Running LLMs via Hugging Face Hub](<./Section 6: Running LLMs via Hugging Face Hub>) | 5 | Hugging Face account, gated models, CLI login, the `transformers` package |
| 7 | [Building AI Agents and Agentic Workflows](<./Section 7: Building AI Agents and Agentic Workflows>) | 5 | What agents are, tool calling, Pydantic structured outputs, a CLI coding assistant |
| 8 | [Building Chat with PDF using RAG](<./Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)>) | 11 | Full RAG pipeline — indexing, retrieval, Qdrant, LangChain, PDF loading, chunking |
| 9 | [Scalable RAG with Async Queues & Distributed Workers](<./Section 9: Scalable RAG with Async Queues & Distributed Workers>) | 9 | Queues, Valkey/Redis, RQ workers, FastAPI job submit/poll, parallel processing |
| 10 | [Multi-Modal Agents](<./Section 10: Multi Modal Agents>) | 2 | Multi-modal AI, sending images to vision models |
| 11 | [Building Agentic Workflows with LangGraph](<./Section 11: Building Agentic Workflows with LangGraph>) | 9 | Nodes, edges, state, the graph builder, LLM nodes, conditional edges |
| 12 | [Checkpointing Workflows in LangGraph with MongoDB](<./Section 12: Checkpointing Workflows in LangGraph with MongoDB>) | 3 | State persistence, MongoDB checkpointer, per-thread/user scoping |
| 13 | [The Memory Layer](<./Section 13: The Memory Layer - Building Short, Long, and Semantic Memory in AI Agents>) | 10 | Memory types (STM/LTM, factual/episodic/semantic) + a Mem0 + Qdrant build |
| 14 | [Graph Memory and Knowledge Graphs in AI Agents](<./Section 14: Graph Memory and Knowledge Graphs In AI Agents>) | 8 | Why relationships need graphs, Neo4j + Cypher, wiring a knowledge graph into Mem0 |
| 15 | [Conversational Agentic AI with Voice Agents & Chained Patterns](<./Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns>) | 9 | Voice agents — S2S vs chained, STT → LLM → TTS, voice-enabling a tool-calling agent |
| 16 | [Model Context Protocol (MCP)](<./Section 16: Model Context Protocol - MCP>) | 3 | MCP as "USB-C for AI" — standardized tool/data connection; Host/Client/Server |

## 🧠 Spotlight — The Memory Layer (Section 13)

The memory series maps out how memory works in LLM-based agents:

```
                        LLM Memory
                            |
            ┌───────────────┴───────────────┐
            |                               |
     Short-Term Memory               Long-Term Memory
          (STM)                            (LTM)
                                            |
                            ┌───────────────┼───────────────┐
                            |               |               |
                       Factual         Episodic         Semantic
                        Memory          Memory           Memory
                       (always)      (on demand)      (on demand)
```

| Memory | About | Lifespan | Storage | When loaded |
|---|---|---|---|---|
| **Short-Term** | Current conversation | Session only | Context window | Active session |
| **Factual** | The user | Forever | KV / Document DB | Every session |
| **Episodic** | Past interactions | Forever | Vector DB | When triggered |
| **Semantic** | The world | Forever | Vector DB / RAG | When topic comes up |

## 🛠️ Tools & Tech Referenced

- **Models / APIs** — OpenAI, Google Gemini, Hugging Face `transformers`
- **Local LLMs** — Docker, Ollama, Open WebUI
- **Serving** — FastAPI, uvicorn
- **Agents / Orchestration** — LangChain, LangGraph, Pydantic
- **RAG & Memory** — [Qdrant](https://qdrant.tech), [Mem0](https://mem0.ai), embeddings
- **Async / Infra** — RQ (Redis Queue), Valkey/Redis, MongoDB
- *Alternatives mentioned* — Pinecone, Weaviate, Chroma, pgvector, Neo4j, Postgres

## 📖 How to Use These Notes

- **In Obsidian** — clone this repo as a folder inside your vault. Wiki-links (`[[01 - Short-Term Memory in LLMs]]`) resolve by filename, and callouts render with styling.
- **On GitHub** — notes render as Markdown. Callouts use GitHub's native alert syntax (`> [!NOTE]`, `> [!TIP]`, `> [!WARNING]`, `> [!IMPORTANT]`), so they show as proper colored boxes. Wiki-links aren't clickable here, but structure, tables, diagrams, and code blocks all work.

## 📝 Note Format

Each note follows a consistent structure:
- **YAML frontmatter** — title, date, section, tags, related links
- **TL;DR** callout — one-paragraph summary
- **Numbered sections** — core ideas, definitions, examples
- **Comparison tables, ASCII diagrams, and pseudocode**
- **Common gotchas / best practices**
- **Main takeaways** and **open questions** for further exploration

## License

Notes are shared for educational use. Feel free to adapt them for your own learning.
