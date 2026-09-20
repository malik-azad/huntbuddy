---
description: Re-test every suspected finding and separate confirmed from invalid before reporting.
---
Run the false-positive verification sweep per the verify-proof skill: list every finding currently marked 'suspected' in the active engagement's state.json (via `~/huntbuddy/tools/helpers/hb-state.sh get <name>`), and for each one (1) reproduce it, (2) cross-check with an independent angle, (3) run a benign control. Mark each as confirmed, suspected, or invalid in state (`hb-state.sh set <name> findings '[...]'`). Then show a table of results with evidence, and list which findings are now safe to include in the report.

$ARGUMENTS