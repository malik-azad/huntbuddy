---
name: web-misc-common
description: High-value web vuln classes WITHOUT dedicated deep packs — auto-load ANY web engagement to test + know under: CSRF, open redirect, CORS misconfig, host-header injection, HTTP request smuggling, cache poisoning, business-logic/race conditions, weak crypto (JWT/TLS/random), clickjacking, security-header gaps, mass-assignment, subdomain takeovers, HTTP verb tampering, GraphQL (introspection/IDOR/batching/mutations), WebSockets (authz/origin/channel). Triggers - any web target (router loads this alongside the class-specific skill), "check CSRF", "test redirect", "CORS", "host header", "smuggling", "cache", "race condition", "business logic", "JWT", "clickjacking", headers, takeover, graphql, /graphql, websocket, ws://, "what else to test".
tags: [vuln_assess, exploitation]
---

# Web "misc-but-common" — the high-value classes that don't get a deep pack

Auto-loaded on EVERY web engagement alongside the specific class skill. Use the checklist; each item has a fast signal, a fast test, and a proof. Don't skip.

## 1. CSRF (broken function-level control)
Signal: state-changing endpoint (POST change-email/password/order) with no anti-CSRF token, no SameSite, no origin check.
Test: craft a self-submitting form PoC; ensure it fires on another session (prove a victim-side action).
```html
<form action="https://t/change-email" method=POST><input name=email value=a@poc></form><script>document.forms[0].submit()</script>
```
Proof: victim-session field changed / action performed cross-origin.

## 2. Weak crypto (JWT + TLS + randomness)
- **JWT**: `alg:none` → strip sig; HS256 with public key as secret (`RS256`→`HS256` confusion); weak/guessable secret (`hashcat -m 16500`); missing exp/nbf; kid header path traversal; JWKS confusion. Verify signature change reflects server-side.
- **TLS**: weak ciphers, expired/self-signed on prod, POODLE/BEAST-era cipher, cert CT transparency mismatch — reporting-grade only.
- **Random/tokens**: predictable reset tokens/IDs (time/NN-seeded) — read two tokens, guess a third for an account you own.
Proof: forged JWT accepted; guessed reset token lands in your mailbox for the target account.

## 3. Open redirect
Signal: `?next=`, `?redirect=`, `?url=`, `?return=` echo a URL.
Test/PoC: `https://t/redir?url=//evil.com` and `/\evil.com`; prove a real 3xx Location to attacker domain; pair with OAuth/callback flows for token leak chain.

## 4. CORS misconfig
Signal: ACAO=null / reflects Origin / `Access-Control-Allow-Credentials:true` + wildcard / bad regex prefix match.
Proof: fetch from an attacker origin reads a credentialed authenticated response (`readme` of an object you own that requires cookie) → screen cap of cross-origin read as that user.

## 5. Host-header injection
Signal: app reflects or routes cache/redirect/URL-rewrite off the Host header.
Test: `curl -H "Host: evil.com"` → 302 to evil.com, password-reset link poisoning, cache-keyed to victim host. Proof: a reset link/URL rewrite lands at attacker domain for that host.

## 6. HTTP request smuggling (CL.TE / TE.CL / TE.TE)
Signal: front-end (CDN/nginx) + backend pair; old stack telegraphs via timeouts.
Fast confirm: `CL.TE` with a smuggled second request → backend responds for a poisoned next request; use `h2c` / `H2.CL` on HTTP/2 front-ends. Proof: front-end cache poisoned to serve attacker content, or a smuggled request deletes a victim's object.

## 7. Cache poisoning (web cache + unkeyed inputs)
Signal: page cached, and a header/param you feed (X-Forwarded-Host, cookie, `?cb=`) is reflected but NOT part of the cache key.
Test: poison with `X-Forwarded-Host: evil` then fetch the URL unauthenticated from a fresh IP → attacker-controlled cached page. Proof: victim-fetch returns poisoned content (screenshot through the same cache as a "victim" clean request).

