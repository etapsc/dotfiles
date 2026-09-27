---
name: Bridge Context Sync
description: Create or update context.json to reflect current code reality. Use when context.json is missing, stale, or after significant code changes.
user-invocable: false
---

# Context Synchronization

## If Creating (context.json missing)

1. Load docs/requirements.json
2. Run `git status` and `git log --oneline -20`
3. Targeted code inspection for modules relevant to first slice only
4. Create docs/context.json:

```json
{
  "schema_version": "context.v1",
  "updated": "[timestamp]",
  "project": { "name": "dotfiles" },
  "feature_status": { "F01": "planned|in-progress|review|done|blocked" },
  "evidence": {
    "AT01": { "class": "executable", "command": "", "exit_code": 0, "revision": "", "dirty": false, "at": "" },
    "AT02": { "class": "manual-observation", "observer": "", "procedure": "", "revision": "", "observed": "" }
  },
  "handoff": { "stopped_at": "", "next_immediate": "", "watch_out": [] },
  "next_slice": { "slice_id": "", "goal": "", "features": [], "acceptance_tests": [] },
  "commands_to_run": { "test": "", "lint": "", "typecheck": "", "dev": "" },
  "recent_decisions": [],
  "blockers": [],
  "discrepancies": [],
  "gate_history": [],
  "eval_history": []
}
```

5. Output summary of findings. Stop.

## If Updating (context.json exists)

1. Load docs/context.json and docs/requirements.json
2. Run `git status` + `git log --oneline -10`
3. Validate feature_status for recently touched areas and next_slice
4. Update context.json to match code reality
5. Output sync report with discrepancies found

## Reconcile Acceptance Before Reporting

Apply Project State and Acceptance from the repository entrypoint. Check the
operator's live instructions and the latest scoped acceptance or reopening in
`docs/decisions.md` and `feedback_history` before deriving a status from older
gate/eval notes. An existing explicit acceptance needs recording, not another
permission question. Append its date, approver, feature/slice scope, revision,
decision pointer and explicit deferrals to `feedback_history`; synchronize
requirements feature statuses, `feature_status`, slice status and handoff.
Do not invent human observations or treat warnings, deferred live evaluation,
`awaiting_feedback`, or an absent release tag as an acceptance veto.
Keep gate/eval history pinned to the revision and results actually observed.
Supersede mistaken decisions by appending a correction, never rewriting history.
Prune contradictory current handoff text before regenerating Status or Brief.

## Context Hygiene (both paths)

**`feature_status` is an object map of id to status string. Nothing else.**
`{"F01": "done"}` — no array, no per-feature object, no titles, no notes.
Titles live in `docs/requirements.json`; copying them into context is drift bait.
Notes belong in `slice_history`. If you find an array-shaped `feature_status`,
convert it and say so in the sync report.

**Evidence lives in the top-level `evidence` map, keyed by acceptance test.**
Two classes, and nothing else counts:

- `executable` — a command a reviewer can re-run. Record `command`, `exit_code`,
  `revision`, `dirty`, and `at` (when it ran).
- `manual-observation` — record `observer`, `procedure`, `revision`, `observed`.

Evidence buried in prose inside a `slice_history` note is not evidence a reviewer
can find. Never write an evidence record for a run you did not observe.

**`recent_decisions` is a window of the last five.** `docs/decisions.md` is
canonical and append-only. The context list is a pointer, not a log — when it
exceeds five entries, drop the oldest and confirm the dropped ones are in
`docs/decisions.md` first. If one is missing there, append it before dropping it.

**`handoff.watch_out` entries expire.** Each entry belongs to live work. When the
feature or slice it warns about closes, remove it in the same pass. A warning
about something that closed months ago is noise that crowds out the ones that
still matter.

## Project Knowledge (docs/project-knowledge.md)

Run in BOTH paths above, before the final output/summary step. `docs/project-knowledge.md` is INPUT-side (world → BRIDGE), filled from operator-provided existing docs plus targeted code inspection. It is NOT the derived `docs/project-brief.md` (output-side, full-overwrite) — never blur the two.

- The operator MAY pass source pointers when invoking bridge-context: README, PRD, wiki export, files under docs/, or arbitrary description text.
- Sources given: read them plus targeted code inspection of THIS repo only. Fill the matching skeleton sections, then append each ingested source with a date to the Ingested Sources provenance table.
- NO sources given: on create, fill what targeted code inspection alone supports (or leave the skeleton placeholders); on update, do NOT touch the file — an explicit no-op. Either way the context.json flow proceeds; this step never fails or blocks it.
- Refresh discipline: the file is operator-owned after first fill. Touch it only when the operator supplies new sources or explicitly requests a refresh. Refresh ONLY the affected sections and report what changed in the output summary. NEVER regenerate or silently overwrite the whole file.
- Workspace boundary: operate on THIS project's own docs/project-knowledge.md only — never scan or write another repo's docs. If the template file is absent, note it and skip (no-op).
