#!/usr/bin/env bash
# hb-engage.sh — scaffold a new Huntbuddy engagement folder
# Usage: hb-engage.sh <engagement-name> [target]
set -euo pipefail

NAME="${1:-}"
TARGET="${2:-}"

if [ -z "$NAME" ]; then
  echo "usage: hb-engage.sh <engagement-name> [target]" >&2
  exit 2
fi

BASE="$HOME/huntbuddy/engagements/$NAME"
if [ -e "$BASE" ]; then
  echo "engagements/$NAME already exists" >&2
  exit 1
fi

mkdir -p "$BASE"
cat > "$BASE/README.md" <<EOF
# $NAME

- Created: $(date '+%Y-%m-%d %H:%M')
- Target: ${TARGET:-<not set>}

## Notes
EOF

if [ -n "$TARGET" ]; then
  echo "INITIAL_TARGET=$TARGET" > "$BASE/.env"
fi

echo "engagement ready: ~/huntbuddy/engagements/$NAME"
echo "put notes/findings copies here; run Huntbuddy with:  start"