#!/usr/bin/env bash
# hb-playwright.sh — ensure Playwright + a usable Chromium are available.
# Detects the self-contained Python Playwright (user-site) + system Chromium.
set -euo pipefail

CHROME=""
for c in /usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome; do
  [ -x "$c" ] && CHROME="$c" && break
done

if python3 -c "import playwright.sync_api" >/dev/null 2>&1; then
  if [ -n "$CHROME" ]; then
    echo "Playwright: OK (python) · Chromium: $CHROME"
    echo "hint: use executable_path=\"$CHROME\" when launching; no browser download needed."
    exit 0
  fi
  echo "Playwright: OK (python) · Chromium: bundled/download needed (run: python3 -m playwright install chromium)"
  exit 1
fi

cat <<'MSG'
Playwright not ready. Either:
  - pip3 install --user --break-system-packages playwright   (self-contained, no sudo)
  - or apt: sudo apt install -y python3-playwright node-playwright chromium
MSG
exit 1