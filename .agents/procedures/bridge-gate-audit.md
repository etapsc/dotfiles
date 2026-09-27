---
name: Bridge Gate Audit
description: Run quality gate checks and produce structured gate report. Use when features are in review status and need quality validation before evaluation.
---

# Quality Gate Audit

## Step 0: Select Mode (content-driven)

This body serves two different acts in the loop. They are not the same check and
must not be confused for one another. State the selected mode at the top of your
output.

- **Self-audit** — run by whoever did the work, in their own working tree, before
  asking for review. Purpose: catch what you can before spending someone else's
  attention. **This is not the gate.** It cannot satisfy the independent-gate step
  and it never moves a feature's status.
- **Independent gate** — run to decide whether the submission passes. Purpose:
  verify a specific revision on someone else's behalf.

Pick Self-audit when the person invoking this also produced the work and is still
in the tree where it happened. Pick Independent gate when a submission is being
judged. If it is ambiguous, it is a Self-audit.

### Self-audit mode

Run the checks below wherever you are. No worktree, no clean-tree requirement,
no harness requirement — the point is speed and honesty with yourself. Write the
findings to `docs/reviews/{slice-range}-self-audit.md`, opening with:

```
SELF-AUDIT — not a gate. Run by the author, in the working tree, at <sha><-dirty>.
```

Do not write `docs/reviews/{slice-range}-gate-report.md` in this mode, and do not
change `feature_status`. Skip Step 5 (gate-fence authoring) — that block belongs
to the independent gate.

### Independent gate mode

A gate is defined by where it runs and who runs it, not by the command name.
Before checking anything:

1. **Work from a scratch checkout at the submitted revision**, never the tree the
   work happened in:
   ```bash
   git worktree add .claude/worktrees/gate-<slice-range> <revision>
   ```
   `.claude/worktrees/` is gitignored. Run every check from there. Auditing a
   dirty working tree audits work in progress, not the submission.

   **Preserve every output before you clean up.** The report, the context
   updates and the gate fences are all written inside the worktree, which makes
   it dirty — `git worktree remove` fails with exit 128, and forcing it destroys
   the only copy. The gate produces four artifacts; copy or port all four, verify
   the transfer, then clean tracked *and* untracked state:

   ```bash
   W=.claude/worktrees/gate-<slice-range>

   # 1. the report
   cp "$W/docs/reviews/<slice-range>-gate-report.md" docs/reviews/

   # 2. the gate_history entry  — port by hand into the main docs/context.json
   # 3. the ATxx evidence records — port by hand into the main docs/context.json
   #    (both live in the worktree's copy; diff it to see what you added)
   git -C "$W" diff -- docs/context.json

   # 4. the gate-owned fenced blocks in tests/slices/<slice>-{verify,smoke}.sh
   git -C "$W" diff -- tests/slices/

   # verify the transfer BEFORE destroying anything
   diff "$W/docs/reviews/<slice-range>-gate-report.md" "docs/reviews/<slice-range>-gate-report.md"
   git diff --stat -- docs/context.json tests/slices/    # your ported changes, in the main checkout

   # only now: reset tracked files AND remove untracked ones, or removal still fails
   git -C "$W" checkout -- .
   git -C "$W" clean -fd
   git worktree remove "$W"
   ```

   `checkout -- .` alone is not enough: the report is a *new* file, so it stays
   untracked and the worktree stays dirty. Never `--force` a removal you have not
   copied out of and verified first.
2. **Record the revision you actually gated** — the full commit SHA and whether
   that checkout was clean — in the report header and in every evidence record
   you write. A symbolic ref like `HEAD` does not identify anything later.
3. **A different harness or model than the one that implemented.** Reviewing an
   Opus-written slice with Codex catches what re-reading it in the same session
   does not.
4. **Re-run the evidence. Do not read the summary.** A gate report with no
   independent re-runs is not a gate report.

Open the report with a provenance block naming what this run actually had:

```
GATE — revision <full sha>, checkout <clean|DIRTY>, harness <name/model>,
        implemented by <name/model>, independence: <mechanical|PARTIAL: ...>
```

**Solo operation.** With one person holding every role, properties 1, 2 and 4
still hold in full — they are mechanical. Property 3 holds only if you gate with a
different harness or model than you built with; when you cannot, write
`independence: PARTIAL: same model as implementation` and say so in the findings.
A gate that overstates its own independence is worse than one that admits it.
Never silently skip a property: name it.

Gate results describe the audited scope and revision, not acceptance or release
state. Consult the latest scoped decision before summarizing current delivery.
Keep non-blocking warnings non-blocking; do not reopen an accepted feature based
only on a warning or deferred live feedback. Preserve acceptance while recording
new findings; any reopening belongs to the operator-directed feedback/fix flow.

## Step 1: Identify Scope

Scope depends on the mode selected in Step 0.

