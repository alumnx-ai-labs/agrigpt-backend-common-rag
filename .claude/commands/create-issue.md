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
