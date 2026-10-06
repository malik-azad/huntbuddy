# Huntbuddy — FROM SCRATCH (first time on any machine)

Everything happens inside `~/huntbuddy` plus one global install of the
OpenCode engine. ~3 minutes total. No API keys needed.

## Step 0 · Prereqs (already on Kali)

```bash
command -v opencode && nmap --version
# expected: a path is printed, and nmap version info
```

If `opencode` is missing, install it once (official installer):

```bash
curl -fsSL https://opencode.ai/install | bash
# ~/.opencode/bin/opencode will be placed on your PATH
```

## Step 1 · Sanity check the Huntbuddy install

```bash
hunter --version      # 1.18.31
hunter --help          # the command reference
hunter skills          # should show 34 skill packs (12 authored + playbooks)
```

## Step 2 · First live chat (the basics test)

```bash
hunter
```

Then type, one line at a time, and watch it work:

```
engagement name: smoke-test, target: 127.0.0.1
```
```
scan 127.0.0.1 ports 1-1024 with nmap and summarize open ports. no exploits.
```
```
/guide          → mentor mode: it explains every step
/verify         → re-test anything it found (false-positive sweep)
/learn nmap     → teaching mode: instructor-style explanation
/report         → generate the findings document
```
Type `exit` to leave.

## What "it works" looks like

The chat header shows `hunter · ling-3.0-flash-fin-free` — your brand and the
free Zen brain. The agent announces each step before running it, interprets
the outcome in plain language, ends every reply with a `Next:` step, and never
marks a finding confirmed before the verify-proof routine.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `Internal server error` / model busy | Free relay hiccup — retry, or `/models` and pick another `opencode/...` free model (see `config/free-models.md`). |
| `hunter: command not found` | `~/.local/bin` must be on PATH; if not, add it in `~/.zshrc` or run `~/.local/bin/hunter`. |
| `engine not found on PATH` | Install opencode (see Step 0) or run `HUNTBUDDY_OPENCODE=/path/to/opencode hunter`. |
| Config not taking effect | Config loads at start — quit and restart `hunter`. |
| "out of scope" | The guard is working. Add your target to `engagements/.hb-scope` (if authorized). |

## Golden rule

Only test systems you own or are authorized to test.