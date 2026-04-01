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
