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

ghost_count(){
  # leftover hunter/opencode run wrappers still parked (from earlier blocked runs).
  # Patterns are anchored to real binary paths so they never match our own shell.
  local hb="${HB_HOME%/*}/.local/bin/hunter"
  # pgrep returns 1 when no matches; with pipefail this would kill the script.
  # Use a subshell with || true to swallow the non-zero exit.
  ( pgrep -af "${hb} run|\.local/bin/hunter run|\.opencode/bin/opencode run|timeout [0-9]* .*\.opencode/bin/opencode run" 2>/dev/null \
    | grep -v 'pgrep' | wc -l | tr -d ' ' ) || echo 0
}

engage_card() {
  local a="$HB_HOME/engagements/.active" nm
  if [ -f "$a" ]; then
    nm="$(cat "$a")"
    printf 'engagement : %s\n' "$nm"
    "$HB_HOME/tools/helpers/hb-state.sh" get "$nm" 2>/dev/null | sed 's/^/  /' || true
  else
    printf 'engagement : none active — open one: hunter engage <name> [target...]\n'
  fi
}

status() {
  local n relay
  n="$(open_count)"
  printf 'engine : %s (%s)\n' "$OPENCODE_BIN" "$( "${OPENCODE_BIN}" --version 2>/dev/null || printf '?')"
  printf 'folder : %s\n' "$HB_HOME"
  engage_card
  printf 'skills : %s packs\n' "$(find "$HB_HOME/skills" "$HB_HOME/playbooks" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
  printf 'active opencode processes: %s\n' "$n"
  if [ "$n" -ge 1 ]; then
    printf '%s\n' "BUSY: the free relay serves ONE conversation at a time, and it is held by an"
    printf '%s\n' "already-running opencode instance. Close that one (kill its pid) before running"
    printf '%s\n' "hunter, or replies will queue quietly behind it."
    pgrep -ax opencode 2>/dev/null | sed 's/^/  pid /' || true
  else
    printf '%s\n' "clear — no other opencode running; start hunting."
    if [ "$(ghost_count)" -ge 1 ]; then
      printf '\033[33mnote: leftover hunter/opencode 'run' processes are parked on this machine\n(they wait forever behind a held slot). Run 'hunter clear' to reap them.\033[0m\n'
    fi
  fi
  relay="$(curl -m 8 -sS -o /dev/null -w '%{http_code}' https://opencode.ai/ 2>/dev/null || printf 'no-response')"
  printf 'relay : HTTP %s\n' "$relay"
}

clear_ghosts() {
  printf '%s\n' "hunter clear: freeing the relay slot..."
  printf '%s\n' " closes any other opencode instance and parked 'hunter run' / 'opencode run' leftovers."
  if [ -t 0 ]; then
    printf '%s' 'really close them all? [y/N] ' >&2
    read -r ans
    case "$ans" in y|Y|yes|YES) ;; *) echo "aborted."; exit 1 ;; esac
  fi
  pkill -9 -x opencode 2>/dev/null || true
  pkill -9 -f '\.local/bin/hunter run' 2>/dev/null || true
  pkill -9 -f '\.opencode/bin/opencode run' 2>/dev/null || true
  sleep 1
  local n; n="$(open_count)"
  if [ "$n" -eq 0 ]; then
    printf '%s\n' "done. relay is free (hunter status to confirm)."
  else
    printf '%s\n' "done — but ${n} opencode process still shows; run 'hunter status' to see which."
  fi
}

preflight() {
  if [ "$(open_count)" -ge 1 ]; then
    printf '\033[33mnote: another opencode instance is already running; the free relay serves one\nconversation at a time, so first replies may queue until it closes.\n(hunter status to see it)\033[0m\n'
    if [ -t 0 ]; then
      printf '%s' 'open anyway? [y/N] ' >&2
      read -r ans
      case "$ans" in
        y|Y|yes|YES) ;;
        *) printf 'exiting. close the other session first, then run hunter again (hunter status shows it).\n' >&2; exit 2 ;;
      esac
    fi
  fi
}

splash() {
  local A=$'\033[33m' R=$'\033[0m' G=$'\033[38;5;46m' W=$'\033[38;5;255m'
  printf '%s\n' \
    "${G}██   ██   ██    ██   ███    ██   ████████     ${W}███████   ██████${R}" \
    "${G}██   ██   ██    ██   ████   ██      ██${W}    ██        ██   ██${R}" \
    "${G}███████   ██    ██   ██ ██  ██      ██${W}    █████     ██████${R}" \
    "${G}██   ██   ██    ██   ██  ██ ██      ██${W}    ██        ██   ██${R}" \
    "${G}██   ██    ██████    ██   ████      ██${W}    ███████   ██   ██${R}"
  printf '%s\n' "  AI pentest partner — recon to report · free opencode Zen brain"
  printf '%s\n' "  hunter --help  ·  hunter <message>  ·  hunter run \"goal\"  ·  hunter status"
  printf '%s%s\n' "${A}${R}" ""
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
  hunter status                               check relay slot, opencode procs, skills, active engagement
  hunter whoami                               who Hunter is (identity card)
  hunter engage <name> [target...]            open a new ISOLATED engagement world (state.json)
  hunter "<message>"                         run a one-off message   (e.g. hunter "what planes?")
  hunter run ["--force"] "<message>"         one-off; fails fast if the slot is busy (or --force to wait)
  hunter clear                               free the relay slot (close other opencode + parked runs)
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
    printf '\033]0;huntbuddy — hunter\007'
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
  engage)
    shift
    exec "$HB_HOME/tools/helpers/hb-state.sh" new "$@"
    ;;
  run)
    shift
    force=0
    [ "${1:-}" = "--force" ] && { force=1; shift; }
    if [ "$force" -eq 0 ] && [ "$(open_count)" -ge 1 ]; then
      printf '%s\n' "hunter: another opencode conversation is holding the relay slot (one at a time)." >&2
      printf '%s\n' "close it first — 'hunter clear' frees everything — or run: hunter run --force \"...\"" >&2
      exit 1
    fi
    cd "$HB_HOME"
    timeout "$RUN_TIMEOUT" "$OPENCODE_BIN" run "$@"
    rc=$?
    if [ "$rc" -eq 124 ]; then
      printf '%s\n' "hunter: timed out after ${RUN_TIMEOUT}s waiting for a relay token." >&2
      printf '%s\n' "The free relay serves one conversation at a time — run 'hunter status'," >&2
      printf '%s\n' "check for BUSY/leftover processes, 'hunter clear' if needed, then try again." >&2
      exit 1
    fi
    exit "$rc"
    ;;
  clear)
    clear_ghosts
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
