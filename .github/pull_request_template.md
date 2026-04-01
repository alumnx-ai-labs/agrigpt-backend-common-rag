## 🔗 Linked Issue (REQUIRED — PR will be auto-rejected without this)

Closes #N

---

## 📋 What does this PR do?

<!-- 2-3 sentences: what changed and why -->

---

## ✅ Issue Acceptance Criteria

<!-- Copy each checkbox from the issue — Claude verifies these against the code diff -->

- [ ] <!-- requirement 1 from the issue -->
- [ ] <!-- requirement 2 from the issue -->

---

## 🧪 Testing

- [ ] Unit tests added or updated
- [ ] Tested locally with a real PDF
- [ ] Edge cases tested (empty PDF, large PDF, image-only)

---

## 🏗️ RAG Pipeline Impact

- [ ] Chunking behavior unchanged / intentionally modified → explain: ___
- [ ] Pinecone metadata schema unchanged / migration handled → explain: ___
- [ ] Embedding dimensions unchanged (384 for all-MiniLM-L6-v2)
- [ ] Pipeline is still idempotent (re-run safe)

---

## ⚠️ Pre-Submit Checklist

- [ ] `Closes #N` is in this PR description
- [ ] No hardcoded Pinecone API key, OpenAI key, or any secret
- [ ] No `.env` file committed
- [ ] Using `logging`, not `print()`
- [ ] Type hints on all new/modified public functions
- [ ] No bare `except:` clauses
- [ ] `flake8` passes locally
- [ ] Tests pass locally: `pytest tests/`

---

> 🤖 Claude will auto-review this PR against the linked issue.
> `claude:approved` label = eligible for merge.
> Owner queue: `is:open label:claude:approved`
