---
description: "Run the quality gate — Self-audit on your own work, or Independent gate on a submission"
---

Run the quality gate. Use the bridge-auditor subagent; it follows the bridge-gate-audit skill, which decides the mode in its Step 0 and the scope in its Step 1 — do not pre-select either here.

- **Self-audit** (the author checking their own in-progress work, in their own tree) covers features in "in-progress" and "review", writes docs/reviews/{slice-range}-self-audit.md, and changes nothing in docs/context.json.
- **Independent gate** (judging a submission) covers features in "review", runs from a scratch worktree at the submitted revision, and writes docs/reviews/{slice-range}-gate-report.md plus the gate_history entry.

If the operator names a slice or feature, that naming wins over both scopes.

Automation-first requirement (Independent gate mode only — Self-audit never writes a gate fence): if the gate asks the human to run manual verification steps that are automatable by shell/API/file-inspection/browser automation, append them into the GATE-owned `gate (managed)` fenced block of `tests/slices/<slice>-verify.sh` / `tests/slices/<slice>-smoke.sh` (rewriting in place, never writing `tests/e2e/<slice>-manual-automation.sh`), run them when feasible, and cite them in the gate report. Leave only human-only checks as manual: subjective UX, external-account, live-credential, or exploratory "does this feel right" checks.

After the subagent completes, present its HUMAN: block to the user verbatim. If the subagent omitted a HUMAN: block, compose one yourself with verification steps and next actions. Never summarize subagent results without ending your response with a HUMAN: block.
