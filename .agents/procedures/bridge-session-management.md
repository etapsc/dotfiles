---
name: Bridge Session Management
description: Session start (re-entry brief) and end (wrap-up) procedures. Use when resuming work in a fresh session or ending a development session.
---

# Session Management

## Fresh Session Re-entry

Read current feature statuses together with the latest scoped acceptance in
`docs/decisions.md` / `context.json.feedback_history`. Follow Project State and
Acceptance in the entrypoint: report acceptance, gate revision, automated eval,
live eval and publication separately. Older `review` notes and non-blocking
warnings cannot override a later acceptance. Re-entry is read-only; surface any
remaining contradiction and its authoritative decision without repairing files.

Output brief:

```
═══════════════════════════════════════
PROJECT: [name]
STACK: [from constraints]
═══════════════════════════════════════

HANDOFF:
└─ Stopped at: [handoff.stopped_at]
└─ Next: [handoff.next_immediate]
└─ Watch out: [handoff.watch_out]

FEATURE STATUS:
✓ Done: [Fxx list]
→ Active: [list]
○ Planned: [list]
⊘ Blocked: [list]

LAST GATE: [pass/fail/none] on [date]
LAST EVAL: [date] or none

NEXT SLICE: [Sxx] - [goal]
  Features: [Fxx list]
  Exit Criteria: [ATxx list]

TASK GRAPH (3-10 tasks):
  [task_id] → [goal] | [inputs] | [tests/evidence]

OPEN QUESTIONS / BLOCKERS:
[if any]
═══════════════════════════════════════
```

Then, before the final `HUMAN:` block:
- If matching specialists were identified for the current/next slice, insert:
  ```
  SPECIALISTS SUGGESTED for [Sxx]:
  - [specialist-name] (confidence: high) — [rationale]. Applies to: [roles]
  - [specialist-name] (confidence: medium) — [rationale]. Applies to: [roles]

  These specialists are suggested from the current requirements/slice context. They are NOT loaded yet.
  ```
- If no specialists match, omit this section.

Then output:
```
HUMAN:
1. Review the brief — does it match your understanding of where things stand?
2. (Optional) If specialists were suggested above, you may reply `load specialists`, `no specialists`, or name the IDs to load — a non-blocking suggestion; giving a task or command proceeds without it
3. Run `git status` and [test command] to confirm code state matches context.json
4. Consult docs/human-playbook.md for what to verify for the current slice
5. Reply "continue" or just give the next task/command — work proceeds immediately and never blocks on the specialist question
```

Then STOP and wait.

## Session Wrap-up

1. Reconcile the operator's decisions before writing the handoff. If explicit
   acceptance was already given, record it in `docs/decisions.md` and
   `context.json.feedback_history` without asking again; follow Project State
   and Acceptance in the entrypoint. Synchronize requirements feature statuses
   with context, preserve deferred checks as unobserved, and expire obsolete
   watch-outs. Never reset accepted features to `review` because live feedback
   is pending or a historical gate report predates acceptance.
2. Update docs/context.json:
   - feature_status
   - handoff (stopped_at, next_immediate, watch_out)
   - next_slice
3. Append other decisions to docs/decisions.md (YYYY-MM-DD: [Decision] - [Rationale]); do not duplicate acceptance already recorded.
4. Output summary: accomplished, remaining, blockers. Separate deferred follow-ups from acceptance blockers and report the current Git state rather than copying old handoff prose.
5. End with:

```
HUMAN:
1. Before closing: run [test/lint commands] to confirm session state
2. Review context.json handoff — does it match your understanding?
3. Before next session, decide: [any open questions that surfaced]
4. Next session: $bridge-resume
```
