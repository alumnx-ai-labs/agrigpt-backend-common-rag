# CLAUDE.md — AgriGPT RAG Backend
## Project Intelligence File | alumnx-ai-labs/agrigpt-backend-common-rag

This file is read by Claude at the start of every local session and by GitHub Actions reviewers.

---

## What This Repo Does

Python RAG (Retrieval-Augmented Generation) pipeline for AgriGPT:
```
PDF Documents → Text Extraction → Chunking → Embeddings (all-MiniLM-L6-v2, 384-dim) → Pinecone Vector DB → Query API
```

---

## Absolute Rules (Never Break These)

| # | Rule |
|---|------|
| 1 | Never push directly to `main` or `master` — always use feature branches |
| 2 | Never hardcode Pinecone API key, OpenAI key, or any credential |
| 3 | Every PR must link to a GitHub issue with `Closes #N` |
| 4 | Pinecone upsert batch size must be ≤ 100 vectors |
| 5 | Embedding dimension must be 384 (all-MiniLM-L6-v2) |
| 6 | Use `logging` module, not `print()`, in all production code |
| 7 | All public functions must have type hints and docstrings |
| 8 | Never swallow errors silently — let them propagate |
| 9 | Pipeline must be idempotent — use `file_hash + chunk_index` as vector ID |
| 10 | Chunk size and overlap must be configurable via environment variables |

---

## Python Standards

```python
# CORRECT function signature
def chunk_text(text: str, chunk_size: int = 512, overlap: int = 50) -> list[str]:
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
```

---

## Environment Variables

```python
# CORRECT — from environment
PINECONE_API_KEY = os.environ["PINECONE_API_KEY"]
CHUNK_SIZE       = int(os.environ.get("CHUNK_SIZE", "512"))
CHUNK_OVERLAP    = int(os.environ.get("CHUNK_OVERLAP", "50"))
EMBEDDING_MODEL  = os.environ.get("EMBEDDING_MODEL", "all-MiniLM-L6-v2")

# WRONG — hardcoded
PINECONE_API_KEY = "pc-xxxxxxxxxxxx"  # NEVER DO THIS
```

---

## Git Workflow

```
1. Create issue → Claude validates → issue gets valid-issue label
2. Create branch: git checkout -b fix/issue-N
3. Write code following standards above
4. Run: /push-code "your message"  OR  /create-pr N
5. Claude reviews PR vs issue automatically on GitHub
6. Approved → auto-merged | Rejected → fix and re-push
7. Owner filters claude:approved queue for final sign-off
```

---

## Quick Commands (in Claude Code terminal)

| Command | What it does |
|---------|-------------|
| `/create-issue` | Create validated GitHub issue |
| `/create-pr 42` | Create PR linked to issue #42 |
| `/push-code "msg"` | Push with secret scan + lint + test |
| `/pull-code` | Safe pull with dependency sync |
| `/review-pr 53` | Deep manual PR review |
| `/audit-rag` | RAG pipeline health audit |
| `/standup` | Generate today's standup |

## Agents (invoke with @-mention)

| Agent | Purpose |
|-------|---------|
| `@"issue-validator"` | Validate issue quality |
| `@"pr-reviewer"` | Full PR review against issue |
| `@"rag-specialist"` | Deep RAG pipeline analysis |
| `@"code-standards"` | Python linting and standards |

---

## Owner Review Queue

```
https://github.com/alumnx-ai-labs/agrigpt-backend-common-rag/pulls?q=is%3Aopen+label%3Aclaude%3Aapproved
```
