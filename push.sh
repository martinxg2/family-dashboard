#!/usr/bin/env bash
# push.sh — one-command stage + commit + push for the family dashboard.
#
# Usage:
#   ./push.sh                        # auto message: "Update YYYY-MM-DD HH:MM"
#   ./push.sh "Fix typo in Caraway"  # custom commit message
#
# Requires: git authenticated for the origin remote (Keychain, gh, or SSH key).

set -euo pipefail

# Always operate from the script's own directory, so it works no matter where it's invoked from.
cd "$(dirname "$0")"

# ----- 1. Clear any stale lock files left by interrupted git operations -----
for lock in .git/index.lock .git/HEAD.lock .git/config.lock; do
  if [ -f "$lock" ]; then
    rm -f "$lock" && echo "Cleared stale $lock"
  fi
done

# ----- 2. Detect whether there's anything to commit -----
HAS_TRACKED_CHANGES=0
HAS_UNTRACKED=0

if ! git diff --quiet || ! git diff --cached --quiet; then
  HAS_TRACKED_CHANGES=1
fi
if [ -n "$(git ls-files --others --exclude-standard)" ]; then
  HAS_UNTRACKED=1
fi

# ----- 3. Stage and commit if there are changes -----
if [ $HAS_TRACKED_CHANGES -eq 1 ] || [ $HAS_UNTRACKED -eq 1 ]; then
  git add -A
  MSG="${1:-Update $(date '+%Y-%m-%d %H:%M')}"
  git commit -m "$MSG"
  echo "Committed: $MSG"
else
  echo "Nothing new to commit."
fi

# ----- 4. Push if anything is ahead of origin -----
git fetch --quiet origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || true
AHEAD=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0)

if [ "$AHEAD" -gt 0 ]; then
  git push
  echo "Pushed $AHEAD commit(s) to origin."
else
  echo "Already up to date with origin."
fi
