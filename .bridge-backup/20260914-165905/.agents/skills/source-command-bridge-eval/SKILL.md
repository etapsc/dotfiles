---
name: "source-command-bridge-eval"
description: "Generate evaluation pack - test scenarios, E2E tests, feedback template"
---

# source-command-bridge-eval

Use this skill when the user asks to run the migrated source command `bridge-eval`.

## Command Template

Generate evaluation pack for features that passed the gate. Use the bridge-evaluator subagent, which will follow the bridge-eval-generate skill.

Automation-first requirement: when scenarios include steps the human would otherwise run by copying shell/API/file-inspection/browser-automation commands, script those automatable checks into `tests/slices/<slice>-eval.sh` as the actual user-facing scenario commands (run via `make eval`). It MUST NOT merely re-run the project test framework — that is verify/smoke's job. Leave only human-only checks as manual: subjective UX, external-account, live-credential, or exploratory "does this feel right" checks.

After the subagent completes, present its HUMAN: block to the user verbatim. If the subagent omitted a HUMAN: block, compose one yourself with verification steps and next actions. Never summarize subagent results without ending your response with a HUMAN: block.
