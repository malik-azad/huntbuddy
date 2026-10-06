---
name: bugbounty-web-api
description: Bug-bounty methodology for web apps/APIs - attack surface mapping, bug classes (IDOR, auth, injection, SSRF, upload, JWT, business logic), impact-first triage, accepted reports. Triggers - web program, bug bounty, API testing, IDOR, JWT.
tags: [recon, engineering, webapp]
---

# Bug Bounty Web/API Hunting

Bounties reward real impact, verified and clearly written. Be systematic and loud on recon, quiet on exploitation.

## 1. Asset discovery (recon first, always)
- Enumerate: `amass enum -passive -d <domain>`, `subfinder`, `assetfinder`, certificate transparency (`crt.sh`), passive DNS, GitHub/Google dorks for leaks, JS files for API keys & endpoints.
- De-duplicate live hosts, fingerprint `whatweb`, look for dev/staging/test subdomains (dev., stg., uat., api.-pre), and shadow VHosts.
- Pro tip: JS bundles (`/static/js/*.js`) are the modern treasure map — endpoints, API routes, hidden IDs, hardcoded secrets.

## 2. Attack-surface triage (input + trust)
Catalog every input the app accepts:
- URL params, bodies (JSON/XML/x-www-form-urlencoded), headers, cookies, tokens, And upload + callback endpoints.
- Identify auth model: JWT/OAuth/session cookies — decode the token (`jwt_analyze`), test `alg:none`, weak secrets, expiry, audience confusion.
- Every endpoint that references an object id (numeric, UUID, email) is an **IDOR candidate**: test by swapping the id across accounts/roles; capture two-account proof.
- Test the whole matrix with an app-aware scanner: `ffuf` fuzzing, `burp`-style flows (nuclei with template tags), sqlmap for SQL-ish params, and manual probes for business-logic gaps that scanners miss.

## 3. High-signal bug classes (check in order)
1. **Access control (IDOR / priv-esc)** — usually the highest bounty-per-effort. Same request, different id/role, or missing check on an admin-only endpoint.
2. **Injection** — SQLi (sqlmap), SSTI ({{7*7}}), XSS (reflected/stored via `xss_detect`), command injection (blind/ping/time).
3. **SSRF** — anything that fetches a URL (imports, previews, webhooks, images). Prove internal reach: hit `http://169.254.169.254/latest/meta-data/` on cloud, or loopback admin.
4. **File upload** → stored XSS/webshell (polyglot, extension bypass, double-encoding, path traversal in name).
5. **JWT / auth flaws** — via `jwt_analyze`, weak signing, alg confusion, user-property trust.
6. **Deserialization** — Java/OAS PHP/Python .NET magic cookies/viewstate.
7. **Business logic** — price/session/rate abuse, OTP bypass, missing rate limiting, race conditions (`turbo-intruder`, double-spend test in a sandbox account).
8. **Information disclosure** — debug endpoints, verbose errors, backup files, `.git/`, S3 buckets, API keys in JS.

## 4. Impact-first triage
- Prove REAL impact or don't report: e.g., for IDOR you need (a) two different accounts, (b) unauthorized resource accessed, (c) sensitive data exposed.
- Score severity honestly (P1/P2/P3) by business impact — data leaked, auth bypass, RCE. Check the program's scope/exclusions first.
- Duplicate-configs are fine; verified, well-explained unique bugs win.

## 5. The bounty report template (program-friendly)
- Title: `<Type> on <endpoint>` (e.g., "IDOR on /api/orders/{id} leaks other users' order data").
- Summary, Steps to Reproduce (numbered, copy-paste requests with full headers), Impact, Remediation suggestion. Keep proof short and clear.
- Use the bundled reporting knowledge + `verify-proof` before submitting.