#!/usr/bin/env python3
"""Build Huntbuddy manual.html (image-rich, print-ready). v2 — post-rebrand."""
import html, os

DOCS = os.path.dirname(os.path.abspath(__file__))

def read(name):
    with open(os.path.join(DOCS, "samples", name), encoding="utf-8", errors="replace") as f:
        return f.read()

def term(name, caption="", trim=None):
    t = read(name).strip().splitlines()
    if trim: t = t[:trim]
    body = "<br>".join(html.escape(l) for l in t)
    cap = f'<figcaption>{caption}</figcaption>' if caption else ""
    return f'<figure class="term"><pre>{body}</pre>{cap}</figure>'

def terminal(text, caption=""):
    body = "<br>".join(html.escape(l) for l in text.splitlines())
    cap = f'<figcaption>{caption}</figcaption>' if caption else ""
    return f'<figure class="term"><pre>{body}</pre>{cap}</figure>'

HUNTER_HELP = """hunter — Huntbuddy, an AI pentest partner (runs on the opencode engine inside ~/huntbuddy).

Usage:
  hunter                                     start the interactive chat (TUI)
  hunter --help | -h | help                  this help
  hunter --version | -v                       engine version
  hunter status                               check relay slot, opencode procs, skills
  hunter whoami                               who Hunter is (identity card)
  hunter "<message>"                         run a one-off message
  hunter run "<message>"                      same, explicit; times out (240s) instead of hanging
  hunter auth                                 manage AI providers & login
  hunter models [provider]                    list available models
  hunter skills                               list loaded skill packs
  hunter debug config                         show resolved configuration
  hunter session|stats|export|import|mcp|upgrade   engine utilities"""

FIRST_RUN = """>  cd ~ && hunter

████ ████ ...  HUNTBUDDY — AI pentest partner · recon to report
                                                 (colors: amber on dark)

> hunter · nemotron-3-ultra-free

$ ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
      inet 192.168.1.9  netmask 255.255.255.0  broadcast 192.168.1.255
      ether 00:0c:29:ef:17:42  (Ethernet)
lo:   flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
      inet 127.0.0.1  netmask 255.0.0.0  (Loopback)

Your local IP is 192.168.1.9. Ready for the ping sweep of 192.168.1.0/24?"""

CONFIG_EXCERPT = """{
  "model": "opencode/nemotron-3-ultra-free",   // default brain: unlimited, no refusals
  "small_model": "opencode/nemotron-3.5-lightning-free",
  "default_agent": "hunter",
  "skills": { "paths": ["./skills", "./playbooks/phases", "./playbooks/playbooks",
                         "./playbooks/services", "./playbooks/web"] },
  "instructions": ["./HUNTBUDDY.md"],
  "permission": { "bash": { "rm -rf /": "deny", "dd if=* of=/dev/*": "deny" } },
  "agent": { "hunter": {...}, "scanner": {...}, "critic": {...}, "reporter": {...} }
}"""

