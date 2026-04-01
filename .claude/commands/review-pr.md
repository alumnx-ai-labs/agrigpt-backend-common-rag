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
