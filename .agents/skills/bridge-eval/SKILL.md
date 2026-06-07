---
name: Bridge Eval
description: Generate evaluation pack - test scenarios, E2E tests, feedback template. Invoke with $bridge-eval in your prompt.
---

Generate evaluation pack for features that passed the gate. Switch to evaluate mode, following `.agents/procedures/bridge-eval-generate.md`.

Automation-first requirement: when scenarios include steps the human would otherwise run by copying shell/API/file-inspection/browser-automation commands, script those automatable checks into `tests/slices/<slice>-eval.sh` as the actual user-facing scenario commands (run via `make eval`). It MUST NOT merely re-run the project test framework — that is verify/smoke's job. Leave only human-only checks as manual: subjective UX, external-account, live-credential, or exploratory "does this feel right" checks.

Your response MUST end with a HUMAN: block. The eval-generate procedure specifies one — include it verbatim. Never present eval results without a HUMAN: block.
