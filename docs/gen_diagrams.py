#!/usr/bin/env python3
"""Generate Huntbuddy documentation diagrams (PNG) with matplotlib."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mp
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

C = {
    "bg": "#0e1116", "panel": "#161b22", "edge": "#2d333b",
    "acc": "#f7c948", "cyan": "#4dd0e1", "green": "#7ee787", "red": "#ff7b72",
    "purple": "#d2a8ff", "blue": "#79c0ff", "grey": "#8b949e", "white": "#e6edf3",
}

def box(ax, x, y, w, h, title, sub="", fc="#161b22", tc="#e6edf3", border="#2d333b", fs=12, sfs=9, lw=1.4):
    p = FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.08",
                       fc=fc, ec=border, lw=lw)
    ax.add_patch(p)
    ax.text(x + w/2, y + h/2 + (0.09 if sub else 0), title, ha="center", va="center",
            color=tc, fontsize=fs, fontweight="bold")
    if sub:
        ax.text(x + w/2, y + h/2 - 0.13, sub, ha="center", va="center", color=C["grey"], fontsize=sfs)

def arrow(ax, x1, y1, x2, y2, color="#8b949e", style="-|>", lw=1.6, ls="solid", ms=11):
    a = FancyArrowPatch((x1, y1), (x2, y2), arrowstyle=style, mutation_scale=ms,
                        color=color, lw=lw, linestyle=ls)
    ax.add_patch(a)

def setup(ax, w, h):
    ax.set_xlim(0, w); ax.set_ylim(0, h)
    ax.axis("off"); ax.set_facecolor(C["bg"])

# ---------------------------------------------------------------- 1. ARCH
fig, ax = plt.subplots(figsize=(12, 7), dpi=200)
setup(ax, 12, 7)
fig.patch.set_facecolor(C["bg"])
box(ax, 4.6, 5.6, 2.8, 1.0, "HUNTBUDDY", "hunter · lead agent / strategist", fc="#1f2328", border=C["acc"], tc=C["acc"], fs=15, sfs=8)
arrow(ax, 6.0, 5.6, 6.0, 4.55, color=C["grey"])
agents = [
    ("hunter · lead", "plan · exploit · mentor", C["acc"]),
    ("scanner", "recon · enumerate · table", C["blue"]),
    ("critic", "verify · FP officer", C["green"]),
    ("reporter", "findings · report", C["purple"]),
]
for i, (name, sub, col) in enumerate(agents):
    x = 0.7 + i * 2.95
    box(ax, x, 3.05, 2.3, 0.95, name, sub, fc="#161b22", border=col, tc=col, fs=10.5, sfs=7.5)
    arrow(ax, 6.0, 4.55, x + 1.15, 4.05, color=C["grey"], lw=1.2)
box(ax, 8.6, 4.3, 2.9, 0.9, "engagement state", "hosts · svcs · vulns · creds\naccess · graph · paths", fc="#1f2328", border=C["green"], tc=C["green"], fs=11, sfs=8)
box(ax, 3.2, 1.35, 5.6, 0.9, "31 skill packs · loaded on demand", "9 authored + 22 playbooks (phases · services · web)", fc="#1f2328", border=C["cyan"], tc=C["cyan"], fs=11, sfs=8)
arrow(ax, 5.2, 3.05, 5.4, 2.27, color=C["grey"], style="-|>", ls="--", lw=1.2)
ax.text(6.0, 0.45, "1 command: hunter  ·  engine: opencode (MIT)  ·  brain: opencode/nemotron-3-ultra-free (free, unlimited)", ha="center", color=C["grey"], fontsize=9)
plt.tight_layout(pad=0.4)
plt.savefig("img/arch.png", facecolor=C["bg"], bbox_inches="tight")
plt.close()

# ---------------------------------------------------------------- 2. FLOW (phases)
fig, ax = plt.subplots(figsize=(12, 5.6), dpi=200)
setup(ax, 12, 5.3)
fig.patch.set_facecolor(C["bg"])
phases = [
    ("1 · Scope", "authorize\ntargets", C["blue"]),
    ("2 · Recon", "nmap sweep\nhost discovery", C["blue"]),
    ("3 · Enumerate", "per-service\nenumeration", C["cyan"]),
    ("4 · Assess", "versions → CVEs\ncandidate vulns", C["purple"]),
    ("5 · Attack", "exploit →\nfoothold", C["red"]),
    ("6 · Post & Esc", "privesc\nlateral move", C["red"]),
    ("7 · Proof & Report", "verified\nfindings → report", C["green"]),
]
xs = [0.2, 2.0, 3.8, 5.6, 7.4, 9.2, 10.6]
for (title, sub, col), x in zip(phases, xs):
    box(ax, x, 2.4, 1.35, 1.55, title, sub, fc="#161b22", border=col, tc=col, fs=10, sfs=8)
for i in range(len(xs) - 1):
    arrow(ax, xs[i] + 1.35, 3.2, xs[i+1], 3.2, color=C["grey"], ms=11)
# verify gate feedback
box(ax, 4.4, 0.35, 3.2, 0.75, "verify-proof gate (re-test every finding)", fc="#1f2328", border=C["green"], tc=C["green"], fs=9, sfs=0)
arrow(ax, 6.0, 2.4, 6.0, 1.1, color=C["green"], style="-|>", ls="--", lw=1.3)
arrow(ax, 6.6, 0.75, 8.0, 2.4, color=C["green"], style="-|>", ls="--", lw=1.1)
ax.text(6.0, 0.05, "mentor mode: every phase is explained out loud, tools named, next step suggested",
        ha="center", color=C["grey"], fontsize=9)
plt.tight_layout(pad=0.4)
plt.savefig("img/flow.png", facecolor=C["bg"], bbox_inches="tight")
plt.close()

# ---------------------------------------------------------------- 3. SKILL MAP
fig, ax = plt.subplots(figsize=(12, 6.6), dpi=200)
setup(ax, 12, 6.4)
fig.patch.set_facecolor(C["bg"])
box(ax, 4.7, 5.2, 2.6, 0.95, "SKILL PACKS", "loaded on demand · plain markdown", fc="#1f2328", border=C["acc"], tc=C["acc"], fs=14, sfs=8)
groups = [
    ("Authored packs (9)", ["oscp-methodology · cpent-enterprise", "privesc-linux · privesc-windows", "bugbounty-webapi · consult-reporting", "mentor-guidance · verify-proof", "research · osint/intel briefs"], C["blue"], 0.35),
    ("Playbooks (22)", ["phases · recon · enumer · attack-engine", "services · smb · ssh · ftp · db", "services · docker · k8s · cloud · ad", "web · sqli · ssrf · ssti · xxe · lfi", "web · upload-rce · deserial · idor"], C["cyan"], 4.35),
    ("Your packs (any)", ["skills/<name>/SKILL.md", "zero code · plain markdown", "in your words, yours"], C["purple"], 9.0),
]
for gname, items, col, x in groups:
    box(ax, x, 3.2, 2.7, 0.7, gname, "", fc="#161b22", border=col, tc=col, fs=11, sfs=0)
    arrow(ax, 6.0, 5.2, x + 1.35, 3.9, color=C["grey"], lw=1.1)
    for i, it in enumerate(items):
        box(ax, x, 2.6 - i * 0.56, 2.7, 0.5, it, "", fc="#0f141a", border=C["grey"], tc="#d7dde5", fs=8.5, sfs=0)
ax.text(6.0, 0.1, "users grow their own packs: skills/<name>/SKILL.md — zero code", ha="center", color=C["grey"], fontsize=9)
plt.tight_layout(pad=0.4)
plt.savefig("img/skillmap.png", facecolor=C["bg"], bbox_inches="tight")
plt.close()

# ---------------------------------------------------------------- 4. VERIFY GATE
fig, ax = plt.subplots(figsize=(11, 4.6), dpi=200)
setup(ax, 11, 4.4)
fig.patch.set_facecolor(C["bg"])
box(ax, 0.3, 3.0, 2.3, 0.9, "finding\n(suspected)", fc="#161b22", border=C["purple"], tc=C["purple"], fs=11, sfs=0)
box(ax, 3.0, 3.0, 2.3, 0.9, "1 · REPRODUCE\nexact trigger", fc="#161b22", border=C["blue"], tc=C["blue"], fs=10, sfs=0)
box(ax, 3.0, 1.7, 2.3, 0.9, "2 · CROSS-CHECK\nindependent angle", fc="#161b22", border=C["blue"], tc=C["blue"], fs=10, sfs=0)
box(ax, 3.0, 0.4, 2.3, 0.9, "3 · NULL CHECK\nbenign control", fc="#161b22", border=C["blue"], tc=C["blue"], fs=10, sfs=0)
arrow(ax, 2.6, 3.45, 3.0, 3.45, color=C["grey"])
arrow(ax, 4.15, 3.0, 4.15, 2.6, color=C["grey"])
arrow(ax, 4.15, 1.7, 4.15, 1.3, color=C["grey"])
box(ax, 5.9, 0.4, 2.35, 3.5, "VERDICT", "confirmed →\nsuspected →\ninvalid →", fc="#1f2328", border=C["white"], tc=C["white"], fs=12, sfs=9)
arrow(ax, 5.3, 2.0, 5.9, 2.2, color=C["grey"], style="-|>", ls="--")
box(ax, 8.8, 2.6, 1.9, 1.6, "to report\never", fc="#0f141a", border=C["green"], tc=C["green"], fs=10, sfs=8)
box(ax, 8.8, 0.5, 1.9, 1.6, "resolved\n(vector dead)", fc="#0f141a", border=C["red"], tc=C["red"], fs=10, sfs=8)
arrow(ax, 8.25, 3.3, 8.8, 3.3, color=C["green"])
arrow(ax, 8.25, 1.3, 8.8, 1.3, color=C["red"])
ax.text(5.5, 0.1, "critic agent re-audits · only confirmed findings reach the report", ha="center", color=C["grey"], fontsize=9)
plt.tight_layout(pad=0.4)
plt.savefig("img/verify.png", facecolor=C["bg"], bbox_inches="tight")
plt.close()

# ---------------------------------------------------------------- 5. MODELS
fig, ax = plt.subplots(figsize=(11, 4.4), dpi=200)
setup(ax, 11, 4.2)
fig.patch.set_facecolor(C["bg"])
box(ax, 0.3, 1.9, 3.0, 1.1, "default brain", "opencode/nemotron-3-ultra-free\nunlimited · no refusals", fc="#1f2328", border=C["green"], tc=C["green"], fs=11, sfs=8)
box(ax, 0.3, 0.3, 3.0, 0.9, "fast offload", "opencode/nemotron-3.5-lightning-free", fc="#1f2328", border=C["cyan"], tc=C["cyan"], fs=10, sfs=0)
box(ax, 3.9, 1.9, 2.7, 1.1, "speed dial", "google/gemini-3.5-flash (free)\n20 req/min · fast", fc="#161b22", border=C["blue"], tc="#d7dde5", fs=10, sfs=8)
arrow(ax, 3.3, 2.45, 3.9, 2.45, color=C["acc"], style="-|>", ls="--", lw=1.3)
box(ax, 3.9, 0.3, 2.7, 1.1, "fallback rotation", "openrouter :free variants", fc="#161b22", border=C["grey"], tc="#d7dde5", fs=10, sfs=8)
box(ax, 7.2, 1.0, 2.3, 1.6, "relay hiccup?\n/models rotate", fc="#1f2328", border=C["acc"], tc=C["acc"], fs=11, sfs=9)
arrow(ax, 6.6, 2.1, 7.2, 2.1, color=C["acc"], style="-|>", ls="--")
box(ax, 9.7, 1.0, 1.1, 1.6, "$0", fc="#0f141a", border=C["green"], tc=C["green"], fs=13, sfs=0)
ax.text(6.0, 0.1, "no card · no subscription · free & unlimited by default, rotation keeps you unstuck", ha="center", color=C["grey"], fontsize=9)
plt.tight_layout(pad=0.4)
plt.savefig("img/models.png", facecolor=C["bg"], bbox_inches="tight")
plt.close()

print("diagrams done:", "arch flow skillmap verify models")