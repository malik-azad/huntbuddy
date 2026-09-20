---
name: consult-reporting
description: Professional pentest report structure for Huntbuddy engagements—executive summary, methodology, verified findings with evidence + CVSS, reproduction, remediation, and traceability to evidence artifacts. Use at the REPORTING phase or when the user asks for a full report. Triggers - write report, /report, reporting phase, deliverable, executive summary.
tags: [reporting, methodology]
---

# Consultant-Grade Report Structure

Write the report with verified findings only (see `verify-proof`). Every claim in the report must point at an evidence line.

## Structure (the skeleton Huntbuddy uses)

### 1. Executive summary
- 8 lines max. What was assessed, what was found (top 3 risks by severity), business impact in plain language, one-line recommendation.

### 2. Scope & methodology
- Targets/ranges, dates, tools, phases followed, exclusions.

### 3. Findings — ordered by severity (CVSS 3.1 style)
Per finding:
- **Title** — `[Severity] [Type] on [Asset]` (e.g., `High · SQL Injection on https://app/api/v2/search?id=`)
- **Evidence chain** — the exact repro steps with tool output/HTTP snippets that the verifier confirmed.
- **Impact** — what an attacker could actually do with this (business language + technical).
- **Remediation** — specific fix, plus (optionally) compensating controls.

For OSCP/CPENT-style engagements, this section is the "attack narrative": the full chain from initial access to final proof, step by step, with the commands used. Walk through it like a story — graders want the THINKING, not just the exploit.

### 4. Coverage summary
- Hosts/services tested, notes on out-of-scope or skipped items, tests that returned no findings.

### 5. Appendix
- Full command log / evidence files references, hashes, creds table (redacted as appropriate), tool versions.

## Rules
- Only `confirmed` (verify-proof) findings enter Sections 3–5. Suspected findings go to an appendix "Further investigation" list, clearly labelled unconfirmed.
- Redact client data that doesn't belong in the report (internal emails in sample data, passwords shown as `P@ss***`).
- Keep commands reproducible: full paths/arguments, no placeholders left unresolved.

## Delivery
- Generate markdown and HTML via `report_gen` (or `/report`). Save a copy in the engagement folder so it survives.
- Offer the raw `findings.md` as machine-readable evidence alongside the human report.