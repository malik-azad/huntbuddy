---
name: burp-mode
description: Human-style web interception workflow for web-app pentesting, bug bounty, CTFs and labs. Uses Burp Suite (Community/Professional) when installed, or mitmproxy as the drop-in GUI-proxy equivalent. Captures, modifies and replays requests; generates reproducable PoCs (curl/python) and screenshots. AUTO-ENGAGES during any web-app/API testing on an authorized web target (engagements with platform/hosts) — start the proxy, capture real traffic as the browser/client runs, and use those real requests for all testing. Triggers - web target engagement, capture a request, intercept, slice, modify request, replay, PoC, proof of concept, proxy on, burp, mitm, manual web testing, reproduce this finding, make a screenshot.
tags: [web, interception, proxy, burp, mitmproxy, poc, evidence]
---

# Burp-Mode — human-style web interception

Think like a manual web tester with a proxy in hand: **capture everything, modify
selectively, replay precisely, prove with evidence.** No guesswork — every finding's
steps can be rerun by a human.

> **Auto-engage rule**: when an engagement/scan has a web or HTTPS target in scope,
> start the proxy automatically before driving the browser/curl so real application
> traffic lands in Burp/mitmweb. You do not wait for the user to type a proxy command —
> you make it happen as part of normal web testing. Keep it lightweight (one engine, one
> capture) and reuse the same running proxy across the session.

## Proxy engine selection (automatic)

`tools/helpers/hb-proxy.sh` picks the best engine on this machine:

1. **Burp Suite GUI** — if installed at `/opt/BurpSuitePro/burpsuite`, `/opt/BurpSuiteCommunity/burpsuite`,
   `~/BurpSuite*`, or `burpsuite` on PATH. Launch it, set the browser/system proxy to `127.0.0.1:8080`,
   intercept ON. The user works the GUI naturally; you guide steps and collect evidence.
2. **mitmproxy (CLI)** — fallback when Burp is absent (this box has it). Same proxy port `127.0.0.1:8080`.
   Start with `mitmweb --listen-port 8080` (web GUI at http://127.0.0.1:8081) so capture/rewrite stays
   visual and reproducible.

Check engine: `tools/helpers/hb-proxy.sh detect`

## Standard workflow (use this order, adapt to the task)

1. **Scope & proxy setup**
   - Confirm authorised target (use engagement world + hb-scope.sh).
   - Ensure proxy engine up: `tools/helpers/hb-proxy.sh start` (starts Burp or mitmweb).
   - Point the browser at the proxy: Playwright `page.route` or `--proxy-server=127.0.0.1:8080`,
     or set `HTTP_PROXY`/`HTTPS_PROXY` for curl/python. For terminal tools:
     `export https_proxy=http://127.0.0.1:8080 http_proxy=http://127.0.0.1:8080`.
2. **Capture (natural browsing)**
   - Drive the browser through the flow that reproduces the behaviour (login, search, upload, fetch).
   - Every request is automatically recorded by the proxy.
3. **Describe, don't blindly paste**
   - Read the intercepted flow. Identify the *interesting* requests by role: which param, what
     header, where the user-supplied value sits, which cookies/CSRF tokens are required.
   - Explaining this selection is part of the skill (mentor mode on teaching).
4. **Modify & re-forward**
   - **Burp:** as the user or in Repeater — pick the request, alter the interesting value, forward.
   - **mitmproxy:** `mitmdump`/`mitmweb` with a small python addon or replay via `curl`.
   - Show the exact before/after. Record both.
5. **Replay & verify**
   - Reproduce with an independent angle (change a value, repeat, benign control) per verify-proof.
   - Evidence goes into the engagement world: `engagements/<name>/evidence/`.
6. **PoC + screenshot**
   - `tools/helpers/hb-proxy.sh poc <raw-request-file>` → writes a runnable `curl` command and a
     `python-requests` script + a summary block (URL, method, headers, body, expected result).
   - Screenshot proof: `tools/helpers/hb-proxy.sh shot "<page-url>" <name>` (Playwright full page)
     or browser DevTools on demand. Save PNG + the flow file.

## Where evidence lives

```
engagements/<name>/evidence/
  flows/        saved raw request/response captures (.req/.res or har)
  poc/          curl + python scripts per finding
  shots/        screenshots (page.png, before.png, after.png)
  findings.md   the verify-proof-confirmed finding entries referencing the above
```

## Assistant behaviour

- **Guided manual mode (default, teaching):** walk the user through intercept→modify→forward one
  step at a time, explaining each. This mirrors how a senior tester replicates findings.
- **Hands-on mode:** you drive Playwright through the proxy yourself, capture, then show the flow
  and produce the PoC — still explain the key choice points.
- **Never proxy-scope-drift:** if the captured traffic leaves authorised scope, call it out and stop.
Minimal automation is used only when it clearly helps; the default is natural, human-reproducible steps.

## Slash-command

`/burp` — shows proxy status, or `/burp capture` starts a capture session into evidence.