## 8. Business-logic / race / mass-assignment
- **Privesc/broken logic**: negative/overflow quantities, price/role/promotion end-run, multiple-use coupons, step-skip (checkout without payment), state-machine hole.
- **Race condition**: double-submit a single-use thing (recovery token, coupon, withdrawal) — send N parallel (Turbo Intruder) and see >1 accepted. Proof: 2 accepted uses of a once-per-token resource.
- **Mass-assignment**: add unexpected fields in JSON (`"role":"admin"`, `"isAdmin":true`, `"verified":true`) in request body → accepted and persisted. Proof: the extra field persists server-side.

## 9. Clickjacking + frame-busting gaps
Signal: no `frame-ancestors`/`X-Frame-Options`, and a page confirms state-change actions.
Proof: 3-line HTML iframe PoC proving the action page renders framed in your attacker page.

## 10. Security-header gaps (reporting/defense-in-depth)
Missing ST/HPKP-descendants, `Content-Security-Policy`, `Referrer-Policy`, HSTS, `Permissions-Policy`, basic auth over HTTPS. Map via `securityheaders`/headers — report as LOW/config unless paired with a real bypass (proven CSP bypass = mid).

## 11. Subdomain takeover + dangling DNS
Signal: NXDOMAIN/error page for a CNAME pointing at a dead provider (heroku/S3/GHB/Azure).
Check: `subjack`/`nuclei -tags takeover`; register proof → serve EICAR/flag → shows fully-controllable. Proof: elected page live under target subdomain.

## 12. HTTP verb / method tampering & parameter pollution
- Map allowed methods (`OPTIONS`/`TRACE`); TRACE=reflected = LOW (fix: disable); GET vs DELETE/DELETE on a state-change-only route.
- HPP: `?role=user&role=admin` server picks last/first; use when first-wins/last-wins differs → bypass filter.

## Proof discipline
Every class above earns `confirmed` ONLY with a concrete artifact (cross-origin state change, forged token accepted, poisoned cached page, second acceptance, persisted field, framed page, takeover page). No influence-only = `low`/informational, never confirmed. Others auto-mapped to `REPORTING` with the engagement find artifact.

## 13. GraphQL (modern APIs — high value)
Signal: `/graphql`, `graphql` route, `__typename` echoes in responses.
- Introspect first: `{__schema{types{name fields{name args{name type{name}}}}}}` → dump types/mutations. Deep-scan exposed objects.
- **IDOR via nested/alias queries**: `{user(id:1){email} a:user(id:2){email}}` — batch field aliases prove cross-user read in one request.
- **Batching to bypass rate-limit/bruteforce**: `mutation{{login(user:"u",pass:"a"){token} ... }}` many aliases → token spray in one HTTP call.
- **Mutation abuse**: enable-payment/role-change/credit-move mutation reachable without authz.
- **Error leak & `null` vs error**: introspection on/off; error messages enum/trace. Over-fetch redacted field (`password`/`secret` nulled vs absent) = leak signal.
- **Potential attacks**: depth/alias DoS, batch smash, fragment bombs — report as resource-exhaustion if it provably multiplies load.
Proof: cross-user object read, brute-forced login oracle, unauthorized mutation effect, redacted-field leak.

## 14. WebSockets (real-time apps)
Signal: `ws://`/`wss://` endpoints (`/ws`, `/socket.io`, `/realtime`), Socket.IO, SignalR, raw WSS in JS.
- **Authz**: is the WS handshake authenticated? Same-origin check on the `Origin` header (CSR-WS: no origin = cross-site connection → full hijack). Credentials in the URL/query vs header.
- **Message injection**: subscribe to a channel you shouldn't (admin/ops/user-1v1); send a message as another user (`sender`/`from` field) → impersonation.
- **IDOR over WS**: object-id messages with no per-message check (read someone else's realtime feed/orders).
- **Replay/plaintext**: WS over plain ws:// carrying tokens/session data; no heartbeat/encryption = note.
Proof: joined an unauthorized channel live, or a sent-message delivered as another user with the receiver screenshot.

## Interaction with deep skills
If the router maps the surface to a deeper web-<class> skill (sqli/ssrf/xss/cmd/ssti/xxe/lfi/upload/deserialization/idor), run THAT first/pivot, then come back here for the misc sweep. This pack covers what the deep packs don't.