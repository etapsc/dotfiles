---
name: Bridge Gate
description: Run quality gate audit on features in review status. Invoke with $bridge-gate in your prompt.
---

Run quality gate. Switch to audit mode to audit all features currently in "review" status. Follow `.agents/procedures/bridge-gate-audit.md` to produce docs/gates-evals/{slice-range}-gate-report.md.

Automation-first requirement: if the gate asks the human to run manual verification steps that are automatable by shell/API/file-inspection/browser automation, append them into the GATE-owned `gate (managed)` fenced block of `tests/slices/<slice>-verify.sh` / `tests/slices/<slice>-smoke.sh` (rewriting in place, never writing `tests/e2e/<slice>-manual-automation.sh`), run them when feasible, and cite them in the gate report. Leave only human-only checks as manual: subjective UX, external-account, live-credential, or exploratory "does this feel right" checks.

Your response MUST end with a HUMAN: block. The gate-audit procedure specifies one — include it verbatim. Never present gate results without a HUMAN: block.
