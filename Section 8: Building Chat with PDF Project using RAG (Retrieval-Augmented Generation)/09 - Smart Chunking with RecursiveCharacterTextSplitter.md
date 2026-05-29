---
title: Smart Chunking with RecursiveCharacterTextSplitter
date: 2026-05-28
source: "Section 8 / Lecture 9"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - langchain
  - chunking
  - text-splitter
  - recursive-character-splitter
  - chunk-overlap
  - rag
  - indexing
  - hands-on
related:
  - "[[08 - Loading PDFs with PyPDFLoader]]"
  - "[[04 - The Indexing Phase]]"
  - "[[10 - Creating Vector Embeddings and Storing in Qdrant]]"
---

# Smart Chunking with RecursiveCharacterTextSplitter

> [!NOTE]
> **TL;DR**
> Take the page-by-page `Document`s from [[08 - Loading PDFs with PyPDFLoader]] and split them into smaller, embeddable chunks. Use **`RecursiveCharacterTextSplitter`** from `langchain_text_splitters` — `splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=400); chunks = splitter.split_documents(docs)`. The "**recursive**" part: tries splitting on natural boundaries first (`\n\n`, then `\n`, then `. `, then ` `), only falling back to mid-word splits if necessary. **`chunk_overlap`** is the key parameter — including ~20-40% of the previous chunk's tail at the start of each chunk preserves context across boundaries. Without overlap, a sentence split exactly at a chunk boundary loses its meaning. Defaults used here: chunk_size=1000, chunk_overlap=400. After this note, the corpus is ready for embedding.

> [!NOTE]
> **Where this fits**
> Ninth lecture of **Section 8: Building Chat with PDF Project using RAG**. Second step of the indexing pipeline. The next note ([[10 - Creating Vector Embeddings and Storing in Qdrant]]) converts these chunks to vectors and stores them in Qdrant.

---

## 1. The goal

Take 104 `Document` objects (one per page) and produce ~200-300 smaller chunks suitable for embedding.

```
104 pages × ~800 chars per page = ~83k characters
         │
         ▼
Split with chunk_size=1000, chunk_overlap=400
         │
         ▼
~150-250 chunks of ~1000 chars each, each containing the tail of the previous chunk
```

---

## 2. Why chunking is needed

Two reasons rehashed from [[04 - The Indexing Phase]]:

| Reason | Detail |
|---|---|
| **Embedding model limits** | Most embedding models have 8k-token input caps. Whole pages may fit, but books don't. |
| **Retrieval precision** | Smaller chunks = more targeted retrieval. A whole page returned may contain only one relevant sentence; a smaller chunk is mostly relevant. |

The trade-off: smaller = more precise but loses surrounding context; larger = more context but less precise.

---

## 3. The "recursive" insight

A naive splitter ("every 1000 characters") often cuts **mid-sentence**:

```
"The quick brown fox jumps over the lazy"   ← chunk 1 ends mid-sentence
"dog. The next paragraph begins here..."    ← chunk 2 starts mid-sentence
```

Bad for embeddings — half-sentences encode poorly.

**`RecursiveCharacterTextSplitter`** tries splitting on **natural boundaries first**, falling back only when necessary:

| Priority | Separator | Where it splits |
|---|---|---|
| 1 | `\n\n` | Paragraph boundaries |
| 2 | `\n` | Line boundaries |
| 3 | `. ` | Sentence boundaries |
| 4 | ` ` | Word boundaries |
| 5 | `""` (empty) | Character-level (last resort) |

The algorithm:
1. Try splitting on the first separator (`\n\n`).
2. If chunks are still bigger than `chunk_size`, split each on the next separator (`\n`).
3. Continue recursively until all chunks fit.

Result: chunks usually end at **clean paragraph or sentence boundaries**, with only edge cases falling back to mid-word splits.

The intuition for overlap: if you read paragraph 1, then paragraph 2, then paragraph 3 in isolation, you lose context at every seam. With overlap, each chunk starts with a tail of the previous chunk — a little extra background that keeps the seam meaningful.

---

## 4. Install

```bash
pip install langchain-text-splitters
pip freeze > requirements.txt
```

A separate package from `langchain-community` — text splitters live in their own module.

---

## 5. The minimal code

Continuing `index.py` from the previous note:

