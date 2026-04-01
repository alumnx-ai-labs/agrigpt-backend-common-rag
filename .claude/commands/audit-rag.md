---
description: Deep audit of the RAG pipeline — chunking, embedding quality, Pinecone schema, idempotency, performance
argument-hint: "[all | chunking | embeddings | pinecone | pipeline]"
---

Run a deep RAG pipeline audit. Scope: $ARGUMENTS (default: all)

Step 1 — Discover structure:
find . -name "*.py" -not -path "./.venv/*" -not -path "./__pycache__/*" | sort
cat requirements.txt 2>/dev/null && cat .env.example 2>/dev/null

Step 2 — Based on scope:
all/chunking → grep -rln --include="*.py" "chunk\|split\|overlap" . --exclude-dir=.venv → read each file
all/embeddings → grep -rln --include="*.py" "embed\|SentenceTransformer\|encode" . --exclude-dir=.venv → read each
all/pinecone → grep -rln --include="*.py" "pinecone\|upsert\|query\|index" . --exclude-dir=.venv → read each
all/pipeline → grep -rln --include="*.py" "ingest\|pipeline\|process\|main" . --exclude-dir=.venv → read each

Step 3 — Run code-standards agent for Python quality

Step 4 — Generate report:
Component ratings: Chunking, Embeddings, Pinecone, Error Handling, Code Quality
Each rated: Optimal / Acceptable / Needs Work / Critical
Prioritised recommendations: Critical → Important → Nice to have

Ask: "Save report to file? (y/n)"
If yes → save to rag-audit-$(date +%Y-%m-%d).md
