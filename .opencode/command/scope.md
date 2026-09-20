---
description: Engagement separation & scope — show, create, or switch the active engagement world.
---
Resolve the current engagement world (one world per engagement, never mix).

- No arguments: show the active engagement card with `hb-state.sh get` and list all worlds with `hb-state.sh list`.
- The operator names a clearly NEW, unrelated target/platform/lab (different bug-bounty site, another THM room, HTB box, new client): automatically open a NEW separated engagement:
  `~/huntbuddy/tools/helpers/hb-state.sh new <name> --platform <bugbounty|thm|htb|client|lab|other> [targets...]`
  Announce it as an isolated world, then start clean — carry no findings, creds, notes or assumptions from the previous engagement.
- The operator names an existing engagement: switch the active pointer with `~/huntbuddy/tools/helpers/hb-state.sh active <name>`, then show its card.
- `/scope read <name>`: READ another engagement's context only (never mix it into the current one) when the operator explicitly asks to cross-reference.

In all cases end by stating exactly which world you are now working in, its phase, and its in-scope targets. Put every tool-call for the active world through the authorisation gate:
`~/huntbuddy/tools/helpers/hb-scope.sh <target> <active-engagement>/.hb-scope`

$ARGUMENTS