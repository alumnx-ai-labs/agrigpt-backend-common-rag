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
