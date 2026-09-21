---
name: playwright
description: Browser automation primitive using Playwright. Launches a visible Chromium you control, runs approved scripts for navigation, extraction, form submission, and screenshots. No credential storage — you log in manually once per session.
tags: [automation, browser, recon, lab]
---

# Playwright Browser Automation

This skill gives you a **visible, user-controlled browser** for any web task. It does NOT store credentials, cookies, or sessions. You log in manually in the opened window; then Hunter can run scripts you approve.

## Prerequisites (auto-installed on first use)
- Node.js + npm
- Playwright (`npm i -g playwright`)
- Chromium (`npx playwright install chromium`)

## Core Functions (call via Python/Playwright)

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=False, args=["--start-maximized"])
    page = browser.new_page()

    # Navigation
    page.goto("https://target.com", wait_until="networkidle")
    page.wait_for_load_state("domcontentloaded")

    # Extraction
    text = page.locator("selector").inner_text()
    html = page.content()
    links = page.eval_on_selector_all("a", "els => els.map(e => e.href)")

    # Interaction
    page.fill("input[name='username']", "your_user")
    page.fill("input[name='password']", "your_pass")
    page.click("button[type='submit']")
    page.wait_for_url("**/dashboard**")

    # Forms / Flags
    page.fill("#flag-input", "flag{...}")
    page.click("#submit-btn")

    # Screenshots / Evidence
    page.screenshot(path="evidence.png", full_page=True)

    # Arbitrary JS in page context
    result = page.evaluate("() => document.querySelector('.flag').innerText")

    browser.close()
```

## Usage Rules
1. **Never auto-login** — user logs in manually in the visible browser.
2. **One action per approval** — Hunter proposes a script, user confirms, then it runs.
3. **No persistent state** — browser closes after each script; cookies die with it.
4. **Teach mode** — when user asks "teach me", explain the selector logic, why that wait, what the JS does.

## Triggers
- User says "open browser", "automate this page", "submit flag via browser", "scrape this"
- Lab tasks requiring web interaction (THM, HTB, CTFd, custom portals)
- Any task where `curl` isn't enough (JS-heavy, CSP, complex forms)

## Integration
- Works with `lab-parser` skill for task-driven automation
- Feeds `lab-parser` extracted data back for analysis
- `/submit` command uses this for flag/form posting