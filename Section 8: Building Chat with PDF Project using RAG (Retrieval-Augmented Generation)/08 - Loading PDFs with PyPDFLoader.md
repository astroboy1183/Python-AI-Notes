---
title: Loading PDFs with PyPDFLoader
date: 2026-05-28
source: "Section 8 / Lecture 8"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - langchain
  - pypdfloader
  - pdf
  - document-loader
  - rag
  - indexing
  - pathlib
  - hands-on
related:
  - "[[07 - Introduction to LangChain]]"
  - "[[04 - The Indexing Phase]]"
  - "[[09 - Smart Chunking with RecursiveCharacterTextSplitter]]"
---

# Loading PDFs with PyPDFLoader

> [!abstract] TL;DR
> First concrete indexing step: read a PDF into Python as page-by-page `Document` objects. Use **`PyPDFLoader`** from `langchain_community.document_loaders` — `loader = PyPDFLoader(pdf_path); docs = loader.load()`. Returns a list where **each element is one page** with `page_content` (the page's text) and `metadata` (source file, page number). Resolve the PDF path safely with **`pathlib`** — `Path(__file__).parent / "nodejs.pdf"`. PDF used here: a 104-page Node.js book downloaded from the internet. After this note, the corpus is in memory as a list of 104 `Document` objects ready for chunking.

> [!info] Where this fits
> Eighth lecture of **Section 8: Building Chat with PDF Project using RAG**. First step of the indexing pipeline. The next note ([[09 - Smart Chunking with RecursiveCharacterTextSplitter]]) splits these documents into smaller chunks suitable for embedding.

---

## 1. The goal

After this note, given a PDF file on disk:

```
nodejs.pdf  (104 pages)
     │
     ▼
[Document(page=1, content="..."),
 Document(page=2, content="..."),
 ...
 Document(page=104, content="...")]
```

Each page becomes one `Document` object — text + metadata. Ready for the next step.

---

## 2. Why LangChain's loader (not raw `pypdf`)

LangChain's `PyPDFLoader` wraps the popular `pypdf` library and adds:
- **Consistent return shape** (`Document` objects with `page_content` + `metadata`).
- **Per-page split** automatically.
- **Metadata injection** (source path, page number).
- **Same API as 50+ other loaders** (Web, Word, CSV, etc.) → swap-able.

Raw `pypdf` works too, but produces strings, not structured `Document`s. The LangChain wrapper makes downstream code (chunking, embedding) uniform across loader types.

`PyPDFLoader` is a utility from the LangChain community packages — a PDF file loader, ready to use.

---

## 3. Install

If not already installed from the LangChain intro note:

```bash
pip install langchain-community pypdf
```

Two packages:
- **`langchain-community`** — has `PyPDFLoader`.
- **`pypdf`** — the underlying PDF-reading library (transitive dep, but install explicitly to be safe).

Freeze:

```bash
pip freeze > requirements.txt
```

---

## 4. The PDF

I'm using a Node.js PDF book — any public Node.js intro PDF works. Download one from the internet and save it as `nodejs.pdf` in the project folder.

```
rag/
├── docker-compose.yml
├── nodejs.pdf            ← the PDF
├── index.py              ← indexing script
└── ...
```

The PDF: 104 pages of text-heavy content. Suitable for RAG experiments.

> [!tip] PDF choice matters
> Text-heavy PDFs (books, articles) work great. PDFs that are **mostly scanned images** (some old documents) need OCR first — `PyPDFLoader` returns blank pages for them. For real production, detect and OCR image-heavy pages.

---

## 5. Path resolution with `pathlib`

A subtle but important detail: how to find the PDF on disk.

### The wrong way
```python
pdf_path = "nodejs.pdf"   # depends on where the script is invoked from
```

This breaks the moment the script runs from a different working directory.

### The right way
```python
from pathlib import Path

pdf_path = Path(__file__).parent / "nodejs.pdf"
```

Explanation:

| Piece | What it does |
|---|---|
| `__file__` | The path to the current script (e.g., `/Users/me/rag/index.py`) |
| `Path(__file__)` | Wrap as a `Path` object |
| `.parent` | The directory containing the script |
| `/ "nodejs.pdf"` | Append filename using `pathlib`'s `/` operator |

Result: always finds the PDF **in the same directory as the script**, regardless of cwd.

The idiom: import `Path` from `pathlib`, take the current file, walk up to its parent directory, and join the PDF filename onto that.

---

## 6. The minimal code

`index.py`:

```python
from pathlib import Path
from langchain_community.document_loaders import PyPDFLoader

# Resolve PDF path
pdf_path = Path(__file__).parent / "nodejs.pdf"

# Load the PDF
loader = PyPDFLoader(file_path=pdf_path)
docs = loader.load()

# Inspect
print(f"Loaded {len(docs)} pages")
print(docs[12])    # peek at page 13 (zero-indexed)
```

Run:

```bash
python index.py
```

Output (illustrative):

```
Loaded 104 pages
page_content='### Functions in JavaScript ###\n\nFunctions are first-class citizens in JavaScript. You can pass...'
metadata={'source': '/Users/me/rag/nodejs.pdf', 'page': 12}
```

Two key takeaways from the output:
- `len(docs) == 104` — one `Document` per page.
- Each `Document` has `page_content` (string) and `metadata` (dict).

`loader.load()` returns the pages — the PDF is loaded into the Python process and every page is its own `Document`, which means it can be iterated over directly.

---

## 7. The `Document` object

LangChain's universal text container:

```python
@dataclass
class Document:
    page_content: str            # the text
    metadata: dict               # arbitrary key-value metadata
```

For `PyPDFLoader`, the metadata includes:

| Key | Value |
|---|---|
| `source` | Full path to the PDF |
| `page` | Page number (zero-indexed: 0 for first page) |

Other loaders add their own metadata (e.g., `WebBaseLoader` adds `title`, `description`, `language`).

This unified format is what makes **downstream code (chunking, embedding, storing) loader-agnostic**.

---

## 8. Iterating through pages

```python
for doc in docs:
    page = doc.metadata['page']
    content_preview = doc.page_content[:100].replace('\n', ' ')
    print(f"Page {page}: {content_preview}...")
```

Useful for:
- Sanity-checking what was extracted.
- Identifying pages that came out empty (likely image-only).
- Spot-checking page numbers match the visual PDF.

---

## 9. PDF extraction quirks

PDFs are messy. A few things `PyPDFLoader` can struggle with:

| Problem | Symptom | Workaround |
|---|---|---|
| Image-only pages | Empty `page_content` | OCR with `pytesseract` |
| Two-column layouts | Text columns concatenated wrongly | Try `pdfplumber` or `pymupdf` |
| Tables | Cells flattened into a paragraph | `pdfplumber` has better table extraction |
| Mathematical notation | Symbols become weird characters | Some loaders preserve LaTeX, most don't |
| Headers / footers repeated | Page number "1", "2", "3" repeat in chunks | Post-process to strip patterns |
| Form fields | Skipped entirely | Use form-specific tools |

For a clean Node.js book PDF like the one used here, all of these are non-issues. For real-world heterogeneous PDFs, layered extraction strategies are needed.

---

## 10. Loader alternatives

LangChain has multiple PDF loaders if `PyPDFLoader` doesn't work:

| Loader | Backend | Strength |
|---|---|---|
| `PyPDFLoader` | `pypdf` | Default, fast |
| `PyMuPDFLoader` | `pymupdf` | Better for complex layouts |
| `PDFPlumberLoader` | `pdfplumber` | Best for tables |
| `UnstructuredPDFLoader` | `unstructured.io` | Most powerful, slowest |
| `MathpixPDFLoader` | Mathpix API | Best for math-heavy PDFs |
| `OnlinePDFLoader` | (any) | Loads from URL directly |

All return the same `Document[]` shape — interchangeable in downstream code.

> [!tip]
> When in doubt, **PyPDFLoader first** — it's the default for a reason. Only swap if the output looks wrong.

---

## 11. State after this note

| Component | Status |
|---|---|
| Qdrant running | ✅ (from Note 6) |
| LangChain packages | ✅ (from Note 7) |
| PDF on disk | ✅ |
| `index.py` exists | ✅ |
| PDF loaded into memory | ✅ (104 `Document` objects) |
| Chunking | ❌ (next note) |
| Embedding | ❌ |
| Storing in Qdrant | ❌ |

Loading is the easy part. Real engineering starts with chunking next.

---

## 12. Common gotchas

> [!warning] First-time issues

| Symptom | Cause | Fix |
|---|---|---|
| `FileNotFoundError` | Wrong path | Use `Path(__file__).parent / "..."` |
| `Loaded 0 pages` | PDF is encrypted | Decrypt first, or use `password=...` param |
| Garbled text in `page_content` | Font encoding issue | Try `PyMuPDFLoader` or `pdfplumber` |
| Each page is suspiciously short | Multi-column layout misread | Try `PyMuPDFLoader` |
| First few pages empty | Cover / TOC images | Normal; skip them in chunking |
| Many pages empty | Scanned PDF | Need OCR |
| `pypdf` not installed | `langchain-community` doesn't pull it | `pip install pypdf` |
| Import path errors | Old LangChain version | Update to recent `langchain-community` |

---

## 13. Main takeaways

- **`PyPDFLoader`** from `langchain_community.document_loaders` is the standard PDF loader.
- Install: `pip install langchain-community pypdf`.
- Usage: `loader = PyPDFLoader(path); docs = loader.load()`.
- Returns a **list of `Document` objects**, one per page.
- Each `Document` has `page_content` (str) and `metadata` (dict with `source` + `page`).
- **`pathlib.Path(__file__).parent`** for robust file resolution.
- PDF used here: 104-page Node.js book.
- `PyPDFLoader` is the default — alternative loaders (`PyMuPDFLoader`, `pdfplumber`) for complex layouts.
- Image-only PDFs need OCR first.
- Loading is **fast** (seconds), and the loaded content is ready for chunking.

---

## 14. Things I still want to figure out

- What's the right loader for **PDFs with lots of tables**?
- How does **page numbering** in `metadata['page']` interact with PDF tables of contents?
- For **scanned PDFs**, what's the best OCR + load pipeline?
- How to handle **password-protected** PDFs?
- For **very large PDFs** (1000+ pages), is loading them all at once a memory issue?
- How does `PyPDFLoader` handle **embedded images** (drops them? Notes them in metadata?)?

---

## 15. Things to dig into

- **`pypdf` docs**: https://pypdf.readthedocs.io
- **LangChain document loaders**: https://python.langchain.com/docs/integrations/document_loaders/
- **`unstructured.io`** for hardest PDFs: https://unstructured.io
- **Hands-on**: try loading 3 different PDFs (book, scanned doc, table-heavy report). Note where `PyPDFLoader` struggles.

---

## 16. Next up in this section

Now split the loaded pages into smaller chunks suitable for embedding:

- [ ] [[09 - Smart Chunking with RecursiveCharacterTextSplitter]] — chunking with overlap.

---

## Related
- [[07 - Introduction to LangChain]] — the library this uses.
- [[04 - The Indexing Phase]] — where loading sits in the pipeline.
- [[09 - Smart Chunking with RecursiveCharacterTextSplitter]] — what comes next.

## Sources
- `pypdf` docs — https://pypdf.readthedocs.io
- LangChain document loaders — https://python.langchain.com/docs/integrations/document_loaders/
- `unstructured.io` — https://unstructured.io
