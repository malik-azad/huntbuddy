#!/usr/bin/env bash
# make-dist.sh — build a single-file, self-contained Huntbuddy installer.
# Produces dist/huntbuddy-install.sh (works on any Linux/macOS laptop) plus
# dist/huntbuddy-bundle.tar.xz (raw payload, for scp/api deployments).
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$SRC/dist"
MARKER='#__HBDATA_B64__'
STG="$(mktemp -d /tmp/hb-dist.XXXXXX)"
trap 'rm -rf "$STG"' EXIT

mkdir -p "$DIST"

# ---- stage the payload (no legacy engine, no user data, no git) -------------
STAGE="$STG/huntbuddy"
rsync -a --exclude 'bin/' --exclude 'engagements/' --exclude '.git/' \
  --exclude 'dist/' --exclude '.opencode/node_modules' \
  "$SRC/" "$STAGE/"

# ---- compress payload --------------------------------------------------------
tar -C "$STG" -cJf "$DIST/huntbuddy-bundle.tar.xz" huntbuddy
B64="$STG/payload.b64"
base64 -w 76 "$DIST/huntbuddy-bundle.tar.xz" > "$B64"

# ---- installer body ----------------------------------------------------------
INSTALLER="$STG/installer.sh"
cat > "$INSTALLER" <<'EOF'
#!/usr/bin/env bash
# Huntbuddy — one-command portable installer.
#   bash huntbuddy-install.sh
# Installs the engine (official opencode, if missing), the Huntbuddy folder,
# and the `hunter` command. No API keys. Free opencode Zen brain connects by default.
# Overrides: HUNTBUDDY_HOME (folder dir), HUNTBUDDY_BIN (command dir),
#            HUNTBUDDY_OPENCODE (path to an existing opencode binary).
set -euo pipefail

HB_HOME="${HUNTBUDDY_HOME:-$HOME/huntbuddy}"
HB_BIN="${HUNTBUDDY_BIN:-$HOME/.local/bin}"
HB_ENGINE="${HUNTBUDDY_OPENCODE:-}"
MARKER='#__HBDATA_B64__'

A=$'\033[33m'; G=$'\033[32m'; R=$'\033[0m'

say()  { printf '%s\n' "$*"; }
info() { printf '%s[+]%s %s\n' "$G" "$R" "$*"; }
warn() { printf '%s[!]%s %s\n' "$A" "$R" "$*"; }

[ -n "${BASH_VERSION:-}" ] || { warn "Huntbuddy installer needs bash — run: bash huntbuddy-install.sh"; exit 1; }

if ! command -v tar >/dev/null || ! command -v base64 >/dev/null; then
  warn "Need 'tar' and 'base64' on PATH (standard on Linux/macOS)."; exit 1
fi

OS="$(uname -s)"
case "$OS" in
  Linux|Darwin) ;;
  *) warn "Unsupported OS: $OS"; exit 1 ;;
esac

info "Installing Huntbuddy → $HB_HOME"

if [ -e "$HB_HOME" ]; then
  BAK="$HB_HOME.backup-$(date +%s)"
  warn "Existing folder found — keeping it aside at $BAK"
  mv "$HB_HOME" "$BAK"
fi
mkdir -p "$HB_HOME"

# extract embedded payload (first line after the marker is base64-encoded tar.xz)
LINE="$(grep -n "^${MARKER}$" "$0" | tail -1 | cut -d: -f1)"
[ -n "$LINE" ] || { warn "installer corrupted (no payload)"; exit 1; }
tail -n +$((LINE + 1)) "$0" | base64 -d | tar -xJ -C "$HB_HOME" --strip-components=1
info "Huntbuddy folder installed ($(find "$HB_HOME/skills" "$HB_HOME/playbooks" -name SKILL.md | wc -l | tr -d ' ') skill packs)"

# ---- engine ------------------------------------------------------------------
if [ -n "$HB_ENGINE" ]; then
  [ -x "$HB_ENGINE" ] && OPENCODE="$HB_ENGINE" || { warn "HUNTBUDDY_OPENCODE not executable: $HB_ENGINE"; exit 1; }
elif command -v opencode >/dev/null 2>&1; then
  OPENCODE="$(command -v opencode)"