CSS = """
:root{--bg:#0e1116;--panel:#161b22;--edge:#2d333b;--ink:#e6edf3;--acc:#f7c948;--cyan:#4dd0e1;--green:#7ee787;--red:#ff7b72;--purple:#d2a8ff;--blue:#79c0ff;--grey:#8b949e}
*{box-sizing:border-box}
body{font-family:"Segoe UI",-apple-system,Roboto,Helvetica,Arial,sans-serif;background:#0b0e13;color:#c9d1d9;margin:0;line-height:1.55}
.page{max-width:980px;margin:0 auto;padding:18px 26px;background:#0e1116}
h1{color:#f0f6fc;font-size:30px;margin:.2em 0 .4em}
h2{color:var(--acc);font-size:22px;border-bottom:2px solid var(--edge);padding-bottom:6px;margin:44px 0 14px;page-break-after:avoid}
h3{color:var(--cyan);font-size:17px;margin:22px 0 8px;page-break-after:avoid}
h4{color:var(--purple);margin:14px 0 6px}
p{margin:.5em 0}
.badge{display:inline-block;padding:2px 10px;border-radius:20px;font-size:12px;font-weight:600;margin-right:6px;vertical-align:middle}
.b-acc{background:#3a2f14;color:var(--acc);border:1px solid var(--acc)}
.b-cyn{background:#0e2b30;color:var(--cyan);border:1px solid var(--cyan)}
.b-grn{background:#0f2b17;color:var(--green);border:1px solid var(--green)}
.b-red{background:#3a1210;color:var(--red);border:1px solid var(--red)}
.b-pur{background:#2a1638;color:var(--purple);border:1px solid var(--purple)}
.cover{text-align:center;padding:90px 40px 60px;page-break-after:always}
.cover .logo{font-size:64px;font-weight:800;color:var(--acc);letter-spacing:2px}
.cover .tag{font-size:20px;color:var(--grey);margin-top:8px}
.cover .sub{font-size:13px;color:#7a8494;margin-top:30px;line-height:1.8}
.cover h1{font-size:34px;color:#f0f6fc}
.cta{display:inline-block;margin-top:34px;padding:12px 26px;border:2px solid var(--green);border-radius:10px;color:var(--green);font-weight:700;font-size:16px;text-decoration:none}
.imgwrap{text-align:center;margin:16px 0;page-break-inside:avoid}
.imgwrap img{max-width:100%;border:1px solid var(--edge);border-radius:10px}
.figcap{color:var(--grey);font-size:12px;margin-top:6px}
figure.term{background:#0a0d12;border:1px solid var(--edge);border-radius:10px;padding:12px 16px;page-break-inside:avoid}
pre{font-family:"JetBrains Mono","DejaVu Sans Mono",monospace;font-size:12px;color:#a8e6a1;margin:0;white-space:pre-wrap;word-break:break-word;line-height:1.5}
figcaption{color:var(--grey);font-size:12px;margin-top:8px}
table{width:100%;border-collapse:collapse;margin:12px 0;font-size:13px}
th{background:#161b22;color:var(--acc);text-align:left;padding:8px 10px;border:1px solid var(--edge)}
td{padding:7px 10px;border:1px solid var(--edge);vertical-align:top}
tr:nth-child(even) td{background:#0f141a}
.callout{border-left:4px solid var(--blue);background:#10151d;padding:10px 14px;margin:14px 0;border-radius:0 8px 8px 0}
.callout.warn{border-left-color:var(--red);background:#180f11}
.callout.ok{border-left-color:var(--green);background:#0f1a13}
.steps{counter-reset:st;margin:10px 0;padding-left:0;list-style:none}
.steps li{position:relative;padding:6px 0 6px 42px;counter-increment:st}
.steps li::before{content:counter(st);position:absolute;left:0;top:6px;width:28px;height:28px;border-radius:50%;background:var(--panel);border:1px solid var(--edge);color:var(--acc);font-weight:700;display:flex;align-items:center;justify-content:center;font-size:13px}
kbd{background:#21262d;border:1px solid var(--edge);border-bottom-width:3px;border-radius:5px;padding:1px 7px;font-size:12px;font-family:monospace;color:#f0f6fc}
.toc{columns:2;font-size:14px}
.toc a{color:var(--cyan);text-decoration:none}
.footer{text-align:center;color:#7a8494;font-size:11px;margin-top:40px;border-top:1px solid var(--edge);padding-top:14px}
.coverimg{width:420px;max-width:90%;margin:10px auto 20px;display:block;border-radius:14px;border:1px solid var(--edge)}
.sectitle{font-size:13px;color:var(--grey);letter-spacing:3px;text-transform:uppercase;margin-top:34px}
@media print{
 body{background:#fff}
 .page{max-width:none;padding:0 8mm;background:#fff;color:#111}
 h1,h2{color:#111}
 h2{border-bottom:1px solid #ccc;color:#b4801c}
}
"""

html_doc = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<title>Huntbuddy — Product &amp; Usage Guide</title>
<style>{CSS}</style></head>
<body>
<div class="page">

<div class="cover">
  <div class="logo">HUNTBUDDY</div>
  <div class="tag">AI penetration-testing partner · recon to report</div>
  <div class="sub">One command: <b>hunter</b>. Terminal-native agent for pentesters, OSCP/CPENT
  students, CTF players and bug-bounty hunters. Runs free &amp; unlimited on OpenCode's Zen
  models, loads 34 method skills, explains every step (mentor mode), verifies its own findings,
  writes the report. One folder. No mess. No API keys.</div>
  <a class="cta" href="#toc">Read the guide ↓</a>
</div>

<div class="sectitle">Contents</div>
<h1 id="toc">Contents</h1>
<div class="toc">
  1. What is Huntbuddy · 2. How it works · 3. Feature highlights<br>
  4. Folder layout · 5. First-time setup · 6. Daily usage · 7. Commands<br>
  8. Agents &amp; modes · 9. Your first basic test run · 10. The skills<br>
  11. Mentor mode · 12. Verification gate · 13. Reporting<br>
  14. Free brains &amp; rotation · 15. Safety &amp; scope · 16. Publishing
</div>

