#!/usr/bin/env bash
# hb-playwright.sh — ensure Playwright + Chromium are installed, or guide install.
set -euo pipefail

if command -v npx >/dev/null 2>&1 && npx playwright --version >/dev/null 2>&1; then
  if npx playwright install --dry-run chromium 2>&1 | grep -q "already installed"; then
    echo "Playwright + Chromium: OK"
    exit 0
  fi
fi

cat <<'MSG'
Playwright not fully ready. One-time setup:

  # Install Node.js if missing (Kali: apt install nodejs npm)
  # Then:
  npm install -g playwright
  npx playwright install chromium

After that, run: hunter "test playwright"  (or any task needing browser)
MSG
exit 1