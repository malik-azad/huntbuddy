#!/usr/bin/env bash
# hb-proxy.sh — Huntbuddy interception proxy manager (burp-mode skill engine).
# Uses Burp Suite GUI when installed, else mitmproxy/mitmweb. Same port :8080.
set -euo pipefail

PORT=8080
WEBPORT=8081
BURP_PATHS=( "/opt/BurpSuitePro/burpsuite" "/opt/BurpSuiteCommunity/burpsuite"
  "$HOME/BurpSuitePro/burpsuite" "$HOME/BurpSuiteCommunity/burpsuite"
  "$HOME/Downloads/Burpsuite-Professional/burpsuitepro" )

usage() { cat <<'EOF'
usage: hb-proxy.sh <cmd> [args]
  detect              show which proxy engine is available
  start [--burp]      start the proxy on :8080 (default mitmweb; --burp for Burp GUI)
  stop                stop mitmweb/mitmdump/curl-down the tunneled proxy
  status              is something listening on :8080?
  poc <req-file>      turn a raw HTTP request file into curl + python PoC + summary
  har <flows-file>    (placeholder) bundle flows for evidence
  shot <url> <name>   Playwright full-page screenshot into engagements/<active>/evidence
Check for poison-value oddities: port, proxy. Logging to ~/.huntbuddy/evidence.
EOF
}

detect() {
  local found=0
  for b in "${BURP_PATHS[@]}"; do
    if [ -f "$b" ]; then echo "burp-gui: $b"; found=1; break; fi
  done
  if [ "$found" = 0 ]; then command -v burpsuite >/dev/null 2>&1 && echo "burp-gui: $(command -v burpsuite)"; fi
  command -v burpsuitepro >/dev/null 2>&1 && echo "burp-pro: $(command -v burpsuitepro)"
  command -v mitmweb >/dev/null 2>&1 && echo "mitmweb: $(command -v mitmweb)"
  command -v mitmproxy >/dev/null 2>&1 && echo "mitmproxy: $(command -v mitmproxy)"
  command -v java >/dev/null 2>&1 && echo "java: $(command -v java)"
  command -v playwright >/dev/null 2>&1 && echo "playwright: yes" || echo "playwright: no (browser scripts need it)"
}

listening() { ss -tln 2>/dev/null | awk '{print $4}' | grep -q ":$1$"; }

start() {
  local use_burp=""
  [ "${1:-}" = "--burp" ] && use_burp=1

  # Default engine: mitmweb (fast, lightweight, headless). Burp only when explicitly requested.
  if [ -z "$use_burp" ]; then
    if command -v mitmweb >/dev/null 2>&1; then
      if listening "$PORT"; then
        echo "mitmweb already up on :$PORT (web UI http://127.0.0.1:$WEBPORT)"
      else
        mkdir -p "$HOME/.huntbuddy/evidence"
        nohup mitmweb --listen-port "$PORT" --web-port "$WEBPORT" \
          --set web_open_browser=false >/dev/null 2>&1 &
        echo "started mitmweb pid $! — proxy 127.0.0.1:$PORT, web GUI http://127.0.0.1:$WEBPORT"
        echo "browser/proxy hint: set proxy 127.0.0.1:$PORT to capture."
      fi
      return
    fi
  fi

  # Explicit Burp request (or mitmweb unavailable) → use the installed Burp GUI.
  local engine=""
  for b in "${BURP_PATHS[@]}"; do [ -f "$b" ] && engine="$b" && break; done
  [ -z "$engine" ] && command -v burpsuite >/dev/null 2>&1 && engine="$(command -v burpsuite)"
  if [ -n "$engine" ]; then
    if listening "$PORT"; then
      echo "proxy already listening on :$PORT — in Burp set intercept as needed."
    else
      echo "launching Burp Suite GUI: $engine"
      # Burp binds 127.0.0.1:8080 by default; start in background, user drives the GUI.
      nohup "$engine" >/dev/null 2>&1 &
      echo "started pid $! — wait for the GUI, keep intercept ON when you want manual review."
    fi
  elif command -v mitmweb >/dev/null 2>&1; then
    if listening "$PORT"; then
      echo "mitmweb already up on :$PORT (web UI http://127.0.0.1:$WEBPORT)"
    else
      mkdir -p "$HOME/.huntbuddy/evidence"
      nohup mitmweb --listen-port "$PORT" --web-port "$WEBPORT" \
        --set web_open_browser=false >/dev/null 2>&1 &
      echo "started mitmweb pid $! — proxy 127.0.0.1:$PORT, web GUI http://127.0.0.1:$WEBPORT"
      echo "browser/proxy hint: set proxy 127.0.0.1:$PORT to capture."
    fi
  else
    echo "no proxy engine found — install Burp Community, or: mkdir; check mitmproxy" >&2
    exit 1
  fi
}

