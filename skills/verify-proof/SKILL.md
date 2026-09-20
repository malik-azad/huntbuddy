---
name: verify-proof
description: Huntbuddy's built-in false-positive officer. Before any finding is marked confirmed or written to the report, re-test it independently—exact same request/commands, different angle, and a null-check (does it also trigger on a benign input?). Suspected findings must earn 'confirmed' with evidence. Triggers - before state_update to confirmed, before report_gen, when a scanner (nuclei/sqlmap/nmap) reports a vuln, or the critic agent flags uncertainty.
tags: [guidance, methodology, confidence]
---

# False-Positive Verification (non-negotiable gate)

Scanners and LLMs lie. Every suspected finding must PASS this gate before being marked `confirmed` or reaching the report.

## Step 1 — Reproduce
Re-run the exact original trigger. Save proof text: server response, timestamp, HTTP code, output line. It must reproduce identically.

## Step 2 — Cross-check (different angle)
Confirm the same vulnerability from an independent angle:
- SQLi: sqlmap `--batch --current-user --dbs` output vs an independent manual probe (`'`, `), `ORDER BY 5`, sleep compare).
- SSRF: hit the payload against a netcat listener you own (`nc -lvnp 8080`) and show the callback packet — not just a vague redirect.
- XSS: inspect the stored/reflected position in the actual response HTML (is it inside a tag? escaped?). Trigger with a known benign payload → confirm contrast.
- IDOR: show two different accounts (A accesses B's resource). Show the response returning B's data AND account A authenticated.
- RCE/File upload: execute `id`/a hashed canary (echo plus md5) on the target, verify the returned hash.
- Auth bypass: show the admin-only endpoint responded with admitted privileges for a low-priv token.
- Service/version findings: verify the version match and the vulnerability's applicability (is the reported version actually vulnerable? patch state?).

## Step 3 — Null check
Repeat the original request with a benign control value. If the benign input ALSO triggers the "indicating" behavior, the finding is a false positive — mark as invalid in state and move on.

## Step 4 — Verdict
- `confirmed` = reproducible + cross-checked + control clean → allowed into report as evidence-backed.
- `suspected` = reproducible but not fully cross-checked → keep labelled, do not report as fact.
- `invalid` = failed reproduction or control noisy → record as resolved vector (do NOT retest it repeatedly; note the dead-end so the agent stops wasting cycles).

## Step 5 — Record
- Update `state_update` with status + evidence chain string. Then the `critic` agent and `report_gen` will only carry confirmed items forward.

## Speed rules
Verification is mandatory but fast: prefer one control + one cross-check per finding. Batch verifications (run the repro + control for several findings in one sweep). Skip only for informational observations (open port, service banner), never for vulnerabilities.