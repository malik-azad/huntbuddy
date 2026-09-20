#!/usr/bin/env bash
# hb-scope.sh — Huntbuddy target scope guard
# Checks that a target (IP, CIDR, hostname) is inside the allowed scope.
# Scope file: ~/huntbuddy/engagements/.hb-scope (one line per target, CIDR or domain)
# Usage: hb-scope.sh <target> [scope-file]
set -euo pipefail

TARGET="${1:-}"
SCOPE_FILE="${2:-$HOME/huntbuddy/engagements/.hb-scope}"

if [ -z "$TARGET" ]; then
  echo "usage: hb-scope.sh <target> [scope-file]" >&2
  exit 2
fi

if [ ! -f "$SCOPE_FILE" ]; then
  echo "NO SCOPE FILE at $SCOPE_FILE — refusing to auto-approve." >&2
  echo "Add your authorized targets (one per line) to proceed." >&2
  exit 1
fi

in_cidr() {
  # $1 = ip, $2 = cidr  ->  exits 0 if ip is in network
  python3 - "$1" "$2" <<'PY'
import ipaddress, sys
ip = ipaddress.ip_address(sys.argv[1])
try:
    net = ipaddress.ip_network(sys.argv[2], strict=False)
except Exception:
    sys.exit(1)
sys.exit(0 if ip in net else 1)
PY
}

ok=0
while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  case "$entry" in \#*) continue ;; esac
  entry="${entry// /}"
  # exact hostname match or suffix-page match
  if [[ "$entry" == */* ]]; then
    if in_cidr "$TARGET" "$entry"; then ok=1; break; fi
  else
    if [ "$TARGET" = "$entry" ] || [[ "$TARGET" == "$entry" ]] || [[ "$TARGET" == *".$entry" ]]; then
      ok=1; break
    fi
  fi
done < "$SCOPE_FILE"

if [ "$ok" = "1" ]; then
  echo "IN SCOPE: $TARGET"
  exit 0
else
  echo "OUT OF SCOPE: $TARGET (not listed in $SCOPE_FILE)" >&2
  exit 1
fi