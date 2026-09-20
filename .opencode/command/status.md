---
description: Compact status of the active engagement world (scope, phase, findings, creds, flags, next steps).
---
Give a compact status of the current engagement world. Run `~/huntbuddy/tools/helpers/hb-state.sh get <name>` and present:

- name, platform, status, current phase
- in-scope targets (and anything out-of-scope declared)
- host/service summary
- findings summary (total + confirmed / suspected / invalid counts, top severities)
- credentials captured (summarised — never paste secrets into third-party services)
- flags collected
- next steps (top 3)

If no engagement is active, say so and offer to open one (`/scope new <name> ...`). Never incorporate findings or context from any other engagement world into this view unless the operator asked to cross-reference it.

$ARGUMENTS