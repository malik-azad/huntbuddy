---
description: Show or change the current engagement phase (recon, enumeration, vuln_assess, exploitation, post_exploit, reporting).
---
Manage the phase of the active engagement. Valid phases: recon, enumeration, vuln_assess, exploitation, post_exploit, reporting.

- No arguments (or `/phase status`): show the current phase and progress via `~/huntbuddy/tools/helpers/hb-state.sh get <name>`.
- `/phase next`: advance to the next phase in the list above and log it.
- `/phase <name>`: set the phase explicitly (e.g. `/phase exploitation`). Use `~/huntbuddy/tools/helpers/hb-state.sh set <name> phase '"<phase>"'` and also append a `log` entry: `~/huntbuddy/tools/helpers/hb-state.sh add <name> log '{"what":"phase -> <phase>","who":"hunter"}'`.

Always confirm the new phase and how many findings/creds/flags the world now holds before continuing work.

$ARGUMENTS