---
name: Bridge Gate Audit
description: Run quality gate checks and produce structured gate report. Use when features are in review status and need quality validation before evaluation.
---

# Quality Gate Audit

## Step 1: Identify Scope
Load features with status "review" from docs/context.json.
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
- For every automatable step, APPEND executable coverage into the GATE-owned fenced block of the per-slice scripts `tests/slices/<slice>-verify.sh` (static/build/lint checks) and `tests/slices/<slice>-smoke.sh` (behavioral checks), where `<slice>` is the literal slice id. Use these EXACT markers (emit verbatim):

  ```
  # >>> BRIDGE slice <slice> gate (managed) >>>
  …gate automatable checks…
  # <<< BRIDGE slice <slice> gate (managed) <<<
  ```

  - Do NOT create or write `tests/e2e/<slice>-manual-automation.sh`. The gate writes ONLY into its own gate-owned fence; the producer (Code/Debug mode) owns the DISTINCT `producer (managed)` fence in the same files — never touch the producer block, the header, or the trailer.
  - If a per-slice file does not yet exist, create it from the skeleton in `.bridge/fence-template.txt`, then fill the gate block. If it exists but lacks the gate markers, insert the gate fence once (immediately after the producer block), then fill it. On re-run, rewrite ONLY the lines between your gate markers in place — never duplicate the block or its commands.
  - Wrap each check with `bridge_run "<label>" <cmd...>` from `.bridge/lib/runner-lib.sh` so `bridge_summary` aggregates pass/fail.
- Human-only checks (subjective UX, external accounts, live credentials, exploratory product feel) STAY as prose in `docs/gates-evals/{slice-range}-gate-report.md`; do NOT script them.
- Run the automation when feasible (`bash tests/slices/<slice>-verify.sh`, `bash tests/slices/<slice>-smoke.sh`, or `make test-slice SLICE=<slice>`) and cite the command/result in the gate report.
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
| Manual Area | Gate-Fence Script / Command (tests/slices/<slice>-*.sh) | Human-Only Remainder | Status |
|-------------|---------------------------------------------------------|----------------------|--------|

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
- PASS → "GATE PASSED ✓ - ready for evaluation ($bridge-eval)."
- FAIL → "GATE FAILED ✗ - [N] blocking issues." + task list + "Re-run $bridge-gate after fixes."

## Step 9: Human Handoff (required)

The gate has ALREADY executed every configured check and recorded the outcomes in the report. The HUMAN block is for the operator to spot-check, not to re-run the audit. Keep it to these four lines verbatim — do NOT add command re-runs, "verify these results yourself" lists, status-promotion steps (review→done flips), or "was this gate legitimate?" questions. Those belong in the report's **Warnings** / **Recommended Actions** sections, not the HUMAN block. If a finding needs an operator decision, surface it as ONE line under "Decision required" inside the report and reference it here, not as a new numbered step.

```
HUMAN:
1. Review docs/gates-evals/{slice-range}-gate-report.md — do the cited file:line evidence rows match? (Re-run any command yourself only if you suspect environment drift.)
2. Manually check only the human-only scenarios listed in the report (subjective UX, external accounts, live credentials).
3. [If PASS] Run: $bridge-eval
4. [If FAIL] Confirm the blocking issues, then feed fix instructions back.
```
