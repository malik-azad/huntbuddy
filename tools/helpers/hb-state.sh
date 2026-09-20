#!/usr/bin/env bash
# hb-state.sh — Huntbuddy per-engagement state machine (one world per engagement).
# Official record: engagements/<name>/state.json ; active pointer: engagements/.active.
# Usage:
#   hb-state.sh list
#   hb-state.sh active [name]
#   hb-state.sh new <name> [--platform bugbounty|thm|htb|client|lab|other] [--phase PHASE] [targets...]
#   hb-state.sh get [name]
#   hb-state.sh set <name> <key> <json>       # replace a scalar or whole list
#   hb-state.sh add <name> <key> <json>       # append to a list (no duplicates)
#   hb-state.sh scopesave <name>              # rewrite .hb-scope from in_scope+targets
set -euo pipefail

python3 - "$@" <<'HBSTATE'
import json
import os
import sys

ENG = os.path.join(
    os.environ.get("HUNTBUDDY_HOME", os.path.join(os.path.expanduser("~"), "huntbuddy")),
    "engagements",
)
ACTIVE = os.path.join(ENG, ".active")

PHASES = ["recon", "enumeration", "vuln_assess", "exploitation", "post_exploit", "reporting"]
SCALAR_KEYS = {"status", "phase", "platform"}
ARRAY_KEYS = {"targets", "in_scope", "out_of_scope", "hosts", "findings",
              "creds", "flags", "next_steps", "notes", "log"}
ALLOWED = SCALAR_KEYS | ARRAY_KEYS

def now():
    import datetime
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def state_path(name):
    return os.path.join(ENG, name, "state.json")

def load(name):
    p = state_path(name)
    if not os.path.isfile(p):
        sys.exit("error: no engagement '%s' (run: hb-state.sh new %s ...)" % (name, name))
    with open(p) as f:
        return json.load(f)

def save(name, state):
    state["name"] = name
    state["updated"] = now()
    p = state_path(name)
    with open(p, "w") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)

def card(name):
    s = load(name)
    out = []
    out.append("name      : %s" % name)
    out.append("platform  : %s" % s.get("platform", "-"))
    out.append("status    : %s" % s.get("status", "active"))
    out.append("phase     : %s" % s.get("phase", "recon"))
    ins = ", ".join(s.get("in_scope") or []) or "-"
    out.append("in scope  : %s" % ins)
    outs = ", ".join(s.get("out_of_scope") or []) or "-"
    out.append("out scope : %s" % outs)
    out.append("hosts     : %d" % len(s.get("hosts") or []))
    f = s.get("findings") or []
    states = {}
    sev = {}
    for x in f:
        states[x.get("state", "suspected")] = states.get(x.get("state", "suspected"), 0) + 1
        sev[x.get("severity", "?")] = sev.get(x.get("severity", "?"), 0) + 1
    out.append("findings  : %d total (%s)" % (
        len(f),
        ", ".join("%s:%d" % kv for kv in sorted(states.items())) or "none"))
    creds = s.get("creds") or []
    out.append("creds     : %d" % len(creds))
    out.append("flags     : %s" % (", ".join(s.get("flags") or []) or "-"))
    ns = s.get("next_steps") or []
    out.append("next      : " + (" | ".join(ns[:3]) if ns else "-"))
    log = s.get("log") or []
    if log:
        out.append("last      : %s — %s" % (log[-1].get("ts", "?"), log[-1].get("what", "")))
    return "\n".join(out)

