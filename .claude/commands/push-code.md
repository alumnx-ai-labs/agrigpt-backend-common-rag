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