<h1>1 · What is Huntbuddy</h1>
<p><b>Huntbuddy</b> is a self-hosted AI agent that lives in your terminal and works like an
experienced penetration tester. Run <kbd>hunter</kbd>; describe a target and a goal; it takes it
from there — map the surface, enumerate services, assess vulnerabilities, exploit, escalate,
verify, report.</p>
{terminal(HUNTER_HELP, "The hunter command — one word, everything else is inside. hunter status tells you the relay slot state before you start.")}
<div class="callout warn"><b>Authorized testing only.</b> Huntbuddy runs real tools against
whatever you point it at. Use it only on systems you own or have explicit written permission to
test — the same responsibility as Metasploit, nmap, or nuclei.</div>

<h1>2 · How it works — architecture</h1>
<p>Two ideas power Huntbuddy: <b>a team of agents</b> and <b>skills that load on demand</b>. The
hunter agent plans the engagement and dispatches specialist subagents (scanner, critic, reporter);
expert playbooks are only pulled into context when a service or phase matches.</p>
<div class="imgwrap"><img src="img/arch.png" alt="architecture"><div class="figcap">Figure 1 — Multi-agent architecture: hunter lead + scanner/critic/reporter specialists.</div></div>
<div class="imgwrap"><img src="img/flow.png" alt="phases"><div class="figcap">Figure 2 — The seven-phase engagement flow with the mandatory verification gate before reporting.</div></div>

<h1>3 · What you get — feature highlights</h1>
<table>
<tr><th>Feature</th><th>What it does for you</th></tr>
<tr><td><span class="badge b-acc">Mentor mode</span></td><td>Explains every tool run, interprets output in plain language, teaches the "why", always proposes the next step.</td></tr>
<tr><td><span class="badge b-cyn">Verify-before-trust</span></td><td>The critic re-tests every suspected finding (reproduce → cross-check → benign control) before it can be confirmed or reach the report.</td></tr>
<tr><td><span class="badge b-grn">37 skill packs</span></td><td>12 authored methodology packs + 25 service/web/phase playbooks, all loaded on demand.</td></tr>
<tr><td><span class="badge b-pur">No-refusal</span></td><td>Authorized scanning/recon of your own networks and labs is never refused or lectured about — by explicit policy and a permissive brain.</td></tr>
<tr><td><span class="badge b-red">Free &amp; unlimited</span></td><td>Runs on OpenCode Zen free models. No API keys, no accounts, no per-minute quota walls that force you to stop mid-task.</td></tr>
<tr><td><span class="badge b-cyn">One command</span></td><td><kbd>hunter</kbd> from any folder after a single install. That's the whole product interface.</td></tr>
</table>

<h1>4 · Folder layout</h1>
<figure class="term"><pre>huntbuddy/
 ├─ opencode.jsonc    the Huntbuddy config (brain, agents, permissions, skills)
 ├─ HUNTBUDDY.md      brand + operator rules loaded into every session
 ├─ skills/           12 authored methodology packs (mentor, oscp, cpent, research, ...)
 ├─ playbooks/        25 service/web/phase playbooks (SMB, AD, SQLi, SSRF, XSS, K8s, ...)
 ├─ tools/helpers/    hb-state.sh (state machine) · hb-scope.sh · hb-report.sh · hb-engage.sh
 ├─ config/           free-models.md (model rotation playbook)
 ├─ engagements/      one ISOLATED world per engagement; state.json + findings.md + .hb-scope
 ├─ .opencode/        custom slash-commands (/guide /verify /learn)
 ├─ docs/             this manual · diagrams · samples
 ├─ start.sh · README.md · LICENSE · NOTICE · hunter (in ~/.local/bin)</pre></figure>

<h1>5 · First-time setup (from scratch)</h1>
<ol class="steps">
<li><b>Install the engine once</b> (official, system-wide): <kbd>curl -fsSL https://opencode.ai/install | bash</kbd></li>
<li><b>Get the Huntbuddy folder</b> into place: from a published bundle, <kbd>bash huntbuddy-install.sh</kbd>, or a git clone of this repo.</li>
<li><b>Done.</b> No API keys, no accounts, no login — the brain is OpenCode Zen free and connects automatically.</li>
<li><b>Check it</b>: <kbd>hunter --version</kbd> → engine version · <kbd>hunter skills</kbd> → 37 packs · <kbd>hunter debug config</kbd> → resolved brain and agents.</li>
<li><b>Test it</b>: <kbd>hunter</kbd>, then <kbd>ifconfig</kbd> — it runs your tools and sums them up.</li>
</ol>

