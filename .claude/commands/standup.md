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
