---
name: Bridge Gate
description: Run the quality gate — Self-audit mode on your own work, or Independent gate mode on a submission. Invoke with $bridge-gate in your prompt.
---

Run the quality gate. `.agents/procedures/bridge-gate-audit.md` decides the mode in its Step 0 and the scope in its Step 1 — do not pre-select either here.

- **Self-audit** (the author checking their own in-progress work, in their own tree) covers features in `in-progress` and `review`, writes `docs/reviews/{slice-range}-self-audit.md`, and changes nothing in `docs/context.json`.
- **Independent gate** (judging a submission) covers features in `review`, runs from a scratch worktree at the submitted revision, and writes `docs/reviews/{slice-range}-gate-report.md` plus the `gate_history` entry.

If the operator names a slice or feature, that naming wins over both scopes.

Automation-first requirement (Independent gate mode only — Self-audit never writes a gate fence): if the gate asks the human to run manual verification steps that are automatable by shell/API/file-inspection/browser automation, append them into the GATE-owned `gate (managed)` fenced block of `tests/slices/<slice>-verify.sh` / `tests/slices/<slice>-smoke.sh` (rewriting in place, never writing `tests/e2e/<slice>-manual-automation.sh`), run them when feasible, and cite them in the gate report. Leave only human-only checks as manual: subjective UX, external-account, live-credential, or exploratory "does this feel right" checks.

Your response MUST end with a HUMAN: block. The gate-audit procedure specifies one — include it verbatim. Never present gate results without a HUMAN: block.
