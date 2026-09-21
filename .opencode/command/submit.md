---
description: Submit a flag, answer, or form via Playwright (browser) or curl (API). Usage: /submit --flag "flag{...}" [--platform thm|htb|ctfd] [--field name] [--browser] [--cookie "session=..."]
---
Submit a flag/answer. Two backends:

**1. Playwright (browser) — default if browser skill loaded**
- Opens visible browser, you log in once, then it fills & submits.
- Usage: `/submit --flag "flag{abc}" --browser`
- If already have a Playwright page open, reuses it.

**2. curl (API) — for platforms with REST endpoints**
- HTB: `POST /api/v1/machine/submit` with `Authorization: Bearer <token>`
- THM: `POST /api/v1/room/submit` (if available)
- CTFd: `POST /api/v1/challenges/attempt` with `Content-Type: application/json`
- Usage: `/submit --flag "flag{abc}" --platform htb --cookie "session=xyz"`

**Arguments**
- `--flag "..."` — the flag/answer to submit (required)
- `--answer "..."` — alias for --flag (for non-flag questions)
- `--platform thm|htb|ctfd|custom` — selects API backend
- `--field "name"` — form field name (default: "flag" or "answer")
- `--browser` — force Playwright path
- `--cookie "k=v; k2=v2"` — session cookie for curl path
- `--url "https://..."` — custom endpoint (with --platform custom)

**Examples**
```
/submit --flag "THM{user_flag_here}" --platform thm
/submit --flag "HTB{root_flag_here}" --platform htb --cookie "session=abc123"
/submit --flag "flag{...}" --browser
/submit --answer "42" --field "question_1" --platform ctfd --cookie "session=xyz"
```

**Behavior**
- Validates flag format (regex: `flag\{.+\}` or `THM\{.+\}` or `HTB\{.+\}` or `picoCTF\{.+\}`)
- On Playwright: launches browser, waits for you to log in, then fills field + submits, screenshots result.
- On curl: posts JSON/form, prints response, checks for "correct"/"incorrect" keywords.
- Logs submission to engagement state (`hb-state.sh add <name> flags '{"flag":"...","status":"submitted","platform":"..."}'`)

**Safety**
- Never stores credentials. Cookie/token passed per-call only.
- Browser session dies after submission (no persistent login).