- **Independent gate** — features with status `review` in `docs/context.json`.
  That status is the submission; nothing else is being judged.
- **Self-audit** — the work in hand: features with status `in-progress` **and**
  `review`. A developer auditing before they ask for review has not set `review`
  yet, so scoping to `review` alone would examine nothing they are working on.
  If the operator names a slice or feature, that naming wins over both.

If the selected scope is empty, say so and stop; do not silently widen it.

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
4. Record what you re-ran, **to the destination the mode allows**:
   - **Independent gate** — the top-level `evidence` map in `docs/context.json`.
   - **Self-audit** — an Evidence section inside
     `docs/reviews/{slice-range}-self-audit.md`, using the same record shape.
     Self-audit never writes `docs/context.json` (Step 7); an evidence record is
     a context write like any other.

   Two classes and nothing else:
   - `executable` — `{"class":"executable","command":…,"exit_code":…,"revision":…,"dirty":…,"at":…}`
   - `manual-observation` — `{"class":"manual-observation","observer":…,"procedure":…,"revision":…,"observed":…}`

   Write a record only for a run you actually observed. An executable acceptance
   test carrying a narrative record is a gap, not evidence. Evidence left in prose
   inside a `slice_history` note does not count — a reviewer cannot find it.

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
- Human-only checks (subjective UX, external accounts, live credentials, exploratory product feel) STAY as prose in `docs/reviews/{slice-range}-gate-report.md`; do NOT script them.
- Run the automation when feasible (`bash tests/slices/<slice>-verify.sh`, `bash tests/slices/<slice>-smoke.sh`, or `make test-slice SLICE=<slice>`) and cite the command/result in the gate report.
- Do not leave the operator with a long copy/paste command list when those commands can be scripted.

## Step 6: Generate the report

Self-audit mode writes `docs/reviews/{slice-range}-self-audit.md` with the
SELF-AUDIT header from Step 0. Independent gate mode writes
`docs/reviews/{slice-range}-gate-report.md` with the GATE provenance block.
The structure below is the same for both.

### docs/reviews/{slice-range}-gate-report.md

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

## Step 7: Update Context — Independent gate mode ONLY

**Self-audit mode writes nothing to `docs/context.json`.** No `gate_history`
entry, no status change, no evidence record. A self-audit is a private check; it
has no standing to record a result that other repos and future sessions will
read. Skip to Step 8.

Independent gate mode appends to `gate_history` in `docs/context.json`:
```json
{ "date": "[timestamp]", "revision": "[full sha gated]", "clean_checkout": true, "harness": "[name/model]", "independence": "mechanical|PARTIAL: [why]", "result": "pass|fail", "features": ["Fxx"], "blocking_issues": 0, "warnings": 0, "coverage": "X%" }
```

## Step 8: Decision

The verdict wording is mode-specific. Self-audit must never emit a gate verdict —
"GATE PASSED" from a self-audit is a false claim of a review that did not happen.

**Self-audit mode:**
- clean → "SELF-AUDIT CLEAN - no blocking findings. This is not a gate; the slice
  still needs an independent gate before it can be accepted."
- findings → "SELF-AUDIT FOUND [N] issue(s)." + the list. Fix them, then re-run.

Never say PASSED or FAILED, never direct the operator to `$bridge-eval`, and
never suggest promoting a status.

**Independent gate mode:**
- PASS → "GATE PASSED ✓ - ready for evaluation ($bridge-eval)."
- FAIL → "GATE FAILED ✗ - [N] blocking issues." + task list + "Re-run $bridge-gate after fixes."

## Step 9: Human Handoff (required)

The gate has ALREADY executed every configured check and recorded the outcomes in the report. The HUMAN block is for the operator to spot-check, not to re-run the audit. Keep it to these four lines verbatim — do NOT add command re-runs, "verify these results yourself" lists, status-promotion steps (review→done flips), or "was this gate legitimate?" questions. Those belong in the report's **Warnings** / **Recommended Actions** sections, not the HUMAN block. If a finding needs an operator decision, surface it as ONE line under "Decision required" inside the report and reference it here, not as a new numbered step.

**Self-audit mode** closes with:

```
HUMAN:
1. Read docs/reviews/{slice-range}-self-audit.md — a self-check by the author, not a gate.
2. [If findings] Confirm the list, then feed fix instructions back.
3. [If clean] Decide whether this slice is ready to request an independent gate.
```

**Independent gate mode** closes with:

```
HUMAN:
1. Review docs/reviews/{slice-range}-gate-report.md — do the cited file:line evidence rows match? (Re-run any command yourself only if you suspect environment drift.)
2. Check the provenance block: is the revision, checkout state and independence verdict what you expected?
3. Manually check only the human-only scenarios listed in the report (subjective UX, external accounts, live credentials).
4. [If PASS] Run: $bridge-eval
5. [If FAIL] Confirm the blocking issues, then feed fix instructions back.
```
