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
