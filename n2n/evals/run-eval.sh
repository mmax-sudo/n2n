#!/bin/bash
# N2N Eval Runner — applies bug patches and provides prompts for manual testing
#
# Usage:
#   ./run-eval.sh <eval-id>       Apply patch and print the n2n prompt
#   ./run-eval.sh --restore       Restore all patched files via git checkout
#   ./run-eval.sh --list          List all available evals
#
# Configuration:
#   Set N2N_PROJECT_DIR to your project root, or run from within a git repo.
#
# Flow:
#   1. ./run-eval.sh n2n-bugfix-02   → applies patch, prints prompt to paste
#   2. Paste the prompt into Claude Code → n2n runs autonomously
#   3. Grade the transcript against expectations in evals.json
#   4. ./run-eval.sh --restore        → git checkout restores original files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVALS_JSON="$SCRIPT_DIR/evals.json"
PROJECT_DIR="${N2N_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <eval-id> | --restore | --list${NC}"
  echo -e "Project dir: ${BLUE}$PROJECT_DIR${NC}"
  echo -e "Set N2N_PROJECT_DIR to override."
  exit 1
fi

# Check if evals array is empty
EVAL_COUNT=$(jq '.evals | length' "$EVALS_JSON")
if [[ "$EVAL_COUNT" -eq 0 && "$1" != "--list" ]]; then
  echo -e "${YELLOW}No evals defined yet.${NC}"
  echo -e "Add evals to ${BLUE}evals.json${NC} and create patch files in ${BLUE}patches/${NC}."
  echo -e "See ${BLUE}patches/README.md${NC} for the format."
  exit 0
fi

# --list: show all evals
if [[ "$1" == "--list" ]]; then
  if [[ "$EVAL_COUNT" -eq 0 ]]; then
    echo -e "${YELLOW}No evals defined yet.${NC}"
    echo -e "See patches/README.md for how to create them."
  else
    echo -e "${BLUE}Available evals:${NC}"
    jq -r '.evals[] | "  \(.id)  —  \(.name)  [\(.bug_type)]"' "$EVALS_JSON"
  fi
  exit 0
fi

# --restore: git checkout all patched files
if [[ "$1" == "--restore" ]]; then
  echo -e "${YELLOW}Restoring all patched files...${NC}"
  for file in $(jq -r '.evals[].target_file' "$EVALS_JSON"); do
    full_path="$PROJECT_DIR/$file"
    if [[ -f "$full_path" ]]; then
      cd "$PROJECT_DIR" && git checkout -- "$file" 2>/dev/null && \
        echo -e "  ${GREEN}✓${NC} Restored $file" || \
        echo -e "  ${RED}✗${NC} Failed to restore $file (not in git?)"
    fi
  done
  echo -e "${GREEN}Done.${NC}"
  exit 0
fi

# Apply a specific eval patch
EVAL_ID="$1"
EVAL=$(jq -r --arg id "$EVAL_ID" '.evals[] | select(.id == $id)' "$EVALS_JSON")

if [[ -z "$EVAL" || "$EVAL" == "null" ]]; then
  echo -e "${RED}Error: eval '$EVAL_ID' not found.${NC}"
  echo "Available evals:"
  jq -r '.evals[].id' "$EVALS_JSON"
  exit 1
fi

PATCH_FILE="$SCRIPT_DIR/$(echo "$EVAL" | jq -r '.patch')"
TARGET_FILE=$(echo "$EVAL" | jq -r '.target_file')
PROMPT=$(echo "$EVAL" | jq -r '.prompt')
NAME=$(echo "$EVAL" | jq -r '.name')
BUG_TYPE=$(echo "$EVAL" | jq -r '.bug_type')

if [[ ! -f "$PATCH_FILE" ]]; then
  echo -e "${RED}Error: patch file not found: $PATCH_FILE${NC}"
  exit 1
fi

FULL_TARGET="$PROJECT_DIR/$TARGET_FILE"
if [[ ! -f "$FULL_TARGET" ]]; then
  echo -e "${RED}Error: target file not found: $FULL_TARGET${NC}"
  exit 1
fi

# Apply the patch using Node.js (handles special chars reliably via JSON)
node -e "
  const fs = require('fs');
  const patch = JSON.parse(fs.readFileSync('$PATCH_FILE', 'utf8'));
  const content = fs.readFileSync('$FULL_TARGET', 'utf8');
  if (!content.includes(patch.find)) {
    console.error('Error: find string not found in file. Already patched or code changed.');
    process.exit(1);
  }
  fs.writeFileSync('$FULL_TARGET', content.replace(patch.find, patch.replace));
"

echo ""
echo -e "${GREEN}━━━ Eval: $NAME [$BUG_TYPE] ━━━${NC}"
echo -e "${GREEN}✓ Patch applied to $TARGET_FILE${NC}"
echo -e "Project: ${BLUE}$PROJECT_DIR${NC}"
echo ""
echo -e "${BLUE}Paste this prompt into Claude Code:${NC}"
echo ""
echo -e "${YELLOW}$PROMPT${NC}"
echo ""
echo -e "${BLUE}After the run, grade against expectations:${NC}"
echo "$EVAL" | jq -r '.expectations[]' | while read -r exp; do
  echo -e "  □ $exp"
done
echo ""
echo -e "When done: ${YELLOW}./run-eval.sh --restore${NC}"
