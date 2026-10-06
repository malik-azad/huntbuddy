---
name: lab-parser
description: Parses lab/CTF/task text into structured objectives, questions, flags, and a step-by-step plan. Uses research for context. Teaches the mentality of each step. Triggers - parse this lab, /lab, teach me, CTF text, task description.
tags: [guidance, methodology, lab, ctf, teaching]
---

# Lab / Task Parser

Turn raw lab descriptions, CTF challenges, or platform tasks into a structured, actionable plan. Integrates with `research` skill for context lookups and `playwright` for automation.

## Input
- Raw task text (pasted, from file, or URL)
- Optional: platform hint (THM, HTB, CTFd, PicoCTF, custom)

## Output (structured JSON + human summary)
```json
{
  "platform": "thm|htb|ctfd|pico|other",
  "title": "Room/Challenge name",
  "objectives": ["Get user flag", "Get root flag"],
  "questions": [
    {"id": "q1", "text": "What is the user flag?", "type": "flag", "field": "user_flag"},
    {"id": "q2", "text": "What service runs on port 8080?", "type": "answer", "field": "service_8080"}
  ],
  "hints": ["Enum SMB first", "Check /robots.txt"],
  "suggested_commands": [
    {"phase": "recon", "cmd": "nmap -sC -sV -p- $TARGET", "why": "Full service enumeration before exploiting"},
    {"phase": "enum", "cmd": "enum4linux -a $TARGET", "why": "SMB shares often reveal credentials on THM/HTB Windows boxes"}
  ],
  "automation_hooks": {
    "playwright": ["login_portal", "submit_flag"],
    "research_queries": ["THM <roomname> writeup", "CVE-2023-XXXX exploit"]
  }
}
```

## Workflow
1. **Parse** — extract platform, title, objectives, questions, hints from text.
2. **Research** (optional, if enabled) — run `research` skill queries for:
   - Platform-specific methodology (THM vs HTB vs CTFd)
   - Known CVEs for identified services
   - Similar room/challenge writeups (high-level only, no spoilers unless asked)
3. **Plan** — generate phase-ordered commands with `why` explanations.
4. **Teach mode** — if user says "teach me" or `/learn`:
   - For each step: explain the *mentality* (why this phase, why this tool, what we're looking for)
   - Show alternative approaches and why we chose this one
   - Ask guiding questions before revealing the command
5. **Automation hooks** — flag `playwright` steps (login, submit) and `research` queries for later use.

## Research Integration
- When a service/version is identified (e.g., "Apache 2.4.49"), auto-query research for:
  - Known CVEs
  - Exploit availability
  - Mitigation context
- When platform = THM/HTB, query for room-specific methodology (not solutions)

## Triggers
- User pastes task text and says "parse this", "plan this lab", "what do I do?"
- `/lab <text>` or `/lab @file.txt`
- User asks "teach me how to approach this"

## Teaching Mentality (core principle)
Never just give the command. Always structure as:
1. **What we're trying to achieve** (objective)
2. **Why this phase now** (methodology)
3. **What the tool does** (mechanism)
4. **What we expect to see** (validation)
5. **What to do next based on output** (branching)