#!/usr/bin/env bash
# Huntbuddy launcher — convenience menu. The real command is `hunter`.
set -euo pipefail

HUNTER="$HOME/.local/bin/hunter"
HB_DIR="$HOME/huntbuddy"

if ! command -v opencode >/dev/null 2>&1; then
  echo "opencode engine not found on PATH — run:  curl -fsSL https://opencode.ai/install | bash" >&2
  exit 1
fi

menu() {
  cat <<'EOF'

  ┌─────────────────────────────────────────────┐
  │                 HUNTBUDDY                    │
  │  AI pentest partner — recon to report        │
  │  (from any shell, type:  hunter)             │
  └─────────────────────────────────────────────┘
   1)  Interactive chat (new session)
   2)  Resume a previous session
   3)  One-shot: give a target & task
   4)  List sessions / engagements
   5)  View latest findings (findings.md)
   6)  Verify findings (false-positive sweep)
   7)  Skills & docs
   8)  Update engine
   9)  Exit
EOF
}

while true; do
  menu
  read -r -p "  Choice [1-9]: " choice
  case "$choice" in
    1)
      echo "-> Starting Huntbuddy. Describe your target and goal when asked."
      echo "   Example: 'pentest 10.10.10.5, goal is root'"
      "$HUNTER"
      ;;
    2)
      echo "-> Opening Huntbuddy — pick the session you want from the session list."
      "$HUNTER"
      ;;
    3)
      read -r -p "  Target + task (e.g. 'scan 10.10.10.0/24 and enumerate'): " task
      if [ -n "$task" ]; then
        "$HUNTER" run "$task"
      fi
      ;;
    4)
      "$HUNTER" session list
      echo "-- engagements --"
      ls -1 "$HB_DIR/engagements" 2>/dev/null | grep -v '^\.' || true
      ;;
    5)
      latest="$(ls -t "$HB_DIR/engagements"/*/findings.md 2>/dev/null | head -1)"
      if [ -n "${latest:-}" ]; then
        less "$latest"
      else
        echo "No findings.md yet. Start an engagement first."
      fi
      ;;
    6)
      echo "-> Opening Huntbuddy for a verification pass. Type: /verify"
      "$HUNTER"
      ;;
    7)
      "$HUNTER" skills list
      ;;
    8)
      echo "-> Updating the engine..."
      "$HUNTER" upgrade
      ;;
    9)
      echo "Good hunting."
      exit 0
      ;;
    *) echo "  Invalid choice." ;;
  esac
done