---
name: Bridge Gate Audit
description: Run quality gate checks and produce structured gate report. Use when features are in review/testing status and need quality validation before evaluation.
user-invocable: false
context: fork
agent: bridge-auditor
---

# Quality Gate Audit

## Step 1: Identify Scope
Load features with status "review" or "testing" from docs/context.json.
Load quality_gates thresholds from docs/requirements.json.

**Derive the slice range prefix** from the in-scope slices for use in the gate report filename. Examples: single slice -> `S22`, consecutive range -> `S10-S15`, non-consecutive -> `S10-S12-S15`. Use this prefix for the gate report filename in Step 5.

## Step 2: Run Checks

Execute using commands_to_run from context.json:
```bash
[commands_to_run.test] 2>&1 || true
[commands_to_run.lint] 2>&1 || true
[commands_to_run.typecheck] 2>&1 || true
[stack-appropriate security scan] 2>&1 || true
[build command if applicable] 2>&1 || true
```

If a command is missing, attempt stack convention and note the gap.

## Step 3: Evaluate
Per check: PASS (meets threshold) | FAIL (blocking) | WARN (non-blocking)

## Step 4: Verify Acceptance Criteria
For each in-scope feature:
1. Load acceptance_tests (ATxx)
2. Locate executable evidence
3. Mark verified or gap

## Step 5: Automatable Manual Verification
Before writing the report, inspect any manual verification instructions you are about to hand to the operator, including `docs/human-playbook.md`, existing eval scenarios, acceptance-test notes, and the final HUMAN block.

- Classify each manual step as `automatable` or `human-only`.
- Automatable means a shell command, API call, browser automation, fixture setup, file inspection, or CLI workflow can verify it without subjective judgment.
- Human-only means real UX judgment, visual polish, external accounts, live credentials, exploratory product feel, or "start a browser and decide whether it feels right".
- For every automatable step, create or update executable coverage under `tests/e2e/` using the project test framework when available; otherwise create/update `tests/e2e/{slice-range}-manual-automation.sh`.
- Run the automation when feasible and cite the command/result in the gate report.
- Do not leave the operator with a long copy/paste command list when those commands can be scripted.

## Step 6: Generate docs/gates-evals/{slice-range}-gate-report.md

```markdown
# Gate Report
Generated: [timestamp]
Features Audited: [Fxx list]

## Summary
**OVERALL: [PASS | FAIL]**

## Test Results
- Unit: [X passed, Y failed] - Coverage: [Z%] (threshold: [T%]) - [PASS/FAIL]
- Integration: [status]

## Code Quality
- Lint Errors: [count] - [PASS/FAIL]
- Type Errors: [count] - [PASS/FAIL]

## Security
- Vulnerabilities: [high/mod/low] - [PASS/FAIL/WARN]

## Acceptance Test Evidence
| Feature | AT ID | Criterion | Evidence | Status |
|---------|-------|-----------|----------|--------|

## Automation Coverage
| Manual Area | Automation Script / Command | Human-Only Remainder | Status |
|-------------|-----------------------------|----------------------|--------|

## Blocking Issues
1. [Issue + file:line]

## Warnings
1. [Warning]

## Recommended Actions
1. [Specific fix]
```

## Step 7: Update Context
Append to gate_history in docs/context.json:
```json
{ "date": "[timestamp]", "result": "pass|fail", "features": ["Fxx"], "blocking_issues": 0, "warnings": 0, "coverage": "X%" }
```

## Step 8: Decision
- PASS → "GATE PASSED ✓ - ready for evaluation (/bridge-eval)."
- FAIL → "GATE FAILED ✗ - [N] blocking issues." + task list + "Re-run /bridge-gate after fixes."

## Step 9: Human Handoff (required)

```
HUMAN:
1. Verify these results yourself — run: [exact test/lint/typecheck commands]
2. Run the generated automation script for any automatable manual checks: [tests/e2e/{slice-range}-manual-automation.sh or equivalent]
3. Inspect docs/gates-evals/{slice-range}-gate-report.md — do the results match what you see?
4. Manually check only the human-only scenarios listed in the report
5. [If PASS] Run: /bridge-eval
6. [If FAIL] Confirm blocking issues, then feed fix instructions back
```
