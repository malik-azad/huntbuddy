#!/usr/bin/env bash
# hb-scope.sh — Huntbuddy target scope guard
# Checks that a target (IP, CIDR, hostname) is inside the allowed scope.
# Scope file: ~/huntbuddy/engagements/.hb-scope (one line per target, CIDR or domain)
# Usage: hb-scope.sh <target> [scope-file]
set -euo pipefail

TARGET="${1:-}"
HB_R="${HUNTBUDDY_HOME:-$HOME/huntbuddy}"
ACTIVE="$HB_R/engagements/.active"
DEFAULT_SCOPE=""
if [ -f "$ACTIVE" ]; then
  A="$(tr -d '[:space:]' < "$ACTIVE")"
  [ -n "$A" ] && DEFAULT_SCOPE="$HB_R/engagements/$A/.hb-scope"
fi
SCOPE_FILE="${2:-$DEFAULT_SCOPE}"

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
  # $1 = ip, $2 = cidr  ->  exits 0 if ip is in network (non-IP target => out)
  python3 - "$1" "$2" <<'PY'
import ipaddress, sys
try:
    ip = ipaddress.ip_address(sys.argv[1])
    net = ipaddress.ip_network(sys.argv[2], strict=False)
except Exception:
    sys.exit(1)
sys.exit(0 if ip in net else 1)
PY
}

is_cidr() { [[ "$1" == */* ]] && [[ "$1" =~ ^[0-9a-fA-F:.]+/[0-9]+$ ]]; }
strip() { s="${1#"${1%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; s="${s#*://}"; s="${s%%/*}"; case "$s" in *:*[0-9]) s="${s%:*}" ;; esac; printf '%s' "$s"; }

ok=0
while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  case "$entry" in \#*) continue ;; esac
  entry="${entry//[[:space:]]/}"
  if is_cidr "$entry"; then
    if in_cidr "$TARGET" "$entry"; then ok=1; break; fi
  else
    e="$(strip "$entry")"; t="$(strip "$TARGET")"
    if [ -n "$t" ] && { [ "$t" = "$e" ] || [ "$t" = "www.$e" ] || [[ "$t" == *".$e" ]]; }; then
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