stop() {
  # detect what holds the port before stopping, so we don't say "mitmweb stopped" for Burp
  local owner=""
  if listening "$PORT" && [ -n "$(command -v ss)" ]; then
    owner="$(ss -tlnp 2>/dev/null | grep ":$PORT " | grep -oE 'users:\(\("([^"]+)"' | head -1 | sed 's/users:(("//')"
  fi
  case "$owner" in
    java*) pkill -f -x 'burpsuite|burpsuitepro' 2>/dev/null || pkill -f 'burpsuite' 2>/dev/null || true; echo "stopped Burp GUI." ;;
    mitm*) ( pkill -x mitmweb 2>/dev/null; pkill -x mitmdump 2>/dev/null ) || true; echo "stopped mitm proxy." ;;
    *) ( pkill -x mitmweb 2>/dev/null; pkill -x mitmdump 2>/dev/null ) || true; echo "stopped mitm proxy (if running). Burp GUI you close manually." ;;
  esac
}

status() {
  if listening "$PORT"; then
    local owner=""
    [ -n "$(command -v ss)" ] && owner="$(ss -tlnp 2>/dev/null | grep ":$PORT " | grep -oE 'users:\(\("([^"]+)"' | head -1 | sed 's/users:(("//')"
    echo "PROXY UP on 127.0.0.1:$PORT (engine: ${owner:-unknown})"
    ss -tlnp 2>/dev/null | grep ":$PORT " | head -2 || true
  else
    echo "proxy DOWN on 127.0.0.1:$PORT (run 'hb-proxy.sh start')"
  fi
}

poc() {
  local req="${1:?usage: hb-proxy.sh poc <raw-request-file>}"
  [ -f "$req" ] || { echo "no such request file: $req" >&2; exit 1; }
  # Build a curl + python-requests PoC from a raw HTTP request capture.
  python3 - "$req" <<'PY'
import re, sys, datetime
raw = open(sys.argv[1]).read()
lines = raw.split("\r\n\r\n", 1)
head = lines[0]; body = lines[1] if len(lines) > 1 else ""
hl = head.split("\r\n")
first = hl[0].split(" ")
if len(first) < 3: sys.exit("not a raw HTTP request")
method, path = first[0], first[1]
headers = {}
for h in hl[1:]:
    if ":" in h:
        k, v = h.split(":", 1); headers[k.strip()] = v.strip()
host = headers.get("Host", "target")
# TLS detection: https if not explicitly http
scheme = "http"
for k in headers:
    if k.lower() == "x-forwarded-proto" and headers[k] == "https": scheme = "https"
url = f"{scheme}://{host}{path}"
# curl flags
curl = ["curl", f"-X {method}", f"'{url}'"]
for k, v in [("User-Agent","-A"),("Cookie","-b"),("Authorization","-H")]:
    if k in headers and k != "Host":
        if k == "User-Agent": curl.append(f"-A '{v}'")
        elif k == "Cookie": curl.append(f"-b '{v}'")
        else: curl.append(f"-H '{k}: {v}'")
# remaining headers
for k, v in headers.items():
    if k in ("Host","User-Agent","Cookie","Content-Length"): continue
    curl.append(f"-H '{k}: {v}'")
if body:
    curl.append(f"--data-raw '{body}'")
# python snippet
py = f"""import requests
url = "{url}"
{("headers = " + headers and f"headers = {headers!r}" if headers and "User-Agent" not in headers else "")}
"""
pylines = [f'import requests', f'url = "{url}"']
hdr = {k: v for k, v in headers.items() if k != "Host"}
if hdr: pylines.append(f"headers = {hdr!r}")
if body: pylines.append(f"data = {body!r}")
pylines.append(f"r = requests.request('{method.lower()}', url{' , headers=headers' if hdr else ''}{', data=data' if body else ''})")
pylines.append("print(r.status_code, r.text[:500])")
out = "\n".join(curl)
print("=== curl PoC ==="); print(out)
print("\n=== python PoC ==="); print("\n".join(pylines))
ts = datetime.datetime.now().isoformat(timespec="seconds")
print(f"\n=== summary ===", )
print(f"method: {method}  url: {url}")
print(f"captured-src: {sys.argv[1]}  at: {ts}")
PY
}

shot() {
  local url="${1:?usage: hb-proxy.sh shot <url> <name>}"
  local name="${2:-shot}"
  command -v python3 >/dev/null || { echo "python3 needed" >&2; exit 1; }
  python3 - "$url" "$name" "$PORT" <<'PY'
import subprocess, sys, os
url, name, port = sys.argv[1], sys.argv[2], int(sys.argv[3])
base = os.path.expanduser("~/huntbuddy/engagements/.active")
act = ""
if os.path.isfile(base):
    act = open(base).read().strip()
ev = os.path.expanduser(f"~/huntbuddy/engagements/{act}/evidence/shots" if act else "~/.huntbuddy/evidence/shots")
os.makedirs(ev, exist_ok=True)
out = os.path.join(ev, f"{name}.png")
chrome = next((c for c in ("/usr/bin/chromium","/usr/bin/chromium-browser","/usr/bin/google-chrome") if os.path.exists(c)), None)
try:
    from playwright.sync_api import sync_playwright
    if chrome is None:
        print("no chromium found — install one (privileged apt) or pip playwright + chromium"); sys.exit(2)
except Exception as e:
    print("playwright not installed — pip3 install --user --break-system-packages playwright"); sys.exit(2)
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=chrome, args=["--no-sandbox"])
    ctx = b.new_context(proxy={"server": f"http://127.0.0.1:{port}"}, ignore_https_errors=True)
    pg = ctx.new_page()
    pg.goto(url, wait_until="load", timeout=30000)
    pg.screenshot(path=out, full_page=True)
    b.close()
print(f"screenshot: {out}")
PY
}

cmd="${1:-}"
case "$cmd" in
  detect) detect ;;
  start) start ;;
  stop) stop ;;
  status) status ;;
  poc) shift; poc "$@" ;;
  shot) shift; shot "$@" ;;
  har|help|-h|--help) usage ;;
  *) usage; exit 2 ;;
esac