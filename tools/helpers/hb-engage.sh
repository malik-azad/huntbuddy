#!/usr/bin/env bash
# hb-engage.sh — scaffold a new Huntbuddy engagement folder (thin alias of hb-state.sh new)
set -euo pipefail

exec "$HOME/huntbuddy/tools/helpers/hb-state.sh" new "$@"
