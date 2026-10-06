---
name: research
description: Quick OSINT/intel on a target, site, URL, document, or dropped text. Parses input, runs fast web searches for tech/CVE/lab context, outputs a compact intel brief. Triggers - research this, look up this link, find lab info, brief me. NOT auto-run.
tags: [recon, osint, intel, websearch]
---

# Research & Intel Briefing

Goal: turn an unknown input (IP, domain, URL, lab name, PDF/text, company) into an actionable intel card — fast. Time-boxed, prioritised, no rabbit holes.

## Step 1 — Classify the input (a few seconds)
- **IP/host** → target is a machine; research = service + context, find the lab/platform it belongs to.
- **URL/domain** → target is a web asset; research = stack, owner, tech, exposed paths.
- **Lab/challenge name** (TryHackMe, HTB, HackTheDna, CTF) → research = official challenge page only if needed to learn the OBJECTIVE (difficulty, flags/root required, provided creds). Do NOT fetch walkthroughs/solutions before attempting the box — that defeats the practice. Only use writeups AFTER completion, never during.
- **Raw text/document/PDF** → research = summarise, extract keys, secrets, credentials, metadata, high-value strings.
- **Company/person** → research = domains, tech, people, breach history (public only).

## Step 2 — Mine the input itself FIRST (cheapest intel)
Before any web search, extract from what you have:
- URL anatomy: scheme, subdomain, parameters, ports implied (`:8080`, `:3000`), file extensions, API paths (`/api`, `/graphql`, `/docs`).
- Visible content: framework fingerprints (`Powered by`, generator meta tag), version strings, error pages, login portals, open redirects in links.
- If it's a file/link the user gave: pull headers/meta when feasible (`curl -sI` on authorised targets), read the content.
- Structured strings: JWTs (`eyJ...`), API keys, email addresses, usernames, tokens — note them for later, never dump them into third-party services.

## Step 3 — Targeted web research (fast, 1 search pass unless needed)
Use the WebSearch tool; 3-6 targeted queries max, then stop:
1. `"<domain>" + "<tech from Step 2>"` → version/stack confirmation, known CVEs tied to it.
2. `"<domain>" vulnerability OR disclosure OR breach` (public, reputable sources only).
3. For a lab name → the platform's official page (objective, difficulty rating, entry creds, required flags). Skip if the user already gave objective/target.
4. Only if something material is missing: one follow-up query (e.g. a specific CVE applicability, subdomain enumeration hints).

Rules:
- **Never guess URLs** — only fetch links the search returns or the user supplied.
- Stay on reputable, public sources. No credential stores, no stolen data, no walkthroughs mid-engagement.
- Time-box: if 2-3 queries don't answer it, mark it unknown and move on. Quick = 1-2 minutes, not a research project.

## Step 4 — Output the intel brief (compact, structured)
Finish with a short card:
- **What it is** — target type, platform, difficulty (for labs).
- **Tech stack** — fingerprint result with versions where known.
- **Objective** — for labs: what "done" means (root flag, user flag, specific task). For configs: what the user wants extracted.
- **Keys & attack angles** — suspicious endpoints, versions with known CVEs, exposed creds/keys/tokens found, most promising service/vector given the stack.
- **Next** — the single best first step (usually: open the target in `oscp-pentest` or matched service playbook, or hand the intel brief to the user).

## Speed rules
Parse-before-search, no more than ~6 queries, one brief. Informational only — nothing here is a finding until verified. If the research is for a lab the user is running, note that walkthroughs are off-limits until after the solve.