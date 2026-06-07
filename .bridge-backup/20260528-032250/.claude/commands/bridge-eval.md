---
description: "Generate evaluation pack - test scenarios, E2E tests, feedback template"
---

Generate evaluation pack for features that passed the gate. Use the bridge-evaluator subagent, which will follow the bridge-eval-generate skill.

Automation-first requirement: when scenarios include steps the human would otherwise run by copying shell/API/file-inspection/browser-automation commands, create or update an executable test script under `tests/e2e/` for those automatable checks. Leave only human-only checks as manual: subjective UX, external-account, live-credential, or exploratory "does this feel right" checks.

After the subagent completes, present its HUMAN: block to the user verbatim. If the subagent omitted a HUMAN: block, compose one yourself with verification steps and next actions. Never summarize subagent results without ending your response with a HUMAN: block.
