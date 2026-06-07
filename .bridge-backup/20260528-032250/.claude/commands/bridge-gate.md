---
description: "Run quality gate audit on features in review status"
---

Run quality gate. Use the bridge-auditor subagent to audit all features currently in "review" or "testing" status. The auditor will use the bridge-gate-audit skill and produce docs/gates-evals/{slice-range}-gate-report.md.

Automation-first requirement: if the gate asks the human to run manual verification steps that are automatable by shell/API/file-inspection/browser automation, create or update an executable script under `tests/e2e/`, run it when feasible, and cite it in the gate report. Leave only human-only checks as manual: subjective UX, external-account, live-credential, or exploratory "does this feel right" checks.

After the subagent completes, present its HUMAN: block to the user verbatim. If the subagent omitted a HUMAN: block, compose one yourself with verification steps and next actions. Never summarize subagent results without ending your response with a HUMAN: block.