<h1>6 · Daily usage</h1>
{terminal(HUNTER_HELP, "hunter --help — everything the command does.")}
{terminal(FIRST_RUN, "First live session: your IP tools run, replies stream, Next step offered.")}
<div class="callout warn"><b>One conversation at a time.</b> The free Zen relay serves a single
active stream per machine. If a reply ever stays silent: run <kbd>hunter status</kbd> — it will
name the opencode process holding the slot. Close any other opencode window first (including a
long-running assistant session), then run <kbd>hunter</kbd> again. Two opencode/hunter chats never
run simultaneously on the free relay.</div>

<h1>7 · In-session commands</h1>
<table>
<tr><th>Command</th><th>What it does</th></tr>
<tr><td><kbd>/guide</kbd></td><td><span class="badge b-acc">Mentor</span>Explain-everything mode — names each tool, teaches the "why", ends with a <i>Next:</i> step.</td></tr>
<tr><td><kbd>/verify</kbd></td><td><span class="badge b-grn">FP filter</span>Runs the false-positive sweep over suspected findings. Verdicts: confirmed / suspected / invalid.</td></tr>
<tr><td><kbd>/learn &lt;topic&gt;</kbd></td><td><span class="badge b-pur">Teaching</span>OSCP-instructor explanation of a technique/tool, with commands and a practice drill.</td></tr>
<tr><td><kbd>/models</kbd></td><td>Show/switch the free brains instantly (nemotron → gemini → lightning → …).</td></tr>
<tr><td><kbd>/new</kbd> <kbd>/compact</kbd> <kbd>/copy</kbd></td><td>Engine built-ins: fresh session, slim context, copy thread.</td></tr>
<tr><td>plain text</td><td>Everything else is plain chat: goals, targets, questions, or direct commands like <kbd>ifconfig</kbd>.</td></tr>
</table>

<h1>8 · Agents &amp; modes</h1>
<table>
<tr><th>Agent</th><th>Role</th><th>Color</th></tr>
<tr><td><kbd>hunter</kbd> (lead/default)</td><td>End-to-end: plan, enumerate, exploit carefully, verify, report; mentors the operator throughout.</td><td>amber #e3b341</td></tr>
<tr><td><kbd>scanner</kbd></td><td>nmap/netexec/recon specialist; returns compact host/port/service tables.</td><td>green #2e9e44</td></tr>
<tr><td><kbd>critic</kbd></td><td>False-positive officer; adversarial re-tests before anything is confirmed.</td><td>red #f85149</td></tr>
<tr><td><kbd>reporter</kbd></td><td>Writes the consultant-style report into engagements/&lt;name&gt;/findings.md.</td><td>purple #8957e5</td></tr>
</table>

<h1>9 · Your first basic test run</h1>
<ol class="steps">
<li><kbd>hunter</kbd></li>
<li>Type: <i>"engagement name: smoke-test, target: 127.0.0.1 — scan ports 1-1024 with nmap, summarize, no exploits."</i></li>
<li>Watch it: explain → run nmap → interpret → update the engagement notes → propose Next.</li>
<li>Then <kbd>/guide</kbd> for full mentor mode, <kbd>/learn nmap</kbd> for a teaching drill, <kbd>/verify</kbd> to sweep findings, <kbd>/report</kbd> to write the deliverable.</li>
</ol>
{term("nemotron-run.txt", "Real + live: the default brain executed ifconfig and was rolling the nmap sweep — no refusals, unlimited.")}

<h1>10 · The skill packs</h1>
<div class="imgwrap"><img src="img/skillmap.png" alt="skills"><div class="figcap">Figure 3 — 37 packs: 12 authored + 25 playbooks, loaded on demand.</div></div>
{term("skills-list.txt", "The actual 37 packs, straight from disk. Skills are plain markdown — add yours with a folder.")}
<h3>Getting the most out of the 12 authored packs</h3>
<ul class="steps">
<li><b>mentor-guidance</b> — on by default; type <kbd>/guide</kbd> to force it. Every reply ends with a concrete <i>Next:</i>.</li>
<li><b>oscp-methodology</b> — prompt: <i>"pentest &lt;box&gt;, goal is root. Follow the OSCP methodology."</i></li>
<li><b>cpent-enterprise</b> — prompt: <i>"network pentest of &lt;range&gt;, enumerate everything, then plan pivots."</i></li>
<li><b>privesc-linux / privesc-windows</b> — paste your low-priv shell context: <i>"I have a Linux shell as www-data on &lt;ip&gt;. Escalate."</i></li>
<li><b>bugbounty-webapi</b> — prompt: <i>"bug-bounty recon and test of &lt;domain&gt;, focus on access control and IDOR."</i></li>
<li><b>verify-proof</b> — run <kbd>/verify</kbd> before reporting; invalid findings stop getting retested.</li>
<li><b>consult-reporting</b> — <kbd>/report</kbd>, then <kbd>tools/helpers/hb-report.sh</kbd> to export HTML.</li>
</ul>

