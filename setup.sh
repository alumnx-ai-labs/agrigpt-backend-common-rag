#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  AgriGPT Claude DevOps System — One-Click Setup Script
#  Run this inside your cloned repo:
#    git clone https://github.com/alumnx-ai-labs/agrigpt-backend-common-rag
#    cd agrigpt-backend-common-rag
#    bash setup.sh
#
#  AUTH: Uses your Claude Code OAuth token (no API key purchase needed)
#  Get your token by running:  claude auth token
#  Then add it as GitHub secret named: CLAUDE_CODE_OAUTH_TOKEN
# ═══════════════════════════════════════════════════════════════

set -e
echo ""
echo "🚀 Setting up Claude DevOps System for agrigpt-backend-common-rag..."
echo ""

# ── Create all folders ─────────────────────────────────────────
mkdir -p .claude/commands
mkdir -p .claude/agents/issue-validator
mkdir -p .claude/agents/pr-reviewer
mkdir -p .claude/agents/rag-specialist
mkdir -p .claude/agents/code-standards
mkdir -p .claude/hooks
mkdir -p .github/workflows
mkdir -p .github/ISSUE_TEMPLATE

echo "✅ Folders created"

# ══════════════════════════════════════════════════════════════
# FILE 1 of 24 — CLAUDE.md
# ══════════════════════════════════════════════════════════════
cat > CLAUDE.md << 'HEREDOC'
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
HEREDOC

echo "✅ CLAUDE.md created"

# ══════════════════════════════════════════════════════════════
# FILE 2 of 24 — REVIEW.md
# ══════════════════════════════════════════════════════════════
cat > REVIEW.md << 'HEREDOC'
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
HEREDOC

echo "✅ REVIEW.md created"

# ══════════════════════════════════════════════════════════════
# FILE 3 of 24 — .claude/settings.json
# ══════════════════════════════════════════════════════════════
cat > .claude/settings.json << 'HEREDOC'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh\""
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/validate-push.sh\""
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/validate-edit.sh\""
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git log*)",
      "Bash(git diff*)",
      "Bash(git fetch*)",
      "Bash(git branch*)",
      "Bash(git stash*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(git checkout*)",
      "Bash(gh pr*)",
      "Bash(gh issue*)",
      "Bash(python -m flake8*)",
      "Bash(python -m mypy*)",
      "Bash(python -m pytest*)",
      "Bash(python -m py_compile*)",
      "Bash(pip install*)",
      "Bash(find . -name*)",
      "Bash(grep -*)"
    ],
    "deny": [
      "Bash(git push origin main)",
      "Bash(git push origin master)",
      "Bash(git push --force*)",
      "Bash(git reset --hard*)",
      "Bash(rm -rf*)"
    ]
  }
}
HEREDOC

echo "✅ .claude/settings.json created"

# ══════════════════════════════════════════════════════════════
# FILE 4 of 24 — .claude/hooks/session-start.sh
# ══════════════════════════════════════════════════════════════
cat > .claude/hooks/session-start.sh << 'HEREDOC'
#!/bin/bash
cat <<'EOF'
═══════════════════════════════════════════════════════════════════
  AgriGPT RAG Backend — Session Context Loaded
═══════════════════════════════════════════════════════════════════
PROJECT: agrigpt-backend-common-rag
TYPE   : Python RAG Pipeline
STACK  : Sentence Transformers (all-MiniLM-L6-v2, 384-dim) + Pinecone

CRITICAL RULES:
  1. Never push directly to main/master
  2. Never hardcode Pinecone/OpenAI API keys
  3. Every PR must link to issue with "Closes #N"
  4. Pinecone batch ≤ 100, embedding dim = 384
  5. Use logging, not print()

COMMANDS: /create-issue  /create-pr N  /push-code  /pull-code
          /review-pr N   /audit-rag    /standup
═══════════════════════════════════════════════════════════════════
EOF

echo ""
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "🌿 Branch: $BRANCH"
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "⚠️  You are on $BRANCH. Create a feature branch before making changes."
fi
git status --short 2>/dev/null | head -8
exit 0
HEREDOC

# ══════════════════════════════════════════════════════════════
# FILE 5 of 24 — .claude/hooks/validate-push.sh
# ══════════════════════════════════════════════════════════════
cat > .claude/hooks/validate-push.sh << 'HEREDOC'
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if ! echo "$COMMAND" | grep -qE '^git push'; then
  exit 0
fi

echo "🔍 Running pre-push checks..." >&2

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "❌ BLOCKED: Direct push to '$BRANCH' is not allowed." >&2
  echo "   Create a feature branch: git checkout -b fix/issue-N" >&2
  exit 2
fi

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

for file in $STAGED_FILES; do
  if [[ -f "$file" ]] && [[ "$file" == *.py || "$file" == *.env ]]; then
    MATCHES=$(grep -nE "(PINECONE_API_KEY|openai_api_key|api_key|password|secret)\s*=\s*['\"][a-zA-Z0-9_\-]{10,}['\"]" "$file" 2>/dev/null || true)
    if [[ -n "$MATCHES" ]]; then
      echo "❌ BLOCKED: Hardcoded secret detected in $file:" >&2
      echo "$MATCHES" >&2
      echo "   Use os.environ.get() or python-dotenv instead." >&2
      exit 2
    fi
  fi
done

