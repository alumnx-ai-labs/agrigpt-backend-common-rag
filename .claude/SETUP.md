# Setup Guide — AgriGPT Claude DevOps System
## alumnx-ai-labs/agrigpt-backend-common-rag

---

## Complete File Map

```
agrigpt-backend-common-rag/
│
├── CLAUDE.md                          ← Project law — read every session
├── REVIEW.md                          ← PR review standards
│
├── .claude/
│   ├── settings.json                  ← Hook wiring + permissions
│   │
│   ├── commands/                      ← Slash commands (type / to use)
│   │   ├── create-issue.md            → /create-issue bug "description"
│   │   ├── create-pr.md               → /create-pr 42
│   │   ├── push-code.md               → /push-code "fix: resolve #42"
│   │   ├── pull-code.md               → /pull-code main
│   │   ├── review-pr.md               → /review-pr 53
│   │   ├── audit-rag.md               → /audit-rag all
│   │   └── standup.md                 → /standup 24
│   │
│   ├── agents/                        ← Specialized AI (invoke with @-mention)
│   │   ├── issue-validator/
│   │   │   └── AGENT.md               → @"issue-validator"
│   │   ├── pr-reviewer/
│   │   │   └── AGENT.md               → @"pr-reviewer"
│   │   ├── rag-specialist/
│   │   │   └── AGENT.md               → @"rag-specialist"
│   │   └── code-standards/
│   │       └── AGENT.md               → @"code-standards"
│   │
│   └── hooks/                         ← Auto-run scripts
│       ├── session-start.sh           ← Fires on every Claude session start
│       ├── validate-push.sh           ← Fires before every git push
│       └── validate-edit.sh           ← Fires after every file edit
│
└── .github/
    ├── workflows/
    │   ├── validate-issue.yml         ← GitHub: auto-validates new issues
    │   └── pr-ai-review.yml           ← GitHub: auto-reviews + auto-merges PRs
    │
    ├── ISSUE_TEMPLATE/
    │   ├── bug-report.yml             ← Structured bug form
    │   ├── feature-request.yml        ← Structured feature form
    │   └── config.yml                 ← Disables blank issues
    │
    └── pull_request_template.md       ← Enforces Closes #N + RAG checklist
```

---

## Setup (5 Steps)

### Step 1 — Copy files into your repo
```bash
# From your local clone of agrigpt-backend-common-rag
cp -r agrigpt-claude-system/.claude ./
cp -r agrigpt-claude-system/.github ./
cp agrigpt-claude-system/CLAUDE.md ./
cp agrigpt-claude-system/REVIEW.md ./
```

### Step 2 — Make hooks executable
```bash
chmod +x .claude/hooks/validate-push.sh
chmod +x .claude/hooks/validate-edit.sh
chmod +x .claude/hooks/session-start.sh
```

### Step 3 — Add GitHub secret
Go to: **Repo → Settings → Secrets and variables → Actions → New secret**
- Name: `ANTHROPIC_API_KEY`
- Value: your key from console.anthropic.com

### Step 4 — Create GitHub labels
```bash
gh label create "valid-issue"      --color "0075ca" --description "Passed Claude quality check"
gh label create "invalid"          --color "e4e669" --description "Failed Claude quality check"
gh label create "claude:approved"  --color "0e8a16" --description "Approved by Claude AI"
gh label create "claude:rejected"  --color "d73a4a" --description "Rejected by Claude AI"
gh label create "needs-issue-link" --color "e99695" --description "PR missing Closes #N"
```

### Step 5 — Enable branch protection + auto-merge
**Settings → Branches → Add rule for `main`:**
- ✅ Require pull request before merging
- ✅ Require status checks: `auto-review`
- ✅ Allow auto-merge

**Settings → General → Pull Requests:**
- ✅ Allow auto-merge
- ✅ Allow squash merging

---

## How the System Works End-to-End

```
ISSUE CREATED
    ↓
GitHub Actions: validate-issue.yml fires in < 30 seconds
    ↓
Claude checks title format, description completeness, component relevance
    ↓
❌ Fails → Issue auto-closed with exact feedback + rewrite example
✅ Passes → label: valid-issue + welcome comment with issue number
    ↓

DEVELOPER WORKS ON FIX
Claude Code locally:
  - session-start.sh shows context + open PRs on every session
  - validate-push.sh blocks pushes to main, catches secrets, syntax errors
  - validate-edit.sh warns on hardcoded secrets, print(), bare except
    ↓

/create-pr 42  (or manual gh pr create)
    ↓

GitHub Actions: pr-ai-review.yml fires immediately
    ↓
Claude:
  1. Checks "Closes #N" in PR body
  2. Fetches issue #N requirements
  3. Reads full code diff
  4. Checks RAG pipeline integrity (batch sizes, dimensions, idempotency)
  5. Checks Python standards (flake8, types, docstrings, logging)
  6. Compares: does diff address all issue requirements?
    ↓
❌ Rejected → gh pr review --request-changes + label: claude:rejected
              Developer fixes → pushes → Claude re-reviews automatically
✅ Approved → gh pr review --approve + label: claude:approved
              gh pr merge --auto --squash (fires when status checks pass)
    ↓

OWNER QUEUE
  https://github.com/alumnx-ai-labs/agrigpt-backend-common-rag/pulls?q=is%3Aopen+label%3Aclaude%3Aapproved
  Owner spot-checks, confirms, merge completes
```

---

## Daily Developer Workflow

```bash
# Start session → Claude shows context, open PRs, warnings
claude  # session-start hook fires automatically

# Create an issue
/create-issue bug "PDF chunker crashes on empty file"

# Pull latest
/pull-code main

# Make your changes...

# Push with full validation
/push-code "fix: handle empty PDF in chunker"

# Raise PR
/create-pr 42

# Check review status
gh pr view 42

# If rejected, fix and re-push — Claude re-reviews automatically
# If approved — auto-merge fires, done
```

---

## Agents Reference

```bash
# Ask rag-specialist to analyze your chunking code
@"rag-specialist" analyze the current chunking implementation

# Ask pr-reviewer before raising a PR
@"pr-reviewer" review PR 42

# Ask code-standards to check a specific file
@"code-standards" check src/ingestor.py

# Ask issue-validator to check a draft issue
@"issue-validator" validate this: "Bug: chunk_text returns empty list when PDF is scanned image"
```
