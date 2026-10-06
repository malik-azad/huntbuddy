---
description: Interception proxy (burp-mode) — status, start, capture, PoC. Usage: /burp [status|start|stop|capture|poc FILE] or /burp with no args shows proxy status.
---
Run the burp-mode intercept workflow. Default engine is mitmweb (fast, headless, port 127.0.0.1:8080, web UI :8081); Burp Suite GUI is used only when explicitly requested via `/burp start burp`.

- `/burp` — proxy status (hb-proxy.sh status).
- `/burp start` — start mitmweb (fast default) on :8080; tell the user the port + GUI URL.
- `/burp start burp` — launch the installed Burp Suite GUI (Community/Pro) for manual interception, replay, and screenshotting the Repeater window.
- `/burp capture <target-url> <name>` — start a capture session: start proxy, drive Playwright through it, save the recorded flow into the engagement evidence folder (engagements/<active>/evidence/flows).
- `/burp poc <request-file>` — turn a saved raw request into a curl PoC + python PoC + summary and show it.
- `/burp shot <url> <name>` — full-page screenshot via Playwright through the proxy into the engagement evidence shots folder.
- `/burp stop` — stop the proxy.

Then run the exact burp-mode workflow: capture → describe the interesting request → modify & re-forward → replay & verify (verify-proof) → PoC + screenshot into evidence → update engagement state (hb-state.sh).

Respect scope (hb-scope.sh + engagement world). Explain each step in mentor mode unless the user asked for hands-off automation.

$ARGUMENTS