# LLM Memory — Lecture Notes

A six-part series of structured lecture notes on **memory in Large Language Models** and AI agents. Originally written in Obsidian Markdown — works great with any Obsidian vault (wiki-links + callouts), but reads fine on GitHub too.

## 📚 The Series

| # | Note | Topic |
|---|---|---|
| 00 | [Types of Memory in LLMs](./00%20-%20Types%20of%20Memory%20in%20LLMs.md) | The full taxonomy — overview of STM, LTM, and the three LTM sub-types |
| 01 | [Short-Term Memory in LLMs](./01%20-%20Short-Term%20Memory%20in%20LLMs.md) | Session-scoped conversation history (the volatile one) |
| 02 | [Long-Term Memory in LLMs](./02%20-%20Long-Term%20Memory%20in%20LLMs.md) | Persistent, user-scoped, DB-backed memory |
| 03 | [Factual Memory in LLMs](./03%20-%20Factual%20Memory%20in%20LLMs.md) | LTM sub-type: stable user facts (always injected) |
| 04 | [Episodic Memory in LLMs](./04%20-%20Episodic%20Memory%20in%20LLMs.md) | LTM sub-type: past interactions (on-demand via vector search) |
| 05 | [Semantic Memory in LLMs](./05%20-%20Semantic%20Memory%20in%20LLMs.md) | LTM sub-type: general world knowledge (on-demand RAG) |

## 🧠 The Big Picture

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

## 🛠️ Tools Referenced

- [Mem0](https://mem0.ai) — Memory framework for LLM agents
- [Qdrant](https://qdrant.tech) — Open-source vector database
- Pinecone, Weaviate, Chroma, pgvector, Neo4j, MongoDB, Redis — alternative stores

## 📖 How to Use These Notes

- **In Obsidian**: clone this repo as a folder inside your vault. Wiki-links (`[[01 - Short-Term Memory in LLMs]]`) will resolve, and Obsidian callouts (`> [!tip]`) will render with styling.
- **On GitHub**: the notes render as Markdown. Wiki-links won't be clickable but the structure, tables, and code blocks all work.

## 📝 Format

Each note follows the same structure:
- **YAML frontmatter** — title, tags, parent, related links
- **TL;DR** callout — one-paragraph summary
- **Core idea, definitions, examples** — with tables, code blocks, ASCII diagrams
- **Implementation patterns + pseudocode**
- **Gotchas / best practices**
- **Open questions** for further exploration

## License

Notes are shared for educational use. Feel free to adapt for your own learning.
