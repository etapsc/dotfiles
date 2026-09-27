---
name: "source-command-bridge-gate"
description: "Run quality gate audit on features in review status"
---

# source-command-bridge-gate

Use this skill when the user asks to run the migrated source command `bridge-gate`.

## Command Template

Run quality gate. Use the bridge-auditor subagent to audit all features currently in "review" or "testing" status. The auditor will use the bridge-gate-audit skill and produce docs/gates-evals/{slice-range}-gate-report.md.

Automation-first requirement: if the gate asks the human to run manual verification steps that are automatable by shell/API/file-inspection/browser automation, append them into the GATE-owned `gate (managed)` fenced block of `tests/slices/<slice>-verify.sh` / `tests/slices/<slice>-smoke.sh` (rewriting in place, never writing `tests/e2e/<slice>-manual-automation.sh`), run them when feasible, and cite them in the gate report. Leave only human-only checks as manual: subjective UX, external-account, live-credential, or exploratory "does this feel right" checks.

After the subagent completes, present its HUMAN: block to the user verbatim. If the subagent omitted a HUMAN: block, compose one yourself with verification steps and next actions. Never summarize subagent results without ending your response with a HUMAN: block.
