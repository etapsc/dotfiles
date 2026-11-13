---
name: Bridge Slice Plan
description: Plan and execute a thin vertical slice from requirements. Use when starting a new slice, planning implementation tasks, or coordinating the architect→coder→debugger delegation flow.
---

# Slice Planning & Execution

## Planning

1. Select the slice: an explicit selection wins (see Selection below); otherwise the next slice from execution.recommended_slices (or propose smallest viable)
2. Output slice plan:

```
SLICE: [Sxx] - [goal]
FEATURES: [Fxx list]
EXIT CRITERIA: [ATxx list]

TASKS:
1. [task_id] architect: [design/contract work]
   → Inputs: [files/JSON sections]
   → Output: [deliverable]

2. [task_id] code: [implementation]
   → Inputs: [architect output + relevant files]
   → Tests: [ATxx → test description]

3. [task_id] debug: [verification]
   → Run: [commands]
   → Expect: [results]

DEPENDENCIES: [task order]
```

## Selection (one slice or a list)

A start invocation may name a selection: one slice, or a comma-separated list run in written order. Spaces around commas are allowed. Each item is a slice ID or an inclusive span; `S14-15` and `S14-S15` are the same. `S14-15,S17,S19,S20-22` expands to S14, S15, S17, S19, S20, S21, S22. An explicit selection wins over `next_slice`, including for specialist loading.

Validate the whole list before any edit or commit, following `previous_doc` for slices missing from the current requirements. Stop and name the problem for a malformed or empty item, a descending span, a repeated or unknown ID, a slice that is not `planned` or `in-progress` (review-ready work goes to the gate, accepted work needs a scoped reopening, blocked work needs its blocker resolved), or a dependency neither already satisfied nor completed earlier in the list.

**Design cost stop.** A selection whose plan or contract proposes a new executable outside tests/slices/ (a tool, renderer or script), more than 200 lines of new code and tests combined, or a contract over 20 KB is not started until docs/decisions.md carries the cost comparison for it (the architect's table, the proposed design against the simplest alternative, with the chosen row named). The comparison cites the design file it summarizes, under docs/designs/ with the gaps the architect found; a comparison without that file is not enough, so if the architect returned its design only as a message, write that file before asking for the row. Stop before any edit and name it: the HUMAN block names the missing comparison and the decision entry that should carry it, and cites the design file's path. A plan under both thresholds that adds no executable needs no comparison before it starts.

**Report ID:** every run of consecutive expanded slice IDs collapses to its first and last ID joined by a hyphen; separate runs join with an underscore; a single slice is its own ID. `S14` stays `S14`; S75, S76, S77, S78, S79 becomes `S75-S79`; `S14-15,S17,S19,S20-22` becomes `S14-S15_S17_S19-S22`. A hyphen inside a report ID always means an inclusive span and an underscore always means a gap. It is a file name, not a new selection: pass the original comma form back to the gate or eval. The request, gate and eval reports share it; per-slice verify, smoke and eval scripts keep their own slice IDs.

**List run.** A selection of more than one slice, or any `with-relay` start, authorizes local commits and runs without the approval pause in Completion & Feedback Loop:

1. Build each slice in order with the Execution Loop, loading specialists for the slice in hand unless the operator said `no specialists`.
2. Run its checks, record observed AT evidence, update the ledgers and commit that slice's paths. Finished, unaccepted work goes to `review`, never `done`; a feature with unfinished slices later in the list stays `in-progress`.
3. Go on to the next slice with no gate, eval or approval pause. Leave unrelated edits uncommitted.
4. At the end, run every `commands_to_run` entry and each selected slice's verify and smoke scripts on the combined result; fix regressions within scope and commit the fixes. End with one HUMAN block: the commits, the selection, its report ID, the results and the gate command for this selection, unless `with-relay` hands the work to Relay instead.

Stop at the current slice, leaving later slices untouched, for a disputed requirement, a needed scope change, an unmet prerequisite, conflicting edits or a check that cannot be fixed within scope; report the commits so far and what remains. A list run never accepts, pushes, tags or starts the gate itself. A one-slice selection without `with-relay` keeps the approval pause.

## Execution Loop

### Specialist Propagation

Before switching modes, check if specialists were loaded for this slice (from $bridge-start or the SPECIALISTS LOADED block). For each loaded specialist:
- Read the specialist file from `.agents/specialists/<id>.md`
- Apply the guidance sections matching your current mode/role
- Only use guidance for roles listed in the specialist's `applies_to` field

### Mode Delegation

1. Switch to architect mode (if slice needs design) → relevant JSON + file paths; apply specialist guidance for architect role
2. Switch to code mode → implement with tests satisfying ATxx; apply specialist guidance for coder role. Seed this slice's producer-owned scaffolding: `tests/slices/<slice>-verify.sh` + `tests/slices/<slice>-smoke.sh` (PRODUCER fence — see AGENTS.md "Per-Slice Verification Scaffolding").
3. Switch to debug mode → run tests, fix failures; apply specialist guidance for debugger role (if any). Refresh the producer fence in `tests/slices/<slice>-{verify,smoke}.sh` with any regression check (same EXACT producer markers; rewrite in place, no duplication).
4. Verify: ATxx → evidence mapping
5. Update docs/context.json: feature_status, handoff, next_slice

## Completion & Feedback Loop

- Slice is PRESENTED (not "done") when all ATxx have passing evidence
- Output the HUMAN: block above
- Then STOP and WAIT for the user's response (a list run or a `with-relay` start continues as Selection says)

### Classify User Response

**ISSUES REPORTED** (default if ambiguous):
User describes bugs, missing behavior, incorrect behavior, or requests changes.
Indicators: "fix", "bug", "issue", "wrong", "missing", "doesn't work", "investigate", "implement", "however", "but", numbered problem lists.
→ Create numbered fix tasks from feedback. Re-enter the Execution Loop above for the SAME slice (same Sxx). Do NOT update feature status to "review" or "done". Do NOT trigger gate or evaluate. After fixes, output a new HUMAN: block and re-enter this loop.

**APPROVED**:
Explicit approval only: "done", "approved", "PASSED", "looks good", "move on", "next slice", "continue".
→ Update feature status to "review" — this triggers the gate. Do NOT set "done" here: "done" requires a passing gate AND an acceptance record in docs/decisions.md, and it is the approver who writes both. Update docs/context.json: feature_status, handoff, next_slice.

**STOP**:
Explicit stop/pause request.
→ Hand off to session wrap-up.

CRITICAL: Never assume approval. Never update feature status until explicitly approved. If the response contains ANY issue descriptions, treat as ISSUES REPORTED regardless of other content.

## Human Handoff (required)

After completing each slice, output:

```
HUMAN:
1. Verify: [exact test/lint/build commands to run yourself]
2. Smoke test: [specific manual test — what to run, what to check, what "working" looks like]
3. Read: [2-3 key files to inspect and what to look for]
4. Decide: [any open questions hit during this slice]
5. Next: [exact prompt to feed back for next slice, or $bridge-gate if ready]
```

Consult docs/human-playbook.md for project-specific verification per slice.
