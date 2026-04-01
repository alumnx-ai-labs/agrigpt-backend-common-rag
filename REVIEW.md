# REVIEW.md — Code Review Standards
## agrigpt-backend-common-rag

---

## Auto-Fail (PR rejected immediately if any found)

- No linked issue (`Closes #N`) in PR description
- Hardcoded `PINECONE_API_KEY`, `OPENAI_API_KEY`, or any credential in `.py` files
- `.env` file staged or committed
- Pinecone upsert with batch size > 100
- Embedding dimension ≠ 384 when using `all-MiniLM-L6-v2`
- Silent error swallowing (`except: pass`) in pipeline-critical code
- Code changes are in completely wrong files (unrelated to the issue)
- Breaking changes to Pinecone metadata schema without migration notes

---

## Must Fix Before Approval

- Missing type hints on public functions
- Missing docstrings on public functions and classes
- `print()` statements in non-test production code
- Bare `except:` without specific exception type
- Hardcoded chunk size or overlap (must be env var)
- Loading SentenceTransformer model inside a loop
- Single-item embedding or upsert calls in a loop (must batch)
- `flake8` violations (max line 100 chars, PEP8)

---

## RAG-Specific Review Criteria

### Chunking
- Chunk size uses env var: `os.environ.get("CHUNK_SIZE", "512")`
- Overlap uses env var: `os.environ.get("CHUNK_OVERLAP", "50")`
- Empty chunks are filtered: `[c for c in chunks if c.strip()]`

### Embeddings
- Model name comes from config, not hardcoded
- `model.encode()` called with `batch_size` parameter
- Model loaded once at module level, not inside function calls

### Pinecone
- `vector_id` is deterministic: `f"{file_hash}_{chunk_index}"`
- Metadata fields match existing schema
- Batch size ≤ 100 per `index.upsert()` call

### Pipeline
- Re-run safety: same PDF ingested twice = no duplicate vectors
- Errors raise exceptions, not return None silently
- Logging present at key pipeline steps
