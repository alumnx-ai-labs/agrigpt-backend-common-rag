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
