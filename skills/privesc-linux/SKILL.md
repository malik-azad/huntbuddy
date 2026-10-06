---
name: privesc-linux
description: Linux privesc checker - systematic, quiet. SUID/SGID, sudo rights, capabilities, cron, world-writable scripts/libs, kernel, PATH hijack, password reuse. Triggers - linux low-priv shell, privesc, escalate on linux.
tags: [post_exploit, exploitation]
---

# Linux Privilege Escalation (methodical)

## 0. Know where you stand (all in one breath)
```bash
id; uname -a; cat /etc/os-release; sudo -l 2>/dev/null; ip a | grep 'inet '; ps aux | grep -v '\['
```
Synthesize: user/uid/groups, kernel, sudo rights, listening ports, running services.

## 1. LinPEAS or the manual order
If `linpeas.sh` runs: collect, don't trust blind. Always double-check its top hits by hand.

Manual order (highest value first, lowest noise):
1. **sudo -l** — password-less entries, `NOPASSWD`, wildcards, `sudo -u #-1` if present. Check `env_keep` for LD_PRELOAD/LD_LIBRARY_PATH attack.
2. **SUID / SGID** — `find / -perm -4000 -o -perm -2000 2>/dev/null | grep -vE '/(usr)?/bin|/bin/'`. Known escalators: `gtar/tar`, `python`, `perl`, `find`, `vi/vim`, `less/more`, `pkexec` (<CVE-2021-4034), `screen`, `sudo` (CVE-2019-14287), `crontab`.
3. **Capabilities** — `getcap -r / 2>/dev/null | grep -v '/usr/bin'`. `cap_setuid`/`cap_setgid` on binaries → trivial root.
4. **Cron / scheduled** — `crontab -l; ls -la /etc/cron*; systemctl list-timers`. World-writable scripts/binaries executed by root → replace with reverse shell or `echo` payload. Check PATH the cron uses (`/usr/local/bin` writable?).
5. **World-writable files / scripts** — `find / -writable -not -user \`whoami\` -not -path '/proc/*' -not -path '/sys/*' -not -path '/run/*' 2>/dev/null`. Config files, scripts in `PATH`, `/etc/passwd` if writable.
6. **Kernel exploits** — only after user-space paths are exhausted and the kernel is actually old (e.g., <4.4 dirtycow, <5.11 on overlayfs, CVE-2023-2640 on ~5.4). Kernel exploits are loud and crash-prone: prefer config/sudo paths.
7. **Shared libs / LD_PRELOAD** — root scripts calling `ldconfig`/custom binaries → build malicious `.so`.
8. **Logs/config secrets** — `.bash_history`, `/home/*/.ssh`, config files with passwords (`/etc/mysql/debian.cnf`, wp-config.php, service tokens), `/tmp` scripts, env vars, `dmesg` leaks.
9. **Password reuse / hashes** — grep configs for reused creds; dump hashes (`/etc/shadow` if readable) and crack offline; reuse creds into SSH sudo (common !).

## 2. Try-it-after-each: light touch wins
Prefer: sudo tricks → SUID/cap tricks → cron binding → writable-path hijack → kernel LAST.
Each escalation MUST be proven: `id` showing new user, or `whoami` → root. Record the exact chain in state for the report.

## 3. Don't for get
- Copy any `/etc/passwd`+`/etc/shadow` combo before `/etc/passwd` writes.
- `find / -perm -4000 2>/dev/null` covers more than `ls -la / -R`.
- Interrogate `/proc/<pid>/environ` and `/proc/<pid>/cmdline` for interesting daemons.