```python
from pathlib import Path
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter

# Load
pdf_path = Path(__file__).parent / "nodejs.pdf"
loader = PyPDFLoader(file_path=pdf_path)
docs = loader.load()

# Split into chunks
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=400,
)
chunks = text_splitter.split_documents(docs)

print(f"Loaded {len(docs)} pages")
print(f"Split into {len(chunks)} chunks")
```

Run:

```bash
python index.py
```

Output:
```
Loaded 104 pages
Split into 192 chunks
```

The 104 pages became ~192 chunks. Each chunk:
- ~1000 characters.
- Contains the previous chunk's last 400 characters as overlap.
- Preserves page-level metadata.

---

## 6. The two parameters

### `chunk_size`
Maximum characters per chunk.

| chunk_size | Effect |
|---|---|
| 200-500 | Very precise retrieval; lots of chunks |
| 500-1000 | Balanced (common) |
| 1000-2000 | More context per chunk (my choice here) |
| 2000-5000 | Risk of crowding multiple topics into one chunk |
| 5000+ | Approaching embedding model limits |

> [!TIP]
> Start with `chunk_size=1000`. Adjust based on:
> - If retrieval **misses things**: try smaller chunks for finer granularity.
> - If retrieval is **too narrow** (loses context): try larger chunks.

### `chunk_overlap`
Characters shared between adjacent chunks.

| chunk_overlap | Effect |
|---|---|
| 0 | No overlap — risk of cut-off context |
| 20-50 | Minimal continuity |
| 100-200 | Moderate continuity |
| 200-400 | Strong continuity (my choice here) |
| 400+ | Lots of duplication; storage bloat |

> [!TIP]
> **Rule of thumb**
> Overlap should be **20-40% of chunk_size**. Using 400 / 1000 = 40% — on the higher end, which is fine for prose-heavy text where context matters more.

---

## 7. Visualizing chunks + overlap

For text `"AAAA BBBB CCCC DDDD EEEE FFFF GGGG HHHH"` with `chunk_size=12` and `chunk_overlap=4`:

```
Chunk 1: "AAAA BBBB"      [chars 0-9]
Chunk 2:        "BBBB CCCC"      [chars 5-14]   ← overlaps with chunk 1
Chunk 3:               "CCCC DDDD"      [chars 10-19]   ← overlaps with chunk 2
Chunk 4:                      "DDDD EEEE"      [chars 15-24]
...
```

Every chunk except the first starts with the **tail of the previous chunk**. A sentence that lives near a boundary appears (in whole or in part) in two chunks — retrieval finds it either way.

---

## 8. The output — chunks are still `Document` objects

`split_documents()` returns `list[Document]` — same shape as the loader's output:

```python
print(chunks[0])

# Document(
#     page_content="### Introduction ###\nNode.js is a JavaScript runtime...",
#     metadata={'source': '/path/to/nodejs.pdf', 'page': 0}
# )
```

The metadata is **inherited from the source page**. So even after chunking, every chunk knows which page it came from — crucial for citations later.

> [!NOTE]
> **When one page splits into multiple chunks**
> All resulting chunks share `metadata['page'] = N`. So if the LLM cites "page 5", that's traceable to the original page 5 of the PDF — regardless of how the chunking happened.

---

## 9. Other splitter options

LangChain has multiple text splitters for different use cases:

| Splitter | Best for |
|---|---|
| `RecursiveCharacterTextSplitter` | **Default** — works for any text |
| `CharacterTextSplitter` | Simpler; splits on one separator only |
| `TokenTextSplitter` | Splits by tokens (e.g., for tiktoken) |
| `MarkdownHeaderTextSplitter` | Markdown — respects `#`/`##` headers |
| `HTMLHeaderTextSplitter` | HTML — respects `<h1>`/`<h2>` |
| `Language`-specific splitters | Code — Python, JavaScript, etc. |
| `SemanticChunker` | Cuts at semantic-shift boundaries (advanced) |

For unstructured PDFs: `RecursiveCharacterTextSplitter` is the right pick. For Markdown wikis: the Markdown splitter. For code: the Language one.

---

## 10. Token-based vs character-based chunking

Two ways to define chunk size:

| Mode | What `chunk_size=1000` means |
|---|---|
| **Character-based** (default) | 1000 characters |
| **Token-based** | 1000 tokens (~750 words) |

Token-based is more accurate for managing embedding model context limits. To use:

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter
import tiktoken

encoder = tiktoken.encoding_for_model("gpt-4o")