else
  info "Installing the opencode engine (official)…"
  command -v curl >/dev/null || { warn "Need 'curl' to install the engine — install it and re-run."; exit 1; }
  curl -fsSL https://opencode.ai/install | bash 2>&1 | tail -2 || true
  OPENCODE="$(command -v opencode || true)"
  [ -z "$OPENCODE" ] && OPENCODE="$HOME/.opencode/bin/opencode"
  [ -x "$OPENCODE" ] || { warn "Engine install did not land on PATH. Re-run after shell restart, or set HUNTBUDDY_OPENCODE."; exit 1; }
fi
[ -x "$OPENCODE" ] || { warn "Engine not found at $OPENCODE"; exit 1; }
info "Engine: $OPENCODE ($($OPENCODE --version 2>/dev/null || echo '?' ))"

# ---- hunter command ------------------------------------------------------------
mkdir -p "$HB_BIN"
HUNTER="$HB_BIN/hunter"
####HBWRAPPER####
chmod +x "$HUNTER"
info "Command installed: $HUNTER"

# ---- path ----------------------------------------------------------------------
if ! printf '%s' "$PATH" | tr ':' '\n' | grep -qx "$HB_BIN"; then
  for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$RC" ] || continue
    grep -qE "^export PATH=.*\$HB_BIN|$HB_BIN" "$RC" 2>/dev/null && continue
    printf '\nexport PATH="%s:$PATH"   # huntbuddy\n' "$HB_BIN" >> "$RC"
  done
  info "Added $HB_BIN to PATH in ~/.bashrc / ~/.zshrc (start a new shell to use 'hunter')"
else
  info "$HB_BIN already on PATH"
fi

# ---- verify ---------------------------------------------------------------------
SKILLS="$(find "$HB_HOME/skills" "$HB_HOME/playbooks" -name SKILL.md | wc -l | tr -d ' ')"
cat <<DONE

$A
  ██   ██ ██   ██ ███    ██ ████████ ██████   ██████  ██    ██ ██████  ██    ██
  ██   ██ ██   ██ ████   ██    ██    ██   ██ ██   ██ ██    ██ ██   ██ ██    ██
  ███████ ██   ██ ██ ██  ██    ██    ██   ██ ██   ██ ██    ██ ██   ██ ██    ██
  ██   ██ ██   ██ ██  ██ ██    ██    ██   ██ ██   ██ ██    ██ ██   ██ ██    ██
  ██   ██  █████  ██   ████    ██    ██████   ██████   ██████  ██████   ██████$R

  installed OK
  folder   : $HB_HOME   ($SKILLS skill packs)
  command  : $HUNTER
  engine   : $OPENCODE

  Run it:   hunter
  Try it:   hunter           then type:  ifconfig
  Guide:    hunter --help  |  open $HB_HOME/docs/Huntbuddy-Guide.pdf

  Authorized-lab use only. No refusals for scans of your own targets; everything
  you run is your responsibility.
DONE

exit 0
EOF

# ---- inject the hunter wrapper (single source: tools/hunter-wrapper.sh) -----
python3 - "$INSTALLER" "$SRC/tools/hunter-wrapper.sh" <<'PY'
import sys
tmpl = open(sys.argv[1]).read()
wrp = open(sys.argv[2]).read().rstrip('\n') + '\n'
assert '####HBWRAPPER####' in tmpl, 'marker missing in installer template'
inject = "cat > \"$HUNTER\" <<'HBEOF'\n" + wrp + "HBEOF\n"
out = tmpl.replace('####HBWRAPPER####', inject)
assert out.count("\nHBEOF\n") == 1, 'HBEOF closing line must appear exactly once'
open(sys.argv[1], 'w').write(out)
print('wrapper injected (heredoc terminator verified)')
PY

# ---- assemble the single-file installer ----------------------------------------
{
  cat "$INSTALLER"
  echo "$MARKER"
  cat "$B64"
} > "$DIST/huntbuddy-install.sh"
chmod +x "$DIST/huntbuddy-install.sh"

echo "built:"
ls -la "$DIST/huntbuddy-install.sh" "$DIST/huntbuddy-bundle.tar.xz"
echo "installer payload size: $(wc -c < "$B64") bytes base64"