if echo "$STAGED_FILES" | grep -qE "^\.env$"; then
  echo "❌ BLOCKED: .env file is staged. Run: git reset HEAD .env" >&2
  exit 2
fi

PY_FILES=$(echo "$STAGED_FILES" | grep "\.py$" || true)
for pyfile in $PY_FILES; do
  if [[ -f "$pyfile" ]]; then
    RESULT=$(python -m py_compile "$pyfile" 2>&1 || true)
    if [[ -n "$RESULT" ]]; then
      echo "❌ BLOCKED: Syntax error in $pyfile: $RESULT" >&2
      exit 2
    fi
  fi
done

echo "✅ Pre-push checks passed." >&2
exit 0
HEREDOC

# ══════════════════════════════════════════════════════════════
# FILE 6 of 24 — .claude/hooks/validate-edit.sh
# ══════════════════════════════════════════════════════════════
cat > .claude/hooks/validate-edit.sh << 'HEREDOC'
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.py ]] || [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

SECRET_HITS=$(grep -nE "(PINECONE_API_KEY|openai_api_key|api_key|password|secret)\s*=\s*['\"][a-zA-Z0-9_\-]{10,}['\"]" "$FILE_PATH" 2>/dev/null || true)
if [[ -n "$SECRET_HITS" ]]; then
  echo "⚠️  SECURITY: Possible hardcoded secret in $FILE_PATH:" >&2
  echo "$SECRET_HITS" >&2
fi

if [[ "$FILE_PATH" != *test* ]]; then
  PRINT_HITS=$(grep -nE "^\s*print\(" "$FILE_PATH" 2>/dev/null || true)
  if [[ -n "$PRINT_HITS" ]]; then
    echo "⚠️  Use logging instead of print() in $FILE_PATH:" >&2
    echo "$PRINT_HITS" >&2
  fi
fi

BARE_EXCEPT=$(grep -nE "^\s*except\s*:" "$FILE_PATH" 2>/dev/null || true)
if [[ -n "$BARE_EXCEPT" ]]; then
  echo "⚠️  Bare except: found in $FILE_PATH (catch specific exceptions):" >&2
  echo "$BARE_EXCEPT" >&2
fi

exit 0
HEREDOC

chmod +x .claude/hooks/session-start.sh
chmod +x .claude/hooks/validate-push.sh
chmod +x .claude/hooks/validate-edit.sh

echo "✅ Hooks created and made executable"

# ══════════════════════════════════════════════════════════════
# FILE 7 of 24 — .claude/agents/issue-validator/AGENT.md
# ══════════════════════════════════════════════════════════════
cat > .claude/agents/issue-validator/AGENT.md << 'HEREDOC'
---
name: issue-validator
description: Validates GitHub issues for quality and relevance to the AgriGPT RAG backend
tools: Bash, Read, Glob, Grep
model: sonnet
---

You are the Issue Quality Gate for agrigpt-backend-common-rag — a Python RAG pipeline (PDF ingestion → chunking → Sentence Transformers embeddings → Pinecone vector DB).

## Validation Rules

TITLE (all must pass):
- Starts with: Bug:, Feature:, Fix:, Docs:, Chore:, Enhancement:, Test:, or Perf:
- At least 15 characters after the prefix
- No vague words: "broken", "fix", "error", "issue", "update", "problem"
- Not gibberish or test content
- Relates to: PDF, chunking, embeddings, Pinecone, RAG, ingestion, pipeline, metadata

DESCRIPTION (all must pass):
- At least 120 total characters
- For Bug: must include actual behavior, expected behavior, steps to reproduce
- For Feature: must include problem, proposed solution, acceptance criteria
- No placeholder text (TBD, TODO, "describe here")

## Output

PASS → recommend label "valid-issue" + write welcome comment

FAIL → list each violated rule + show a corrected example + instruct to close the issue

Example PASS comment:
```
✅ Issue accepted — quality standards met.
Component: [chunking / embeddings / Pinecone / PDF loader / pipeline]
Summary: [1-sentence summary]
When submitting a PR, include `Closes #[N]` in the PR description.
```

Example FAIL comment:
```
❌ Issue closed — quality standards not met.

Problems:
- [specific rule violated]

Corrected example:
Title: `Bug: PDF chunker returns empty list for scanned image-only documents`
Description: ...
```
HEREDOC

echo "✅ Agent: issue-validator created"

# ══════════════════════════════════════════════════════════════
# FILE 8 of 24 — .claude/agents/pr-reviewer/AGENT.md
# ══════════════════════════════════════════════════════════════
cat > .claude/agents/pr-reviewer/AGENT.md << 'HEREDOC'
---
name: pr-reviewer
description: Deep code reviewer for AgriGPT RAG backend PRs — checks issue alignment, code diff, RAG correctness, approve/reject
tools: Bash, Read, Glob, Grep
model: sonnet
---

You are a senior ML/backend engineer reviewing PRs for agrigpt-backend-common-rag (Python RAG pipeline: PDF → chunking → Sentence Transformers 384-dim → Pinecone).

## Review Process

Phase 1 — Issue Link Check:
Run: gh pr view [PR_NUMBER] --json body,title,number,headRefName
Scan body for: Closes #N, Fixes #N, Resolves #N
If NO issue → REJECT immediately, no code review

Phase 2 — Fetch Issue Requirements:
Run: gh issue view [N] --json number,title,body,labels

Phase 3 — Analyze Code Diff:
Run: gh pr diff [PR_NUMBER]

Python checks:
- PEP8, type hints on public functions, docstrings, no bare except, no print(), no commented-out blocks

RAG checks:
- No hardcoded Pinecone/OpenAI keys
- Chunk size/overlap configurable via env vars
- Pinecone batch ≤ 100 vectors
- Vector dimension = 384
- Metadata schema consistent
- Pipeline is idempotent (vector_id = file_hash + chunk_index)
- No silent failures

Phase 4 — Requirements Coverage: Table matching issue requirements to diff changes

Phase 5 — Decision:
APPROVE if: valid issue, diff matches requirements, no violations
REJECT if: no issue, diff doesn't match, hardcoded secrets, wrong dimensions

On APPROVE:
  gh pr review [N] --approve --body "[detailed comment]"
  gh pr edit [N] --add-label "claude:approved"
  gh pr merge [N] --auto --squash --delete-branch

On REJECT:
  gh pr review [N] --request-changes --body "[detailed comment]"
  gh pr edit [N] --add-label "claude:rejected"
HEREDOC

echo "✅ Agent: pr-reviewer created"

# ══════════════════════════════════════════════════════════════
# FILE 9 of 24 — .claude/agents/rag-specialist/AGENT.md
# ══════════════════════════════════════════════════════════════
cat > .claude/agents/rag-specialist/AGENT.md << 'HEREDOC'
---
name: rag-specialist
description: Deep RAG pipeline expert — audits chunking, embedding quality, Pinecone schema, retrieval accuracy, and pipeline performance
tools: Bash, Read, Glob, Grep
model: sonnet
---

You are a senior RAG engineer specializing in production pipelines for agrigpt-backend-common-rag.

Stack: PDF → text extraction → chunking → Sentence Transformers (all-MiniLM-L6-v2, 384-dim) → Pinecone

## Chunking Audit
Check for:
- Configurable chunk size and overlap (env vars, not hardcoded)
- Sentence boundary preservation
- Empty chunk filtering: [c for c in chunks if c.strip()]
- Overlap ~10-20% of chunk size

## Embedding Audit
Check for:
- Batch encoding: model.encode(chunks, batch_size=32)
- Output dimension = 384 for all-MiniLM-L6-v2
- Model loaded once, not inside loops
- normalize_embeddings=True

## Pinecone Audit
Check for:
- Deterministic vector IDs: f"{file_hash}_{chunk_index}"
- Batch size ≤ 100 per upsert call
- Consistent metadata schema: source_file, chunk_index, total_chunks, chunk_text, ingested_at
- Namespace usage for multi-tenant isolation

## Pipeline Idempotency
- Re-running ingestion must NOT create duplicate vectors
- Use file hash as part of vector ID

## Output Format
Always give:
- Rating per component: Optimal / Acceptable / Needs Work / Critical
- Recommended changes in priority order: Critical → Important → Nice to have
HEREDOC

echo "✅ Agent: rag-specialist created"

# ══════════════════════════════════════════════════════════════
# FILE 10 of 24 — .claude/agents/code-standards/AGENT.md
# ══════════════════════════════════════════════════════════════
cat > .claude/agents/code-standards/AGENT.md << 'HEREDOC'
---
name: code-standards
description: Enforces Python code standards — PEP8, type hints, docstrings, security, naming conventions
tools: Bash, Read, Glob, Grep
model: haiku
---

You are a strict Python code standards enforcer for agrigpt-backend-common-rag. You check form, not business logic.

## Run These Checks

1. Linting:
   python -m flake8 . --max-line-length=100 --exclude=.venv,__pycache__ 2>&1 | head -50
   python -m mypy . --ignore-missing-imports 2>&1 | head -50

2. Secret scan:
   grep -rn --include="*.py" -E "(api_key|PINECONE_API_KEY|password|secret)\s*=\s*['\"][a-zA-Z0-9_\-]{10,}['\"]" . 2>/dev/null

3. print() in production:
   grep -rn --include="*.py" "^\s*print(" . --exclude="test_*.py" --exclude-dir=.venv 2>/dev/null

4. Bare excepts:
   grep -rn --include="*.py" "except:" . --exclude-dir=.venv 2>/dev/null

5. Unpinned requirements:
   cat requirements.txt 2>/dev/null

## Output Format
```
## Code Standards Report
### Linter: [PASS / N violations]
### Secrets: [CLEAN / FOUND at file:line]
### print(): [CLEAN / FOUND at file:line]
### Bare except: [CLEAN / FOUND at file:line]
### Dependencies: [Pinned / Unpinned — list]
### Overall: PASS or FAIL — list blockers
```
HEREDOC

echo "✅ Agent: code-standards created"

# ══════════════════════════════════════════════════════════════
# FILE 11 of 24 — .claude/commands/create-issue.md
# ══════════════════════════════════════════════════════════════
cat > .claude/commands/create-issue.md << 'HEREDOC'
---
description: Create a properly validated GitHub issue for the AgriGPT RAG backend
argument-hint: "[bug|feature|fix|docs|chore|perf] [short description]"
---

Create a GitHub issue for agrigpt-backend-common-rag. Arguments: $ARGUMENTS

Step 1 — Parse Arguments:
Extract issue type (bug/feature/fix/docs/chore/perf) and description from $ARGUMENTS.
If missing, ask the user for: type, one-sentence description, affected component (PDF loader / chunker / embeddings / Pinecone / pipeline / config).

Step 2 — Gather Details based on type:
For bugs: actual behavior, expected behavior, steps to reproduce, environment, error messages
For features: problem being solved, proposed solution, acceptance criteria (as checkboxes)

Step 3 — Validate before creating:
- Title must start with type prefix (Bug:, Feature:, Fix:, Docs:, Chore:, Perf:)
- Title must be at least 15 meaningful characters after prefix
- Description must be at least 120 characters
- No placeholder text

Step 4 — Create:
gh issue create --title "[TYPE]: [Description]" --body "[Full description]" --label "[bug|enhancement|documentation|performance]"

After creation: show the issue URL and number. Remind: "Add `Closes #[N]` to your PR description."
HEREDOC

echo "✅ Command: create-issue created"

# ══════════════════════════════════════════════════════════════
# FILE 12 of 24 — .claude/commands/create-pr.md
# ══════════════════════════════════════════════════════════════
cat > .claude/commands/create-pr.md << 'HEREDOC'
---
description: Create a validated PR linked to a GitHub issue — runs checks, creates branch, pushes, raises PR
argument-hint: "[issue-number]"
---

Create a pull request for issue #$ARGUMENTS in agrigpt-backend-common-rag.

Step 1 — Validate issue exists:
gh issue view $ARGUMENTS --json number,title,body,state,labels
If closed or missing → stop and tell user.

Step 2 — Check branch state:
git status && git branch --show-current
If on main/master → create: git checkout -b fix/issue-$ARGUMENTS
If uncommitted changes → ask: stash, commit, or abort?

Step 3 — Pre-push validation:
python -m flake8 . --max-line-length=100 --exclude=.venv,__pycache__ 2>&1
If lint fails → show violations, ask to fix before proceeding.
python -m pytest tests/ -v --tb=short 2>&1 || echo "No tests directory"
If tests fail → STOP. Show failures.
grep -rn --include="*.py" -E "(PINECONE_API_KEY|api_key|password)\s*=\s*['\"][a-zA-Z0-9]{10,}['\"]" . 2>/dev/null
If secrets found → STOP immediately.

Step 4 — Stage, commit, push:
git add -A
git commit -m "fix: resolve issue #$ARGUMENTS"
git push origin $(git branch --show-current)

Step 5 — Create PR:
Extract acceptance criteria from the issue body as checkboxes.
gh pr create \
  --title "$(gh issue view $ARGUMENTS --json title -q .title)" \
  --body "## Linked Issue
Closes #$ARGUMENTS

## What this PR does
[describe implementation]

## Issue Acceptance Criteria
[checkboxes from issue]

## RAG Pipeline Impact
- [ ] Chunking behavior unchanged or intentionally modified
- [ ] Pinecone metadata schema unchanged or migration handled
- [ ] Embedding dimensions unchanged (384 for all-MiniLM-L6-v2)
- [ ] Pipeline is idempotent (re-run safe)"

Step 6 — Show PR URL. Remind: Claude will auto-review this PR on GitHub.
HEREDOC

echo "✅ Command: create-pr created"

# ══════════════════════════════════════════════════════════════
# FILE 13 of 24 — .claude/commands/push-code.md
# ══════════════════════════════════════════════════════════════
cat > .claude/commands/push-code.md << 'HEREDOC'
---
description: Validate and push code with full Python + RAG standards checks
argument-hint: "[commit message]"
---

Push code with full validation. Commit message: "$ARGUMENTS"

Check 1 — Branch safety:
BRANCH=$(git branch --show-current)
If main or master → BLOCK: "Create a feature branch first: git checkout -b fix/issue-N"

Check 2 — Secret scan (CRITICAL):
grep -rn --include="*.py" -E "(PINECONE_API_KEY|openai_api_key|api_key|password)\s*=\s*['\"][a-zA-Z0-9_\-]{10,}['\"]" . --exclude-dir=.venv 2>/dev/null
If found → BLOCK. Never push secrets.

Check 3 — .env staged:
git status --short | grep "^[AM].*\.env$"
If found → BLOCK.

Check 4 — Python linting:
python -m flake8 . --max-line-length=100 --exclude=.venv,__pycache__ --count 2>&1
If violations → WARN, ask: "Fix now or push anyway?"

Check 5 — Tests:
python -m pytest tests/ -v --tb=short -q 2>&1 || echo "No tests/ directory"
If tests fail → BLOCK. Show which tests failed.

Check 6 — print() in production:
grep -rn --include="*.py" "^\s*print(" . --exclude-dir=.venv --exclude="test_*.py" 2>/dev/null
If found → WARN with file:line.

If all critical checks pass:
git add -A
git commit -m "$ARGUMENTS"
git push origin $(git branch --show-current)

After push: show branch, commit hash, files changed. If feature branch: suggest /create-pr N
HEREDOC

echo "✅ Command: push-code created"

# ══════════════════════════════════════════════════════════════
# FILE 14 of 24 — .claude/commands/pull-code.md
# ══════════════════════════════════════════════════════════════
cat > .claude/commands/pull-code.md << 'HEREDOC'
---
description: Safely pull latest code from remote, sync dependencies, and report what changed
argument-hint: "[branch-name]"
---

Pull the latest code safely. Target: $ARGUMENTS (default: current branch)

Step 1 — Check working state:
git status --short
If uncommitted changes → ask: stash, commit, or abort?
If stash: git stash push -m "auto-stash before pull $(date +%Y-%m-%d)"

Step 2 — Fetch and show incoming changes:
git fetch origin
TARGET="${ARGUMENTS:-$(git branch --show-current)}"
git log HEAD..origin/$TARGET --oneline 2>/dev/null | head -20
Show: "These commits will be pulled: [list]"
git pull origin $TARGET

If merge conflicts → STOP, list conflicting files. Do NOT auto-resolve.

Step 3 — Detect dependency changes:
git diff HEAD~1 HEAD -- requirements.txt pyproject.toml 2>/dev/null | head -30
If changed → pip install -r requirements.txt --quiet

Step 4 — Check config changes:
git diff HEAD~1 HEAD -- .env.example config.py settings.py 2>/dev/null
If changed → warn: "Check your local .env matches .env.example"

Step 5 — Summary:
Branch, commits added, files changed, dependency status, config status
If stash was applied → git stash pop
HEREDOC

echo "✅ Command: pull-code created"

# ══════════════════════════════════════════════════════════════
# FILE 15 of 24 — .claude/commands/review-pr.md
# ══════════════════════════════════════════════════════════════
cat > .claude/commands/review-pr.md << 'HEREDOC'
---
description: Manually trigger deep PR review — checks issue alignment, code diff, RAG correctness, posts GitHub review
argument-hint: "[pr-number]"
---

Trigger full manual review of PR #$ARGUMENTS for agrigpt-backend-common-rag.

Phase 1 — Load PR context:
gh pr view $ARGUMENTS --json number,title,body,state,isDraft,headRefName,baseRefName,author,files,additions,deletions

Phase 2 — Extract linked issue:
Scan PR body for: Closes #N, Fixes #N, Resolves #N
If NO issue found → stop: "Add Closes #N to PR description and retry."
gh issue view [N] --json number,title,body,labels,state

Phase 3 — Code diff analysis:
gh pr diff $ARGUMENTS
Use @"rag-specialist (agent)" to evaluate RAG-specific changes.
Use @"code-standards (agent)" to run Python quality checks.

Phase 4 — Requirements coverage matrix:
Build a table comparing each issue requirement to code changes.

Phase 5 — Decision:
If APPROVED:
  gh pr review $ARGUMENTS --approve --body "[detailed approval]"
  gh pr edit $ARGUMENTS --add-label "claude:approved"
  echo "✅ PR approved. In claude:approved queue."

If REJECTED:
  gh pr review $ARGUMENTS --request-changes --body "[detailed rejection]"
  gh pr edit $ARGUMENTS --add-label "claude:rejected"
  echo "❌ PR rejected. See review comment for what to fix."

Show terminal summary:
- Issue: #N [title]
- Verdict: APPROVED / REJECTED
- Requirements met: X/Y
- Code quality: PASS/ISSUES
- RAG checks: PASS/ISSUES
HEREDOC

echo "✅ Command: review-pr created"

# ══════════════════════════════════════════════════════════════
# FILE 16 of 24 — .claude/commands/audit-rag.md
# ══════════════════════════════════════════════════════════════
cat > .claude/commands/audit-rag.md << 'HEREDOC'
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
HEREDOC

echo "✅ Command: audit-rag created"

# ══════════════════════════════════════════════════════════════
# FILE 17 of 24 — .claude/commands/standup.md
# ══════════════════════════════════════════════════════════════
cat > .claude/commands/standup.md << 'HEREDOC'
---
description: Generate a standup update from recent git activity, open PRs, and linked issues
argument-hint: "[hours-back — default 24]"
---

Generate standup for agrigpt-backend-common-rag. Look back: $ARGUMENTS hours (default: 24)

Step 1 — Git activity:
HOURS="${ARGUMENTS:-24}"
git log --since="$HOURS hours ago" --oneline --author="$(git config user.email)" 2>/dev/null

Step 2 — Open PRs you own:
gh pr list --author "@me" --state open --json number,title,labels,reviewDecision

Step 3 — Issues assigned to you:
gh issue list --assignee "@me" --state open --json number,title,labels

Step 4 — PRs waiting for your review:
gh pr list --reviewer "@me" --state open --json number,title,author,labels

Step 5 — Format and output:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  STANDUP — [Today's Date]
  agrigpt-backend-common-rag
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ YESTERDAY: [commits, PRs]
🔨 TODAY: [next from open issues/PRs]
🚧 BLOCKERS: [stuck PRs, unassigned issues]
📋 OPEN PRs: [list with labels]
📌 OPEN ISSUES: [list]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HEREDOC

echo "✅ Command: standup created"

# ══════════════════════════════════════════════════════════════
# FILE 18 of 24 — .github/workflows/validate-issue.yml
# ══════════════════════════════════════════════════════════════
cat > .github/workflows/validate-issue.yml << 'HEREDOC'
name: "Claude — Issue Quality Gate"

on:
  issues:
    types: [opened, edited]

permissions:
  issues: write
  contents: read

jobs:
  validate-issue:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Claude Issue Validator
        uses: anthropics/claude-code-action@v1
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
          timeout_minutes: 5
          prompt: |
            You are the Issue Quality Gate for agrigpt-backend-common-rag — a Python RAG pipeline (PDF → chunking → Sentence Transformers 384-dim → Pinecone).

            ISSUE SUBMITTED:
            Number : ${{ github.event.issue.number }}
            Title  : ${{ github.event.issue.title }}
            Author : ${{ github.event.issue.user.login }}
            Body:
            ${{ github.event.issue.body }}

            TITLE RULES (all must pass):
            1. Must start with: Bug:, Feature:, Fix:, Docs:, Chore:, Enhancement:, Test:, or Perf:
            2. At least 15 meaningful characters after the prefix
            3. Must NOT use only vague words: "broken", "fix", "help", "error", "issue", "update", "problem"
            4. Must NOT be random characters (asdf, test123, aaa)
            5. Should relate to: PDF, chunking, embeddings, Pinecone, RAG, ingestion, pipeline, metadata

            DESCRIPTION RULES (all must pass):
            1. At least 120 total characters
            2. For Bug: must describe actual behavior, expected behavior, AND steps to reproduce
            3. For Feature: must describe problem, proposed solution, AND acceptance criteria
            4. No placeholder text (TBD, TODO, "describe your issue here")

            CASE A — FAILS: run in order:
            1. gh issue edit ${{ github.event.issue.number }} --add-label "invalid"
            2. Post comment explaining exactly what was wrong and show a corrected example
            3. gh issue close ${{ github.event.issue.number }} --reason "not planned"

            CASE B — PASSES: run in order:
            1. gh issue edit ${{ github.event.issue.number }} --add-label "valid-issue"
            2. Post welcome comment: "✅ Issue accepted. Add `Closes #${{ github.event.issue.number }}` to your PR description when you raise one."

            Execute now using gh CLI. Be specific about what was wrong.
HEREDOC

echo "✅ Workflow: validate-issue.yml created"

# ══════════════════════════════════════════════════════════════
# FILE 19 of 24 — .github/workflows/pr-ai-review.yml
# ══════════════════════════════════════════════════════════════
cat > .github/workflows/pr-ai-review.yml << 'HEREDOC'
name: "Claude — PR Review & Auto-Merge"

on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  issue_comment:
    types: [created]

permissions:
  contents: write
  pull-requests: write
  issues: read

jobs:
  auto-review:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request' && github.event.pull_request.draft == false

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Claude Deep PR Review
        uses: anthropics/claude-code-action@v1
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
          timeout_minutes: 12
          prompt: |
            You are a senior ML/backend engineer reviewing a PR for agrigpt-backend-common-rag (Python RAG pipeline: PDF → chunking → Sentence Transformers 384-dim → Pinecone).

            PR NUMBER : ${{ github.event.pull_request.number }}
            PR TITLE  : ${{ github.event.pull_request.title }}
            PR AUTHOR : ${{ github.event.pull_request.user.login }}
            PR BRANCH : ${{ github.event.pull_request.head.ref }} → ${{ github.event.pull_request.base.ref }}
            PR BODY:
            ${{ github.event.pull_request.body }}

            STEP 1 — LINKED ISSUE CHECK:
            Scan PR body for: Closes #N, Fixes #N, Resolves #N, or #N
            If NO issue number found → run:
              gh pr review ${{ github.event.pull_request.number }} --request-changes --body "## ❌ Rejected — No Linked Issue\n\nThis PR has no linked GitHub issue. Add `Closes #ISSUE_NUMBER` to your PR description and push an update."
              gh pr edit ${{ github.event.pull_request.number }} --add-label "claude:rejected"
            Then STOP.

            STEP 2 — FETCH ISSUE:
            gh issue view [N] --json number,title,body,labels
            Extract: problem, acceptance criteria, affected components

            STEP 3 — CODE DIFF:
            gh pr diff ${{ github.event.pull_request.number }}
            gh pr view ${{ github.event.pull_request.number }} --json files,additions,deletions

            Check Python: PEP8, type hints, docstrings, no bare except, no print(), no commented code
            Check RAG: no hardcoded keys, configurable chunk size, batch ≤ 100, dim = 384, idempotent IDs, no silent failures

            STEP 4 — REQUIREMENTS TABLE:
            Build table: Issue Requirement | Files Changed | Status (✅/❌/⚠️) | Evidence

            STEP 5 — DECISION:
            APPROVE if: valid issue, diff addresses all requirements, no critical violations
            REJECT if: no issue, wrong files changed, missing requirements, hardcoded secrets, wrong dimensions

            IF APPROVED:
              gh pr edit ${{ github.event.pull_request.number }} --add-label "claude:approved" 2>/dev/null || true
              gh pr review ${{ github.event.pull_request.number }} --approve --body "## ✅ Claude Review: APPROVED\n\nCloses #[N] — [title]\n\n[verification table]\n[what PR does]\n[requirements coverage]\n\n*Auto-approved. In the claude:approved merge queue.*"
              gh pr merge ${{ github.event.pull_request.number }} --auto --squash --delete-branch 2>/dev/null || true

            IF REJECTED:
              gh pr edit ${{ github.event.pull_request.number }} --add-label "claude:rejected" 2>/dev/null || true
              gh pr review ${{ github.event.pull_request.number }} --request-changes --body "## ❌ Claude Review: NOT APPROVED\n\nIssue #[N]\n\n[why rejected]\n[requirements table]\n[fixes needed]\n\n*Push fixes and Claude will re-review automatically.*"

  manual-review:
    runs-on: ubuntu-latest
    if: |
      github.event_name == 'issue_comment' &&
      github.event.issue.pull_request != null &&
      contains(github.event.comment.body, '@claude review')

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Claude Manual Re-Review
        uses: anthropics/claude-code-action@v1
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
          timeout_minutes: 12
          prompt: |
            @${{ github.event.comment.user.login }} requested a re-review of PR #${{ github.event.issue.number }}.

            Run the full review:
            1. gh pr view ${{ github.event.issue.number }} --json body,title,number,headRefName
            2. Extract linked issue number from PR body
            3. gh issue view [N] — fetch requirements
            4. gh pr diff ${{ github.event.issue.number }} — get code diff
            5. Compare requirements vs implementation
            6. Check RAG pipeline integrity and Python standards
            7. Post detailed review, update label (claude:approved or claude:rejected)
            8. If approved: gh pr merge ${{ github.event.issue.number }} --auto --squash

            Repo: agrigpt-backend-common-rag (Python RAG, Pinecone, Sentence Transformers 384-dim)
HEREDOC

echo "✅ Workflow: pr-ai-review.yml created"

# ══════════════════════════════════════════════════════════════
# FILE 20 of 24 — .github/ISSUE_TEMPLATE/bug-report.yml
# ══════════════════════════════════════════════════════════════
cat > .github/ISSUE_TEMPLATE/bug-report.yml << 'HEREDOC'
name: "Bug Report"
description: "Report a bug in the AgriGPT RAG pipeline"
title: "Bug: [Short description of the bug]"
labels: ["bug", "triage"]

body:
  - type: markdown
    attributes:
      value: |
        ## 🐛 Bug Report
        > Issues with vague titles or incomplete descriptions are **automatically closed** by Claude.

  - type: dropdown
    id: component
    attributes:
      label: "Affected Component"
      options:
        - "PDF Ingestion / Text Extraction"
        - "Text Chunking / Overlap Strategy"
        - "Embedding Generation (Sentence Transformers)"
        - "Pinecone Upsert / Vector Storage"
        - "Pinecone Query / Retrieval"
        - "Metadata Handling"
        - "Pipeline Orchestration"
        - "Configuration / Environment Setup"
        - "CI/CD / DevOps"
        - "Other"
    validations:
      required: true

  - type: textarea
    id: actual-behavior
    attributes:
      label: "Actual Behavior"
      description: "What is happening right now? Include error messages and stack traces."
      placeholder: "When running the ingestion pipeline on a 50-page PDF, the chunker returns 0 chunks. No error is raised."
    validations:
      required: true

  - type: textarea
    id: expected-behavior
    attributes:
      label: "Expected Behavior"
      description: "What should happen instead?"
      placeholder: "The chunker should return N chunks based on CHUNK_SIZE env var, or raise ValueError if no text found."
    validations:
      required: true

  - type: textarea
    id: reproduce
    attributes:
      label: "Steps to Reproduce"
      placeholder: |
        1. Set CHUNK_SIZE=512 in .env
        2. Run: python ingest.py --file sample.pdf
        3. Observe: 0 chunks returned, no error
    validations:
      required: true

  - type: input
    id: environment
    attributes:
      label: "Environment"
      placeholder: "Python 3.11 | pinecone-client 3.x | sentence-transformers 2.x | Local"
    validations:
      required: true

  - type: dropdown
    id: severity
    attributes:
      label: "Severity"
      options:
        - "Critical — Data loss or pipeline completely broken"
        - "High — Core RAG functionality broken"
        - "Medium — Partial functionality broken, workaround exists"
        - "Low — Minor issue, non-blocking"
    validations:
      required: true
HEREDOC

echo "✅ Issue template: bug-report.yml created"

# ══════════════════════════════════════════════════════════════
# FILE 21 of 24 — .github/ISSUE_TEMPLATE/feature-request.yml
# ══════════════════════════════════════════════════════════════
cat > .github/ISSUE_TEMPLATE/feature-request.yml << 'HEREDOC'
name: "Feature Request"
description: "Propose a new feature or enhancement for the AgriGPT RAG pipeline"
title: "Feature: [Short description of the feature]"
labels: ["enhancement", "triage"]

body:
  - type: markdown
    attributes:
      value: |
        ## ✨ Feature Request
        > Issues with vague titles or incomplete descriptions are **automatically closed** by Claude.

  - type: dropdown
    id: component
    attributes:
      label: "Target Component"
      options:
        - "PDF Ingestion / Text Extraction"
        - "Text Chunking / Overlap Strategy"
        - "Embedding Generation (Sentence Transformers)"
        - "Pinecone Upsert / Vector Storage"
        - "Pinecone Query / Retrieval"
        - "Metadata Schema"
        - "Pipeline Orchestration / Configuration"
        - "Performance / Batching"
        - "Observability / Logging"
        - "CI/CD / DevOps"
    validations:
      required: true

  - type: textarea
    id: problem
    attributes:
      label: "Problem / Gap"
      description: "What is missing or broken that this feature would fix?"
      placeholder: "Currently, chunk size and overlap are hardcoded to 512 and 50. This means we cannot optimize RAG retrieval without changing source code and redeploying."
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: "Proposed Solution"
      description: "Describe what you want built. Be specific."
      placeholder: "Add CHUNK_SIZE and CHUNK_OVERLAP environment variables read at startup via os.environ.get(). Update .env.example with defaults."
    validations:
      required: true

  - type: textarea
    id: acceptance-criteria
    attributes:
      label: "Acceptance Criteria"
      description: "Checkboxes that must ALL be true for this to be done. Claude uses these to verify the PR."
      placeholder: |
        - [ ] CHUNK_SIZE env var read at startup, default 512
        - [ ] CHUNK_OVERLAP env var read at startup, default 50
        - [ ] .env.example updated
        - [ ] Unit tests cover different chunk sizes
    validations:
      required: true

  - type: dropdown
    id: priority
    attributes:
      label: "Priority"
      options:
        - "Critical — Blocking current work"
        - "High — Significant improvement"
        - "Medium — Clear value, not urgent"
        - "Low — Nice to have"
    validations:
      required: true
HEREDOC

echo "✅ Issue template: feature-request.yml created"

# ══════════════════════════════════════════════════════════════
# FILE 22 of 24 — .github/ISSUE_TEMPLATE/config.yml
# ══════════════════════════════════════════════════════════════
cat > .github/ISSUE_TEMPLATE/config.yml << 'HEREDOC'
blank_issues_enabled: false
contact_links:
  - name: "📖 Project Standards"
    url: https://github.com/alumnx-ai-labs/agrigpt-backend-common-rag/blob/main/CLAUDE.md
    about: "Read the project standards before raising an issue"
HEREDOC

echo "✅ Issue template: config.yml created"

# ══════════════════════════════════════════════════════════════
# FILE 23 of 24 — .github/pull_request_template.md
# ══════════════════════════════════════════════════════════════
cat > .github/pull_request_template.md << 'HEREDOC'
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
HEREDOC

echo "✅ PR template created"

# ══════════════════════════════════════════════════════════════
# FILE 24 of 24 — .gitignore entry
# ══════════════════════════════════════════════════════════════
if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
  echo "" >> .gitignore
  echo "# Environment secrets — never commit these" >> .gitignore
  echo ".env" >> .gitignore
  echo ".env.local" >> .gitignore
  echo ".claude/settings.local.json" >> .gitignore
  echo "✅ .gitignore updated"
else
  echo "✅ .gitignore already has .env entry"
fi

# ── Final Summary ──────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ All 24 files created successfully!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📁 What was created:"
echo "  CLAUDE.md                          ← Project rules for Claude"
echo "  REVIEW.md                          ← PR review standards"
echo "  .claude/settings.json              ← Hook configuration"
echo "  .claude/commands/   (7 files)      ← Slash commands"
echo "  .claude/agents/     (4 agents)     ← Specialized AI agents"
echo "  .claude/hooks/      (3 scripts)    ← Auto-run hooks"
echo "  .github/workflows/  (2 workflows)  ← GitHub Actions"
echo "  .github/ISSUE_TEMPLATE/ (3 files)  ← Issue forms"
echo "  .github/pull_request_template.md   ← PR form"
echo ""
echo "🔜 NEXT STEPS (do these in order):"
echo ""
echo "  ── STEP 1: Get your Claude OAuth token ──────────────────"
echo "  Run this in your terminal:"
echo "     claude auth token"
echo ""
echo "  This prints a token that looks like: sk-ant-oaut01-..."
echo "  Copy that token."
echo ""
echo "  (If 'claude' is not installed: npm install -g @anthropic-ai/claude-code)"
echo "  (Then authenticate: claude  → follow the login prompts)"
echo "  (Then run: claude auth token)"
echo ""
echo "  ── STEP 2: Add token as GitHub secret ───────────────────"
echo "  Go to: Repo → Settings → Secrets and variables → Actions"
echo "  Click: New repository secret"
echo "  Name:  CLAUDE_CODE_OAUTH_TOKEN"
echo "  Value: [paste the token from Step 1]"
echo "  Click: Add secret"
echo ""
echo "  ── STEP 3: Create GitHub labels (run this once) ─────────"
echo '     gh label create "valid-issue"      --color "0075ca" --description "Passed Claude quality check"'
echo '     gh label create "invalid"          --color "e4e669" --description "Failed Claude quality check"'
echo '     gh label create "claude:approved"  --color "0e8a16" --description "Approved by Claude AI"'
echo '     gh label create "claude:rejected"  --color "d73a4a" --description "Rejected by Claude AI"'
echo '     gh label create "needs-issue-link" --color "e99695" --description "PR missing Closes #N"'
echo ""
echo "  ── STEP 4: Enable branch protection on main ─────────────"
echo "  Repo → Settings → Branches → Add rule"
echo "  Branch name pattern: main"
echo "  ✅ Require a pull request before merging"
echo "  ✅ Require status checks to pass → add: auto-review"
echo "  ✅ Allow auto-merge"
echo "  Click: Save changes"
echo ""
echo "  ── STEP 5: Enable auto-merge on the repo ────────────────"
echo "  Repo → Settings → General → Pull Requests"
echo "  ✅ Allow auto-merge"
echo "  ✅ Allow squash merging"
echo ""
echo "  ── STEP 6: Push everything to GitHub ────────────────────"
echo "     git add ."
echo '     git commit -m "chore: add Claude AI DevOps system"'
echo "     git push origin main"
echo ""
echo "  ── STEP 7: Test it ──────────────────────────────────────"
echo "  Go to GitHub → Issues → New Issue"
echo "  Type a bad title like: 'fix bug' with no description"
echo "  Submit it. Claude should auto-close within 30 seconds."
echo ""
echo "════════════════════════════════════════════════════════"