# CLAUDE.md — AgriGPT RAG Backend
## Project Intelligence File | alumnx-ai-labs/agrigpt-backend-common-rag

This file is read by Claude at the start of every local session and by GitHub Actions reviewers.
It defines the law of this repository.

---

## What This Repo Does

This is the common RAG (Retrieval-Augmented Generation) backend for AgriGPT — an agriculture AI platform.

**Pipeline:**
```
PDF Documents
    → Text Extraction (PyPDF / pdfminer)
    → Chunking (fixed-size with overlap)
    → Embeddings (Sentence Transformers: all-MiniLM-L6-v2, 384-dim)
    → Pinecone Vector DB (batch upsert with structured metadata)
    → Query API (semantic search for downstream AI features)
```

---

## Absolute Rules (Never Break These)

| # | Rule | Why |
|---|------|-----|
| 1 | Never push directly to `main` or `master` | Breaks production |
| 2 | Never hardcode Pinecone API key, OpenAI key, or any credential | Security breach |
| 3 | Every PR must link to a GitHub issue (`Closes #N`) | Traceability |
| 4 | Pinecone upsert batch size ≤ 100 | Pinecone API limit |
| 5 | Embedding dimension must match model output (384 for all-MiniLM-L6-v2) | Pipeline correctness |
| 6 | Use `logging`, not `print()`, in all production code | Observability |
| 7 | All public functions must have type hints and docstrings | Maintainability |
| 8 | Never swallow errors silently — let them propagate | Debuggability |
| 9 | Pipeline must be idempotent (use `file_hash + chunk_index` as vector ID) | No duplicate vectors |
| 10 | Chunk size and overlap must be configurable via env vars | Experiment-friendly |

---

## Python Standards

```python
# ✅ CORRECT function signature
def chunk_text(
    text: str,
    chunk_size: int = 512,
    overlap: int = 50
) -> list[str]:
    """
    Split text into overlapping chunks for RAG ingestion.

    Args:
        text: The raw extracted text to split.
        chunk_size: Number of characters per chunk.
        overlap: Number of overlapping characters between chunks.

    Returns:
        List of text chunks.

    Raises:
        ValueError: If text is empty or chunk_size <= overlap.
    """
    ...

# ❌ WRONG
def chunk(t, s, o):  # No types, no docstring
    print(f"chunking {s}")  # print() not allowed
    try:
        ...
    except:  # Bare except not allowed
        pass
```

**Naming:**
- Files: `lowercase_underscore.py` (Python convention)
- Classes: `PascalCase`
- Functions & variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- No magic numbers — use named constants or env vars

---

## Environment Variables

All configuration must come from environment variables or `.env` (via python-dotenv).

```python
# ✅ CORRECT
import os
from dotenv import load_dotenv

load_dotenv()

PINECONE_API_KEY = os.environ["PINECONE_API_KEY"]  # Required — raises KeyError if missing
PINECONE_ENV     = os.environ.get("PINECONE_ENV", "gcp-starter")  # Optional with default
CHUNK_SIZE       = int(os.environ.get("CHUNK_SIZE", "512"))
CHUNK_OVERLAP    = int(os.environ.get("CHUNK_OVERLAP", "50"))
EMBEDDING_MODEL  = os.environ.get("EMBEDDING_MODEL", "all-MiniLM-L6-v2")

# ❌ WRONG
PINECONE_API_KEY = "pc-xxxxxxxxxxxxxxxxxxxx"  # Hardcoded secret!
chunk_size = 500  # Magic number!
```

---

## RAG Pipeline Standards

### Chunking
```python
# Chunk size must be configurable
# Overlap should be ~10% of chunk_size
# Strip whitespace from chunks
# Filter empty chunks
chunks = [c.strip() for c in raw_chunks if c.strip()]
```

### Embeddings
```python
# Always batch — never encode one-by-one in a loop
embeddings = model.encode(
    chunks,
    batch_size=32,           # Configurable
    show_progress_bar=False, # Suppress in production
    normalize_embeddings=True
)
```

### Pinecone Upsert
```python
# Vector IDs must be deterministic (idempotent)
vector_id = f"{file_hash}_{chunk_index}"

# Batch size must be ≤ 100
PINECONE_BATCH_SIZE = 100
for i in range(0, len(vectors), PINECONE_BATCH_SIZE):
    batch = vectors[i:i + PINECONE_BATCH_SIZE]
    index.upsert(vectors=batch, namespace=namespace)

# Metadata schema (keep consistent):
metadata = {
    "source_file": filename,
    "chunk_index": chunk_index,
    "total_chunks": total_chunks,
    "page_number": page_num,       # If extractable
    "chunk_text": chunk_text,
    "ingested_at": datetime.utcnow().isoformat()
}
```

---

## Git Workflow

```
1.  Create issue → Claude validates quality → issue gets valid-issue label
2.  Create branch: git checkout -b fix/issue-N  (or feature/issue-N)
3.  Write code following standards above
4.  Run locally: flake8 + mypy + pytest
5.  /push-code "your commit message"  (or /create-pr N)
6.  Claude reviews PR vs issue automatically
7.  Approved → auto-merged
8.  Rejected → fix and re-push → Claude re-reviews
9.  Owner filters claude:approved queue for final sign-off
```

**Branch naming:**
- `fix/issue-N` for bug fixes
- `feature/issue-N` for features
- `docs/issue-N` for documentation
- `perf/issue-N` for performance

---

## Available Claude Commands (run in Claude Code)

| Command | What it does |
|---------|-------------|
| `/create-issue [type] [description]` | Create validated GitHub issue |
| `/create-pr [issue-number]` | Create PR with full checks |
| `/push-code [commit message]` | Push with secret scan + lint + test |
| `/pull-code [branch]` | Safe pull with dep sync |
| `/review-pr [pr-number]` | Deep manual PR review |
| `/audit-rag [scope]` | RAG pipeline health audit |
| `/standup [hours]` | Generate standup from git activity |

## Available Claude Agents (invoke with @-mention)

| Agent | Purpose |
|-------|---------|
| `@"issue-validator"` | Validate issue quality before creating |
| `@"pr-reviewer"` | Full PR review against issue requirements |
| `@"rag-specialist"` | Deep RAG pipeline analysis and optimization |
| `@"code-standards"` | Python linting and standards enforcement |

---

## Owner Review Queue

See all Claude-approved PRs ready for merge:
```
https://github.com/alumnx-ai-labs/agrigpt-backend-common-rag/pulls?q=is%3Aopen+label%3Aclaude%3Aapproved
```

Or via CLI:
```bash
gh pr list --label "claude:approved" --state open
```

---

## Labels

| Label | Meaning |
|-------|---------|
| `valid-issue` | Issue passed Claude quality check |
| `invalid` | Issue closed — failed quality check |
| `claude:approved` | PR approved by Claude, eligible for merge |
| `claude:rejected` | PR rejected, needs fixes |
| `needs-issue-link` | PR missing `Closes #N` |
