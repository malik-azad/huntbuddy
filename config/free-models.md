# Free model rotation for Huntbuddy

Huntbuddy's default brain is **OpenCode Zen free** (`opencode/...` models) —
opencode's own relay for free AI models. No API keys, no accounts, no cards.
It works because Huntbuddy runs inside the OpenCode engine itself.

No provider is truly "unlimited" for free. Free relays are shared and can
occasionally be slow or return a transient error. When one model hiccups,
switch: same session, nothing else to configure.

**One conversation at a time.** The Zen relay serves a *single active stream*
per machine. If `hunter` opens to a blank screen or a reply stays silent,
someone else (usually another opencode window, or a long-running assistant
session) already holds the slot. Run `hunter status`, close the other
instance, then rerun `hunter`.

## How to switch models

Inside a session:

```
/models              # graphical model picker (Zen models are listed)
```

One-shot / permanent (edit `opencode.jsonc`, then restart `hunter`):

```jsonc
"model": "opencode/ling-3.0-flash-fin-free",   // main brain
"small_model": "opencode/ling-3.0-flash-fin-free" // cheap offload for tool output
```

## Zen free models (verified on this machine, Sep 2026)

| Model id | Refusals? | Notes |
| --- | --- | --- |
| `opencode/nemotron-3-ultra-free` | **No** | **Default.** Unlimited + executes authorized scanning/recon without refusals. Bigger, a bit slower. |
| `opencode/nemotron-3.5-lightning-free` | No (family) | Faster small/offload model, same family. |
| `google/gemini-3.5-flash` | No | **Speed dial** when you want fast responses. Caveat: free quota 20 req/min (rolling; bursts <1 min can brief-wait and recover). |
| `opencode/big-pickle` | Sometimes | Flagship; strong but can decline security-adjacent asks. |
| `opencode/ling-3.0-flash-fin-free` | Yes | Over-filtered for pentest prompts — not recommended as main. |
| `opencode/mimo-v2.5-free` | Unknown | Useful rotation. |
| `opencode/jev-1.13-free` | Unknown | Tiny/fast offload; occasionally transient 500s on the relay. |

Rule of thumb: keep **ling** (or big-pickle) as main, use a fast one for
`small_model`, and rotate when one errors.

## Reality check (so you're never surprised)

- The Zen relay is shared; a transient `Internal server error` right after a
  switch is normal — retry or pick the next model in the table above.
- If you ever want a Google/OpenRouter brain instead, that still works:
  `hunter auth` → login, then set `"model": "google/gemini-3.5-flash"` etc.
- Never paste client secrets into any chat with a free model — free tiers may
  train on prompts.