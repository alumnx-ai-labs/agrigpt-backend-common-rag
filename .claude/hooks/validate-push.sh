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