def main():
    argv = sys.argv[1:]
    if not argv:
        sys.exit("usage: hb-state.sh list|active|new|get|set|add|scopesave ...")
    cmd = argv[0]

    if cmd == "list":
        dirs = [d for d in os.listdir(ENG) if os.path.isdir(os.path.join(ENG, d)) and os.path.isfile(state_path(d))] if os.path.isdir(ENG) else []
        dirs.sort(key=lambda d: os.path.getmtime(state_path(d)), reverse=True)
        for d in dirs:
            mark = "*" if os.path.exists(ACTIVE) and open(ACTIVE).read().strip() == d else " "
            s = load(d)
            print("%s%s  [%s] %s" % (mark, d, s.get("phase", "recon"), ", ".join(s.get("in_scope") or [])[:60]))
        if not dirs:
            print("no engagements yet — start one: hb-state.sh new <name> [targets...]")

    elif cmd == "active":
        if len(argv) > 1:
            name = argv[1]
            if not os.path.isfile(state_path(name)):
                sys.exit("error: no engagement '%s'" % name)
            os.makedirs(ENG, exist_ok=True)
            open(ACTIVE, "w").write(name + "\n")
            print("active engagement: %s" % name)
        else:
            print(open(ACTIVE).read().strip() if os.path.isfile(ACTIVE) else "none")

    elif cmd == "new":
        if len(argv) < 2:
            sys.exit("usage: hb-state.sh new <name> [--platform p] [--phase p] [targets...]")
        name = argv[1]
        platform, phase = "other", "recon"
        targets = []
        i = 2
        while i < len(argv):
            if argv[i] == "--platform":
                platform = argv[i + 1]; i += 2; continue
            if argv[i] == "--phase":
                phase = argv[i + 1]; i += 2; continue
            targets.append(argv[i]); i += 1
        if phase not in PHASES:
            sys.exit("error: phase must be one of %s" % ", ".join(PHASES))
        folder = os.path.join(ENG, name)
        if os.path.isdir(folder):
            sys.exit("error: engagement '%s' already exists — work in it or switch (active)." % name)
        os.makedirs(folder, exist_ok=True)
        state = {
            "platform": platform, "status": "active", "phase": phase,
            "targets": targets, "in_scope": list(targets), "out_of_scope": [],
            "hosts": [], "findings": [], "creds": [], "flags": [],
            "next_steps": [], "notes": [], "log": [],
        }
        save(name, state)
        open(os.path.join(folder, "README.md"), "w").write(
            "# %s\n\n- Created: %s\n- Platform: %s\n- Phase: %s\n\n## Notes\n" % (name, now(), platform, phase))
        open(os.path.join(folder, "findings.md"), "w").write(
            "# %s — verified findings\n\n| # | Title | Severity | State | Evidence |\n|---|-------|----------|-------|----------|\n" % name)
        write_scope(name)
        os.makedirs(ENG, exist_ok=True)
        open(ACTIVE, "w").write(name + "\n")
        print("new isolated engagement: %s (now active)" % name)
        print(card(name))

    elif cmd == "get":
        name = argv[1] if len(argv) > 1 else (open(ACTIVE).read().strip() if os.path.isfile(ACTIVE) else "")
        if not name:
            sys.exit("no active engagement — name one or run: hb-state.sh new <name> [target]")
        print(card(name))

    elif cmd == "set":
        if len(argv) < 4:
            sys.exit("usage: hb-state.sh set <name> <key> <json>")
        name, key, raw = argv[1], argv[2], argv[3]
        if key not in ALLOWED:
            sys.exit("error: key must be one of %s" % ", ".join(sorted(ALLOWED)))
        try:
            val = json.loads(raw)
        except ValueError:
            sys.exit("error: value is not valid JSON: %s" % raw)
        s = load(name); s[key] = val; save(name, s)
        print("%s.%s = %s" % (name, key, json.dumps(val)))

    elif cmd == "add":
        if len(argv) < 4:
            sys.exit("usage: hb-state.sh add <name> <list-key> <json>")
        name, key, raw = argv[1], argv[2], argv[3]
        if key not in ARRAY_KEYS:
            sys.exit("error: key must be one of %s" % ", ".join(sorted(ARRAY_KEYS)))
        try:
            val = json.loads(raw)
        except ValueError:
            sys.exit("error: value is not valid JSON: %s" % raw)
        s = load(name)
        lst = s.setdefault(key, [])
        if val not in lst:
            lst.append(val)
        if key in ("targets", "in_scope", "out_of_scope") and key == "in_scope":
            write_scope(name, s)
        save(name, s)
        print("%s.%s now has %d entries" % (name, key, len(lst)))

    elif cmd == "scopesave":
        if len(argv) < 2:
            sys.exit("usage: hb-state.sh scopesave <name>")
        write_scope(argv[1])
        print("scopes written for %s" % argv[1])

    else:
        sys.exit("unknown command: %s" % cmd)

def write_scope(name, s=None):
    if s is None:
        s = load(name)
    lines = []
    for x in (s.get("in_scope") or []) + (s.get("targets") or []):
        if x and x not in lines:
            lines.append(x)
    with open(os.path.join(ENG, name, ".hb-scope"), "w") as f:
        f.write("# authorised in-scope targets for engagement '%s' — one per line\n" % name)
        for x in lines:
            f.write(x + "\n")

main()
HBSTATE