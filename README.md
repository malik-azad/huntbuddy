<div align="center">

# 🐾 Huntbuddy

**An agentic AI penetration-testing partner for your terminal.**

One command — `hunter` — takes you from recon to verified findings to a
consultant-grade report. Mentor-style, enumeration-first, and built on free AI
models with zero API keys.

```
MIT License          ·         31 skill packs          ·         4 agents
Linux · macOS        ·         free OpenCode Zen brain          ·         no refusals
```

</div>

---

## What it is

Huntbuddy is a self-hosted AI agent that lives in your terminal and works like
an experienced penetration tester. Run `hunter`, describe a target and a goal,
and it takes it from there:

> **map the surface → enumerate services → assess vulnerabilities → exploit →
> escalate → verify → report**

Every step is explained *before* it runs (mentor mode), every finding is
independently re-tested before it is called confirmed, and the final output is
a structured, evidence-backed report — the way clients and exams want it.

## Quick start

```bash
hunter                 # start the interactive chat (from any folder)
hunter "message"       # one-off question or task
hunter run "pentest 10.10.10.5, goal is root"
hunter --help          # full command reference
hunter status          # relay slot + engine health before you start
hunter whoami          # who Hunter is
```

Example prompt (chat, not commands):

```
pentest 10.10.10.5, goal is root
scan 10.10.10.0/24 and enumerate all services
engagement name: acme-ctf, target acme.local, goal: domain admin
```

## Install on a new machine

A full Huntbuddy install is two steps — the engine, then this folder.

```bash
# 1. OpenCode engine (the runtime binary, installs globally once)
curl -fsSL https://opencode.ai/install | bash
# 2. This repository (Huntbuddy itself)
git clone https://github.com/malik-azad/huntbuddy.git ~/huntbuddy
ln -s ~/huntbuddy/tools/hunter-wrapper.sh ~/.local/bin/hunter
hunter status   # sanity check
```

> Everything else (`~/huntbuddy`) is the *product*: config, skills, playbooks,
> commands and docs. The engine binary installs globally once — the folder is
> fully portable and version-controlled.

Alternatively, copy the **portable installer** (no engine install needed on the
target machine) — build it with `bash dist/make-dist.sh` and run the generated
`dist/huntbuddy-install.sh` on any Linux/macOS box.

## Features

| Feature | Why it matters |
| --- | --- |
| **Mentor mode (default)** | Explains every tool run, interprets output in plain language, teaches the *why*, and always suggests the next step. A coach, not a script-runner. |
| **Verify-before-trust** | A built-in critic re-tests every suspected finding (reproduce → cross-check → benign control) before anything is confirmed or reaches the report. Kills false positives. |
| **Free brains — zero keys** | Runs on **OpenCode Zen free models** (`opencode/…`) out of the box — no API keys, no accounts, no cards. Rotation table in `config/free-models.md`. |
| **31 skill packs** | 9 authored methodology packs + 22 service/web/phase playbooks, loaded on demand so they only cost context when relevant. |
| **One folder, no mess** | Engine config, skills, commands, helpers and docs all live in one directory. The folder is the product — version it, bundle it, clone it. |
| **OSCP/CPENT discipline** | Enumeration-first, low-noise, proof-driven testing — the style exams and clients reward. |

## Command reference

```
hunter                                       start the interactive chat (TUI)
hunter --help | -h | help                    help screen
hunter --version | -v                        engine version
hunter status                                relay slot, running processes, skills
hunter whoami                                identity card
hunter "<message>"                           run a one-off message
hunter run "<message>"                       explicit run; times out (default 240s)
hunter auth                                  manage AI providers & login
hunter models [provider]                     list available models
hunter skills                                list loaded skill packs
hunter debug config                          resolved configuration
hunter session|stats|export|import|mcp|upgrade   engine utilities
```

Type `/guide` for mentor mode, `/verify` to sweep suspicious findings,
`/learn nmap` for a teaching drill, `/report` to write the report.

## Agents

`hunter` is the lead agent (default). It dispatches three specialists:

- **scanner** — recon/enumeration specialist (nmap, netexec, nuclei, dig, ffuf)
- **critic** — false-positive officer; re-tests suspected findings before they become confirmed
- **reporter** — writes the consultant-style report into `engagements/<name>/findings.md`

## Skills

Every folder in `skills/` is a standalone, plain-markdown skill pack. Add your
own by dropping a folder with a `SKILL.md` — no code needed.

```
authored packs      oscp-methodology · cpent-enterprise · research · privesc-linux
                    privesc-windows · bugbounty-webapi · verify-proof
                    consult-reporting · mentor-guidance
playbooks (22)      phases/recon/attack-engine · SMB/SSH/SQLi/SSRF/XXE · Docker/K8s
                    cloud/AD/pivoting · upload-RCE/deserialization/IDOR · …
```

## Models

The default brain is a free OpenCode Zen model — unlimited and refusal-free for
authorized security work:

| Model | Role | Refusal rate |
| --- | --- | --- |
| `opencode/nemotron-3-ultra-free` | main brain (default) | none |
| `opencode/nemotron-3.5-lightning-free` | fast offload (`small_model`) | none (family) |
| `google/gemini-3.5-flash` | speed dial (`/models`) | none (20 req/min cap) |

Switch models any time with `/models`; backup keys (Google, OpenRouter) attach
via `hunter auth`. Full table + reality-check notes → `config/free-models.md`.

## Configuration

Everything lives in `opencode.jsonc` at the repo root: brain model, agents,
permissions and skill paths.

| Env var | Default | Purpose |
| --- | --- | --- |
| `HUNTBUDDY_HOME` | `~/huntbuddy` | where the folder lives |
| `HUNTBUDDY_BIN` | — | install target for the wrapper |
| `HUNTBUDDY_OPENCODE` | `opencode` on PATH | engine binary path |
| `HUNTBUDDY_RUN_TIMEOUT` | `240` | `hunter run` bail-out (seconds) |

Per-session brand and operator rules are loaded from `HUNTBUDDY.md`.

## Safety

- **Authorized scope only.** Before touching a target, Hunter confirms it is in
  scope for the engagement; recon and enumeration on in-scope targets never
  need extra justification.
- **Hard stops baked in:** `rm -rf /`, `mkfs.*` and raw-write to block devices
  are denied at the engine level (`permission` in `opencode.jsonc`).
- **Scope guard:** `tools/helpers/hb-scope.sh` keeps tool calls inside the
  engagement's target list.
- **Credentials never leave the machine.** Sensitive engagement data stays in
  `engagements/` and is git-ignored.

## Project layout

```
huntbuddy/
  opencode.jsonc     brain + agents + permissions + skills config
  HUNTBUDDY.md       brand & operator rules loaded into every session
  skills/            9 authored methodology packs (plain markdown)
  playbooks/         22 service/web/phase playbooks
  tools/             hunter wrapper + helpers (scope guard, reports, scaffold)
  config/            free-model rotation notes
  docs/              PDF manual, diagrams, quickstart
  dist/              make-dist.sh — builds the portable installer
  engagements/       one folder per engagement (git-ignored)
```

## Docs & manual

- `docs/Huntbuddy-Guide.pdf` — the full illustrated manual (run `python3 docs/build_manual.py` to rebuild).
- `docs/QUICKSTART.md` · `docs/FIRST-RUN.md` — getting around fast.

## License

[MIT](LICENSE) — see the [NOTICE](NOTICE) file for third-party attributions.

---

<div align="center">

**Huntbuddy ·  recon → report ·  private personal tool**

</div>