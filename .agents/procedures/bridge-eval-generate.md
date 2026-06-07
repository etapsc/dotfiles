---
name: Bridge Eval Generate
description: Generate user test scenarios, E2E tests, and feedback template. Use only after a quality gate has passed.
---

# Evaluation Pack Generation

## Precondition
Verify the most recent docs/gates-evals/{slice-range}-gate-report.md shows PASS. If not, abort and notify.

**Derive the slice range prefix** from the in-scope slices (matching the gate report). Examples: single slice -> `S22`, consecutive range -> `S10-S15`, non-consecutive -> `S10-S12-S15`. Use this prefix for the eval scenarios filename.

## Step 1: Manual Test Scenarios

Treat manual evaluation as the human-only remainder, not as a copy/paste command queue.

For every scenario:
- Classify each step as `automatable` or `human-only`.
- Automatable means a shell command, API call, browser automation, fixture setup, file inspection, or CLI workflow can verify it without subjective judgment.
- Human-only means real UX judgment, visual polish, external accounts, live credentials, exploratory product feel, or "start a browser and decide whether it feels right".
- Script every automatable step into `tests/slices/<slice>-eval.sh` as the **actual user-facing scenario commands** — drive the product the way an operator/user would (invoke the real commands/flows named in each scenario's `### Steps:`) and assert the observable outcome of each step. This file MUST NOT merely re-run the project test framework (`bash test.sh` / the unit suite / the integration suite) — re-running the test framework is verify/smoke's job (`tests/slices/<slice>-{verify,smoke}.sh`, owned by producers + gate). Eval drives the product end-to-end as a user.
- Run the automation when feasible, record the command/result in the eval scenarios file, and pre-check or annotate checklist items that the automation already verified.
- Leave only human-only checks for the operator to perform manually as prose in `docs/gates-evals/{slice-range}-eval-scenarios.md` (which is never removed).

### Writing `tests/slices/<slice>-eval.sh`

`<slice>-eval.sh` is **single-owner** (`bridge-eval-generate` only). It uses the shared per-slice file skeleton plus the `eval (managed)` fence, so re-runs rewrite in place idempotently:

```bash
#!/usr/bin/env bash
set -uo pipefail
# BRIDGE per-slice eval script for <slice>. Managed in a fenced block.
# Owner: bridge-eval-generate. Re-runs rewrite the eval block in place.
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source .bridge/lib/runner-lib.sh

# >>> BRIDGE slice <slice> eval (managed) >>>
# (filled by eval-generate with real user-facing scenario commands)
# <<< BRIDGE slice <slice> eval (managed) <<<

bridge_summary
```

- If the file is absent → create it from this skeleton, then fill the eval block.
- If present with the eval markers → rewrite ONLY the lines between the markers; leave the header/trailer byte-for-byte unchanged. Never append a duplicate block; never duplicate commands.
- Wrap each scenario command with `bridge_run "<label>" <cmd...>` so `bridge_summary` aggregates pass/fail and returns non-zero on any failure.
- Run it via `bash tests/slices/<slice>-eval.sh`, `make eval` (runs all `*-eval.sh` via `tests/run-eval.sh`), or `make test-slice SLICE=<slice>`.

Create docs/gates-evals/{slice-range}-eval-scenarios.md:

```markdown
# Evaluation Scenarios
Generated: [timestamp]
Project: dotfiles

## How to Use
1. Set up application (see README)
2. Run the automation first: `make eval` (or `bash tests/slices/<slice>-eval.sh`)
3. Execute only the human-only scenario steps manually
4. Record results in checklists
5. Fill feedback form at bottom

## Automation Coverage
- Script/command: tests/slices/<slice>-eval.sh (run via `make eval` / `make test-slice SLICE=<slice>`)
- Covers: [scenario/checklist items]
- Human-only remainder: [items that cannot be automated]

---

## Scenario N: [Feature Fxx] - [Happy Path / Edge Cases / Cross-Feature]
**Goal:** [what user accomplishes]
**Preconditions:** [setup]
**Linked:** [Fxx, ATxx, UFxx]

### Steps:
1. [Action] → Expected: [result]

### Checklist:
- [ ] Step N works as expected
- [ ] Automatable checks are covered by [script/command]
- [ ] Human-only checks are completed manually

---

## Feedback Form

### Overall Assessment
- [ ] Ready for launch  - [ ] Minor fixes  - [ ] Major fixes

### Ratings (1-5): Usability ___ | Performance ___ | Polish ___

### Issues Found
| # | Severity | Feature | Description | Steps to Reproduce |
|---|----------|---------|-------------|-------------------|

### Suggestions
[Free form]

### Would you use this? Why/why not?
[Free form]
```

## Step 2: User-Facing Scenario Commands
- Write `tests/slices/<slice>-eval.sh` (skeleton + `eval (managed)` fence, above), scripting every automatable scenario step as a **real product invocation** — the commands/flows an operator/user would actually run — and asserting the observable outcome.
- It MUST NOT merely re-run the project test framework (`bash test.sh` / unit / integration); that is verify/smoke's job. Eval drives the product as a user.
- Map to e2e_critical_paths from quality_gates
- Happy path + key edge cases per feature
- Cover every automatable eval scenario step; do not leave copy/paste shell/API/file-inspection steps in the manual-only instructions

## Step 3: Update Context
Append to eval_history in docs/context.json:
```json
{ "date": "[timestamp]", "scenarios_generated": 0, "e2e_tests_generated": 0, "automation_script": "tests/slices/<slice>-eval.sh", "awaiting_feedback": true }
```

## Step 4: Output
```
EVALUATION PACK GENERATED ✓
Created: docs/gates-evals/{slice-range}-eval-scenarios.md ([X] scenarios), tests/slices/<slice>-eval.sh ([Y] scenario commands)

HUMAN:
1. Run automated eval coverage yourself: `make eval` (or `bash tests/slices/<slice>-eval.sh`)
2. Walk through only the human-only items in docs/gates-evals/{slice-range}-eval-scenarios.md — do not repeat checks already covered by automation unless you want a spot check
3. Actually use the application as a real user would for each human-only scenario
4. Fill in the feedback form at the bottom of docs/gates-evals/{slice-range}-eval-scenarios.md
5. Note any DX friction, performance issues, or "this feels wrong" moments
6. Paste your filled feedback into: $bridge-feedback [your feedback]

Estimated evaluation time: [X] minutes
```
