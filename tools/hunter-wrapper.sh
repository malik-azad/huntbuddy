#!/usr/bin/env bash
# hunter — the Huntbuddy command. One word, one folder, everything else is inside.
# Single source of truth: copied to ~/.local/bin/hunter and embedded by dist/make-dist.sh.
set -euo pipefail

HB_HOME="${HUNTBUDDY_HOME:-${HOME}/huntbuddy}"
OPENCODE_BIN="${HUNTBUDDY_OPENCODE:-$(command -v opencode || true)}"
RUN_TIMEOUT="${HUNTBUDDY_RUN_TIMEOUT:-240}"

err(){ printf 'hunter: %s\n' "$*" >&2; exit 1; }

[ -n "$OPENCODE_BIN" ] || err "engine not found on PATH (install it, or set HUNTBUDDY_OPENCODE)"
[ -d "$HB_HOME" ] || err "folder not found at $HB_HOME"

open_count(){ pgrep -x opencode 2>/dev/null | wc -l | tr -d ' '; }

status() {
  local n relay
  n="$(open_count)"
  printf 'engine : %s (%s)\n' "$OPENCODE_BIN" "$( "${OPENCODE_BIN}" --version 2>/dev/null || printf '?')"
  printf 'folder : %s\n' "$HB_HOME"
  printf 'skills : %s packs\n' "$(find "$HB_HOME/skills" "$HB_HOME/playbooks" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
  printf 'active opencode processes: %s\n' "$n"
  if [ "$n" -ge 1 ]; then
    printf '%s\n' "BUSY: the free relay serves ONE conversation at a time, and it is held by an"
    printf '%s\n' "already-running opencode instance. Close that one (kill its pid) before running"
    printf '%s\n' "hunter, or replies will queue quietly behind it."
    pgrep -ax opencode 2>/dev/null | sed 's/^/  pid /' || true
  else
    printf '%s\n' "clear — no other opencode running; start hunting."
  fi
  relay="$(curl -m 8 -sS -o /dev/null -w '%{http_code}' https://opencode.ai/ 2>/dev/null || printf 'no-response')"
  printf 'relay : HTTP %s\n' "$relay"
}

preflight() {
  if [ "$(open_count)" -ge 1 ]; then
    printf '\033[33mnote: another opencode instance is already running; the free relay serves one\nconversation at a time, so first replies may queue until it closes.\n(hunter status to see it)\033[0m\n'
  fi
}

splash() {
  local A=$'\033[33m' R=$'\033[0m'
  printf '%s\n' "${A}"
  printf '%s\n' "  ██   ██ ██   ██ ███    ██ ████████ ██████   ██████  ██    ██ ██████  ██    ██"
  printf '%s\n' "  ██   ██ ██   ██ ████   ██    ██    ██   ██ ██   ██ ██    ██ ██   ██ ██    ██"
  printf '%s\n' "  ███████ ██   ██ ██ ██  ██    ██    ██   ██ ██   ██ ██    ██ ██   ██ ██   ██ ██    ██"
  printf '%s\n' "  ██   ██ ██   ██ ██  ██ ██    ██    ██   ██ ██   ██ ██    ██ ██   ██ ██    ██"
  printf '%s\n' "  ██   ██  █████  ██   ████    ██    ██████   ██████   ██████  ██████   ██████"
  printf '%s\n' "  AI pentest partner — recon to report · free opencode Zen brain"
  printf '%s\n' "  hunter --help  ·  hunter <message>  ·  hunter run \"goal\"  ·  hunter status"
  printf '%s%s\n' "${R}" ""
}

whoami_text() {
  cat <<'IDENTITYEOF'
I'm Hunter — your agentic AI pentest buddy.

Name   : Hunter (brand: Huntbuddy)  — the AI partner, not the folder, not the tool.
Job    : map the target, enumerate, assess, exploit, verify, and report — inside
         authorised scope, mentor-style, with a concrete Next step every reply.
Engine : a local opencode install keeps me autonomous and scripted.
Brain  : free OpenCode Zen model by default (no keys; switch anytime with /models).
Config : ~/huntbuddy/opencode.jsonc · docs: ~/huntbuddy/docs/Huntbuddy-Guide.pdf
IDENTITYEOF
}

usage() {
  cat <<'USAGEEOF'
hunter — Huntbuddy, an AI pentest partner (runs on the opencode engine inside ~/huntbuddy).

Usage:
  hunter                                     start the interactive chat (TUI)
  hunter --help | -h | help                  this help
  hunter --version | -v                       engine version
  hunter status                               check relay slot, opencode procs, skills
  hunter whoami                               who Hunter is (identity card)
  hunter "<message>"                         run a one-off message   (e.g. hunter "what planes?")
  hunter run "<message>"                      same, explicit; times out (default 240s) instead of hanging
  hunter auth                                 manage AI providers & login
  hunter models [provider]                    list available models
  hunter skills                               list loaded skill packs
  hunter debug config                         show resolved configuration
  hunter session|stats|export|import|mcp|upgrade   engine utilities

Free-relay note: the zen free service serves one conversation at a time per
machine. If replies go quiet, run `hunter status`; close any other opencode
instance, then rerun. Env: HUNTBUDDY_HOME, HUNTBUDDY_BIN, HUNTBUDDY_OPENCODE,
HUNTBUDDY_RUN_TIMEOUT. Config: ~/huntbuddy/opencode.jsonc.
USAGEEOF
}

case "${1:-}" in
  "")
    preflight
    splash
    cd "$HB_HOME"
    exec "$OPENCODE_BIN"
    ;;
  --help|-h|help)
    usage
    ;;
  --version|-v)
    exec "$OPENCODE_BIN" --version
    ;;
  status)
    status
    ;;
  whoami|identity)
    whoami_text
    ;;
  run)
    shift
    cd "$HB_HOME"
    timeout "$RUN_TIMEOUT" "$OPENCODE_BIN" run "$@"
    rc=$?
    if [ "$rc" -eq 124 ]; then
      printf '%s\n' "hunter: timed out after ${RUN_TIMEOUT}s waiting for a relay token." >&2
      printf '%s\n' "The free relay serves one conversation at a time — run 'hunter status'," >&2
      printf '%s\n' "close any other opencode instance, then try again." >&2
      exit 1
    fi
    exit "$rc"
    ;;
  auth|models|skills|debug|mcp|upgrade|uninstall|session|stats|export|import|serve|attach)
    cmd="$1"; shift
    cd "$HB_HOME"
    exec "$OPENCODE_BIN" "$cmd" "$@"
    ;;
  *)
    cd "$HB_HOME"
    exec "$OPENCODE_BIN" "$@"
    ;;
esac