splitter = RecursiveCharacterTextSplitter.from_tiktoken_encoder(
    encoding_name="cl100k_base",
    chunk_size=500,       # now 500 *tokens*
    chunk_overlap=100,
)
```

For learning, character-based is fine. For production where embedding API costs matter, token-based gives more predictable behavior.

---

## 11. Practical decisions

Some chunking decisions to consider for a real RAG project:

| Decision | Trade-off |
|---|---|
| Include **page headers/footers** in chunks? | Noise if "Page 1, 2, 3" appears every chunk; ignore them if possible |
| Include **TOC pages**? | Usually not useful; filter them out |
| Strip **blank lines** before chunking? | Yes — saves token cost |
| Normalize **whitespace**? | Yes — reduces noise in embeddings |
| Detect and skip **boilerplate**? | Yes for legal disclaimers, footnotes |
| Preserve **structural metadata**? | Yes — chunk-from-chapter-X is useful filtering |

The defaults used here skip all these refinements. Worth iterating on for real corpora.

---

## 12. State after this note

| Component | Status |
|---|---|
| Qdrant running | ✅ |
| PDF loaded | ✅ |
| **Chunks generated** | ✅ (~192 chunks for this PDF) |
| Chunk metadata intact | ✅ |
| Embeddings | ❌ (next note) |
| Stored in Qdrant | ❌ |

Almost halfway through the indexing pipeline.

---

## 13. Common gotchas

> [!WARNING]
> **Chunking issues**

| Symptom | Cause | Fix |
|---|---|---|
| Too few chunks | `chunk_size` too big | Reduce |
| Too many chunks | `chunk_size` too small | Increase |
| Chunks cut mid-sentence | Source has no `\n\n` separators | Pre-clean text, normalize newlines |
| Retrieval misses context | `chunk_overlap` too small | Increase to ~30% of `chunk_size` |
| Embedding cost spikes | `chunk_overlap` too big → lots of duplication | Reduce overlap |
| One chunk dominates results | Chunks have wildly different sizes | Investigate min/max chunk size |
| Import error | Wrong package | `pip install langchain-text-splitters` |

---

## 14. Main takeaways

- **`RecursiveCharacterTextSplitter`** is the default text splitter.
- Install: `pip install langchain-text-splitters`.
- API: `splitter.split_documents(docs) -> list[Document]`.
- Two key knobs: **`chunk_size`** (max chars per chunk) and **`chunk_overlap`** (shared chars between adjacent chunks).
- **Recursive**: tries `\n\n` → `\n` → `. ` → ` ` → character splits.
- **Overlap** preserves context across chunk boundaries. ~20-40% of chunk_size.
- Defaults used here: `chunk_size=1000, chunk_overlap=400`.
- Output chunks **inherit metadata** (source, page number) from source documents.
- Many splitter variants for different content types (markdown, HTML, code).
- Token-based splitting more accurate for embedding cost control.

---

## 15. Things I still want to figure out

- What's the **right chunk size** for code documents specifically?
- How does **semantic chunking** (cutting at meaning boundaries) compare to character/recursive?
- For **multi-language** corpora, do I need different splitters?
- For PDFs with **mixed prose + tables + code**, how to chunk?
- What's the **measured impact** on retrieval accuracy of varying chunk_size?
- Is there a way to **automatically tune** chunk_size for a given corpus?

---

## 16. Things to dig into

- **LangChain splitter docs**: https://python.langchain.com/docs/concepts/text_splitters/
- **Semantic chunking**: https://python.langchain.com/docs/how_to/semantic-chunker/
- **Chunking visualizer**: https://chunkviz.up.railway.app — see how splitters chunk specific text.
- **Hands-on**: chunk the same PDF with three different `chunk_size`/`chunk_overlap` combos. Compare retrieval quality on the same query.

---

## 17. Next up in this section

Convert each chunk into a vector and store it in Qdrant:

- [ ] [[10 - Creating Vector Embeddings and Storing in Qdrant]] — the embedding + storage step.

---

## Related
- [[08 - Loading PDFs with PyPDFLoader]] — provides the input.
- [[04 - The Indexing Phase]] — where chunking sits.
- [[04 - What is a Token]] — relevant for token-based chunking.

## Sources
- LangChain splitter docs — https://python.langchain.com/docs/concepts/text_splitters/
- Semantic chunker docs — https://python.langchain.com/docs/how_to/semantic-chunker/
- Chunking visualizer — https://chunkviz.up.railway.app
