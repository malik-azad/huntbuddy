#!/usr/bin/env bash
# Huntbuddy bootstrap — full setup from a single line.
# Clones the repo (if needed), checks for the opencode engine and installs it
# only when missing, links the `hunter` command, then verifies everything.
# Nothing else is downloaded or kept; this machine stays clean.
set -euo pipefail

HB_REPO="https://github.com/malik-azad/huntbuddy.git"
HB_HOME="${HUNTBUDDY_HOME:-${HOME}/huntbuddy}"
HB_BIN="${HUNTBUDDY_BIN:-${HOME}/.local/bin}"

ok()   { printf '\033[1;32m%s\033[0m\n' "$*"; }
note() { printf '\033[1;33m%s\033[0m\n' "$*"; }

# 1 · Get the folder -----------------------------------------------------------
if [ -f "$HB_HOME/opencode.jsonc" ] && [ -f "$HB_HOME/HUNTBUDDY.md" ]; then
  note "huntbuddy folder already present at $HB_HOME — updating it"
  command git -C "$HB_HOME" pull --ff-only --quiet 2>/dev/null || note "  (no git history here — left as-is)"
else
  note "cloning huntbuddy …"
  if [ -e "$HB_HOME" ]; then
    note "moving existing $HB_HOME to ${HB_HOME}.backup-$(date +%s)"
    mv "$HB_HOME" "${HB_HOME}.backup-$(date +%s)"
  fi
  command git clone --quiet --depth 1 "$HB_REPO" "$HB_HOME"
fi

# 2 · Engine (install only if missing) -----------------------------------------
OPENCODE_BIN="${HUNTBUDDY_OPENCODE:-}"
if [ -z "$OPENCODE_BIN" ] && command -v opencode >/dev/null 2>&1; then
  OPENCODE_BIN="$(command -v opencode)"
fi
if [ -z "$OPENCODE_BIN" ] && [ -x "$HOME/.opencode/bin/opencode" ]; then
  OPENCODE_BIN="$HOME/.opencode/bin/opencode"
fi
if [ -z "$OPENCODE_BIN" ]; then
  note "opencode engine not found — installing the official build"
  command curl -fsSL https://opencode.ai/install | bash
  OPENCODE_BIN="$HOME/.opencode/bin/opencode"
fi
[ -x "$OPENCODE_BIN" ] || { printf 'hunter: engine missing at %s\n' "$OPENCODE_BIN" >&2; exit 1; }
ok "engine ready: $("$OPENCODE_BIN" --version 2>/dev/null || printf '?')"

# 3 · The hunter command ----------------------------------------------------
mkdir -p "$HB_BIN"
ln -sfn "$HB_HOME/tools/hunter-wrapper.sh" "$HB_BIN/hunter"
ok "hunter linked at $HB_BIN/hunter"

# 4 · Sanity check -------------------------------------------------------------
"$HB_BIN/hunter" --version >/dev/null
ok "setup complete — run:   hunter"
command -v opencode >/dev/null 2>&1 || \
  note "tip: add \$HOME/.opencode/bin to PATH or reopen your terminal to reach the engine."