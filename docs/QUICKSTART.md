# Huntbuddy — Quickstart (plain English)

No setup required: `hunter` already runs on a free brain.

## 1. Start it

```bash
hunter
```

(From anywhere — no `cd`, no `./`.) You get the chat. If you prefer a menu,
`cd ~/huntbuddy && ./start.sh`.

## 2. Tell it what to do (chat, not commands)

Type a sentence:

```
pentest 10.10.10.5, goal is root
```

or

```
scan 10.10.10.0/24 and enumerate all open services
```

It will: plan → run tools → explain each step → record everything →
suggest the next move.

## 3. Useful things to type mid-session

| You type | What happens |
| --- | --- |
| `/guide` | Full mentor mode: explains everything, teaches as it goes |
| `/verify` | Re-tests every suspected finding before you report it |
| `/learn sql injection` | Teaches a topic like an OSCP instructor |
| `/report` | Generate a pentest report from verified findings |
| `/models` | Show/switch the free brains |

## 4. First-time setup (once)

None. The Zen free brain needs no API key. If you want an extra provider
(Google, OpenRouter), run `hunter auth` → pick the provider → follow prompts.

## 5. Adding your own knowledge

Every folder in `skills/` is a skill. To add yours:

```
skills/my-skill-name/SKILL.md
```

`SKILL.md` starts with a `---name / description---` header and then plain
markdown instructions the agent reads when it matters. That's it — no code.

## 6. After the engagement

- `findings.md` logs every finding: `tail -f ~/huntbuddy/engagements/<name>/findings.md`
- Generate an HTML report: `./tools/helpers/hb-report.sh ~/huntbuddy/engagements/<name>/findings.md`
- Scope guard: `./tools/helpers/hb-scope.sh <target>` checks your authorized list.

## Golden rule

Only test systems you own or are explicitly authorized to test. That's on you,
not the tool.