<h1>11 · Mentor mode — watch it work</h1>
{terminal(FIRST_RUN, "Huntbuddy narrates before running, interprets after, proposes Next. That is /guide behaviour.")}

<h1>12 · Verification — kill false positives</h1>
<div class="imgwrap"><img src="img/verify.png" alt="verify gate"><div class="figcap">Figure 4 — The verification gate: reproduce → cross-check → control; only confirmed findings reach the report.</div></div>
<p>Scanners lie; LLMs amplify guesses. Run <kbd>/verify</kbd> before <kbd>/report</kbd> and only
confirmed findings make it into the deliverable.</p>

<h1>13 · Reporting</h1>
<ol class="steps"><li><kbd>/report</kbd> (or <i>"write the full report"</i>).</li>
<li>Structure: executive summary → methodology → verified findings (CVSS) → coverage → appendix.</li>
<li>Export a single self-contained HTML: <kbd>tools/helpers/hb-report.sh ~/huntbuddy/engagements/&lt;name&gt;/findings.md</kbd></li></ol>

<h1>14 · Free brains &amp; rotation</h1>
<div class="imgwrap"><img src="img/models.png" alt="models"><div class="figcap">Figure 5 — Free-model strategy: unlimited permissive default + fast offload + switches when a relay hiccups.</div></div>
<table>
<tr><th>Model (default: unlimited, no refusals)</th><th>Role</th></tr>
<tr><td><kbd>opencode/nemotron-3-ultra-free</kbd></td><td><b>Default brain</b> — unlimited, understands authorized scanning, executes without refusals. Slower at peak hours but never "stuck".</td></tr>
<tr><td><kbd>opencode/nemotron-3.5-lightning-free</kbd></td><td>Fast small/offload model, same family.</td></tr>
<tr><td><kbd>opencode/big-pickle</kbd></td><td>Flagship; occasionally declines security-adjacent asks — use for general work.</td></tr>
<tr><td><kbd>google/gemini-3.5-flash</kbd></td><td>Speed-dial when wanted fast replies; caveat: 20 req/min free quota. Never the default.</td></tr>
</table>
<div class="callout warn">Reality check: no LLM is truly "unlimited". Zen free relays are shared — sometimes slow at peak, occasionally a transient error. The rotation table + <kbd>/models</kbd> is how you stay unstuck. Never paste client secrets into any free-model chat.</div>

<h1>15 · Safety &amp; scope</h1>
<ul>
<li><b>Scope guard:</b> <kbd>tools/helpers/hb-scope.sh &lt;target&gt;</kbd> checks a target against your authorized list (<kbd>engagements/.hb-scope</kbd>).</li>
<li><b>Command guardrails:</b> destructive patterns (<kbd>rm -rf /</kbd>, <kbd>dd</kbd>, <kbd>mkfs</kbd>) are denied in the default config.</li>
<li><b>No-refusal is bounded:</b> recon and exploitation on <i>your own / authorised</i> targets always runs; a genuinely unauthorised target gets one question, never a lecture.</li>
<li><b>Integrity:</b> the engine installs from the official source; your data stays in <kbd>~/.huntbuddy</kbd> folders and the engine's own storage.</li>
</ul>

<h1>16 · Publishing &amp; open-source note</h1>
<p>The folder is publishable: <kbd>README.md</kbd>, this manual, <kbd>LICENSE</kbd> (MIT),
<kbd>NOTICE</kbd>, skills, scripts, docs and config are authored content. The engine it runs on is
MIT open source (OpenCode); the 25 playbooks are ported under MIT from PentestCode. MIT requires
keeping those copyright notices in LICENSE/NOTICE when you redistribute — keep that one line;
everything else is yours to brand, extend and share.</p>

<div class="footer">Huntbuddy — product &amp; usage guide · 2026 · MIT · runs on the OpenCode engine (MIT) · playbooks from PentestCode (MIT)</div>
</div>
</body></html>
"""

out = os.path.join(DOCS, "manual.html")
with open(out, "w", encoding="utf-8") as f:
    f.write(html_doc)
print("manual.html written:", out, f"{os.path.getsize(out)//1024} KB")