# REVIEW.md — Code Review Standards
## agrigpt-backend-common-rag

This file is read by Claude during every PR review. It defines what passes and what fails.

---

## Auto-Fail (PR is rejected immediately if any of these are found)

- [ ] No linked issue (`Closes #N`) in PR description
- [ ] Hardcoded `PINECONE_API_KEY`, `OPENAI_API_KEY`, or any credential in `.py` files
- [ ] `.env` file staged or committed
- [ ] Direct changes to `main`/`master` without a PR
- [ ] Pinecone upsert with batch size > 100
- [ ] Embedding dimension ≠ 384 when using `all-MiniLM-L6-v2`
- [ ] Silent error swallowing (`except: pass`) in pipeline-critical code
- [ ] Code changes are in completely wrong files (unrelated to the issue)
- [ ] Breaking changes to Pinecone metadata schema without migration notes

---

## Must Fix Before Approval (non-blocking but flagged)

- [ ] Missing type hints on public functions
- [ ] Missing docstrings on public functions and classes
- [ ] `print()` statements in non-test production code
- [ ] Bare `except:` without specific exception type
- [ ] Hardcoded chunk size or overlap (must be env var)
- [ ] Loading SentenceTransformer model inside a loop
- [ ] Single-item embedding or upsert calls in a loop (must batch)
- [ ] `flake8` violations (max line 100 chars, PEP8)
- [ ] No tests for new functionality

---

## Skip (Don't review these)

- `requirements.txt` or `pyproject.toml` version bumps (unless introducing security issues)
- Generated files (`*.lock`, `*.egg-info`)
- Notebook files (`*.ipynb`) — reviewed separately
- Test fixtures and sample PDFs

---

## RAG-Specific Review Criteria

### Chunking Changes
When chunking code is modified, verify:
1. Chunk size uses env var: `os.environ.get("CHUNK_SIZE", "512")`
2. Overlap uses env var: `os.environ.get("CHUNK_OVERLAP", "50")`
3. Empty chunks are filtered: `[c for c in chunks if c.strip()]`
4. Sentence boundaries are preserved where possible

### Embedding Changes
When embedding code is modified, verify:
1. Model name comes from config, not hardcoded
2. `model.encode()` is called with `batch_size` parameter
3. Output dimension matches what Pinecone index expects
4. Model is loaded once at module/class level, not inside function calls

### Pinecone Changes
When Pinecone code is modified, verify:
1. `vector_id` is deterministic: `f"{file_hash}_{chunk_index}"`
2. Metadata fields match existing schema (see CLAUDE.md)
3. Batch size ≤ 100 per `index.upsert()` call
4. Namespace is used for tenant isolation if multi-tenant

### Pipeline Changes
When pipeline orchestration is modified, verify:
1. Re-run safety: the same PDF can be ingested twice without duplicating vectors
2. Error propagation: failures raise exceptions, not return None silently
3. Logging is present at key pipeline steps
4. Large PDFs are handled (memory-efficient, streaming if possible)

---

## Review Comment Tone

- Be specific — cite file names and line numbers
- Be constructive — explain why something is wrong, not just that it is
- Prioritize — separate blocking issues from suggestions
- Be final — post one comprehensive review, not multiple small comments
