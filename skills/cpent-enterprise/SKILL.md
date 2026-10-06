---
name: cpent-enterprise
description: CPENT/enterprise engagement - scope discovery, network aggregation/graphing, pivoting, SOE attacks, AV/EDR-aware execution, credential harvesting, wireless/IoT, evidence chains. Triggers - enterprise engagement, CPENT, multiple segments, pivot.
tags: [methodology, engineering, infrastructure]
---

# Enterprise Network Pentesting (CPENT variant)

Enterprise engagements are about the NETWORK, not a single box. You win by mapping, aggregating, pivoting, and chaining small wins into domain/network dominion — always within the written scope.

## Phase A — Scope & network discovery
- Parse the engagement scope: ranges, domains, VLANs, exclusions, *authorized* targets only.
- Map the estate: `nmap -sn` per subnet; DNS zone transfers (`dig axfr`), SPF/DMARC/related-domains, SSL scans for assets that love to hide (staging, dev, VPC).
- Correlate every host to a business function. Note DMZ vs internal vs cloud.

## Phase B — Aggressive but structured scanning
- Syn-sweep all scoped ranges: `nmap -sS -p- --min-rate 2000 -iL ranges.txt -oA sweep`
- Service+version per open port; then `nuclei` on exposed web; store everything via parsers into engagement state (nmap_parse, nuclei_parse, cme_parse).

## Phase C — Standard Operating Environment (SOE) attacks
Enterprises run SOE images: learned OS hostnames, domain-joined hosts, common software (agents, backup, patch mgmt).
- Enable `nmap --script smb-os-discovery`, NetExec host runs, `bloodhound` on AD.
- Look for: unrepatched SOE software, default agents, exposed admin panels, SMB signing disabled, common user names (first.last), password policy lapses (use domain policy, no lockout — spray carefully).

## Phase D — Pivoting & internal movement
- First code-exec anywhere = a pivot candidate if dual-homed. Load the built-in `svc-pivoting` skill: chisel/ligolo/SOCKS + `proxychains`.
- Enumerate from INSIDE out: internal nmap via pivot, SMB share access, AD attacks (AS-REP roast, kerberoast, relay when signing disabled with `ntlmrelayx`).
- Track every pivot in state (tunnel_manage) so the chain is reproducible.

## Phase E — Evasion-aware execution
Enterprises have AV/EDR. Rules: know what's monitored before you drop anything.
- Prefer living-off-the-land (PowerShell? only if allowed), inline `msfvenom` with `-e`/crypt templates, staged payloads, in-memory execution, and ALWAYS clean up files + logs you created.
- Document every AV interaction observed (what got flagged) — that's test evidence.

## Phase F — Credential harvesting & post-exploit
- Dump order: SAM/LSA secrets, DPAPI, browser stores, token theft, then crack interesting hashes offline; spray ONLY at a rate the domain tolerates (track lockout policy first).
- Goal-oriented: DA / domain-join machine / high-value data within scope.

## Phase G — Wireless / IoT / perimeter extras (as scoped)
- Wireless surveys, Bluetooth (if clearly in scope), IoT protocol audits — follow scope strictly; passive first, active only when authorized.

## Phase H — Report-grade evidence
- Every finding: evidence chain, severity (CVSS-style), reproduction steps, business impact, remediation. Export with `/report` or `report_gen`, verify with `verify-proof`.

## Always
Centralise all routes, creds, tokens, and findings in engagement state; the reviewer/critic agent re-tests before anything is marked confirmed.