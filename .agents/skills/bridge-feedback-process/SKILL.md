---
name: Bridge Feedback Process
description: Process actual evaluation feedback or record explicit operator acceptance and deferrals. Never infer completed tests from an acceptance decision.
user-invocable: false
---

# Feedback Processing

## Step 0: Recognize Existing Operator Decisions

Read the operator's current and earlier instructions before triage. Explicit
acceptance such as "treat these slices as done" already authorizes recording it;
it does not require a second go/no-go or completed live tests if the operator
explicitly deferred them. Apply Project State and Acceptance in the entrypoint:
append the scoped acceptance to `docs/decisions.md`, add a `feedback_history`
entry with date, approver, features/slices, revision, decision pointer and explicit
deferrals, then synchronize context and requirements statuses and handoff.
An agent records the operator's decision; it does not independently accept work.

A plan to test later is not a test result. Keep live evaluation deferred and
unobserved, and keep `awaiting_feedback` true for the missing observations.
Non-blocking warnings do not veto explicit acceptance. Preserve every gate's
verdict and revision; accepting a known coverage limitation cannot turn it into
passing evidence. If the message only supplies acceptance or deferral, skip the
issue-count update below: do not invent a zero-issue test report.

## Step 1: Parse
- Extract issues with severity (high/medium/low)
- Identify patterns and themes
- Note positive feedback

## Step 2: Triage
- **High severity** → blocking, must fix before launch
- **Medium severity** → should fix, can defer to v1.1
- **Low severity** → add to extended features in requirements.json

## Step 3: Update Context
Update eval_history entry in docs/context.json:
```json
{ "feedback_received": "[today]", "issues_found": { "high": 0, "medium": 0, "low": 0 }, "action": "iterate|launch" }
```

## Step 4: Decision

If high severity:
```
ITERATION REQUIRED
Blocking issues:
1. [Task - Fxx]
Returning to code/debug. Re-run /bridge-gate after fixes.
```
Features → "in-progress"

If medium/low only:

Apply this recommendation branch only when no explicit acceptance is already available.
```
LAUNCH CANDIDATE ✓
Optional improvements (non-blocking):
1. [Suggestion]
Recommended: Launch. Medium issues → v1.1.
```
Features stay at **"review"**.

**Do NOT set "done" here.** This recommendation branch has no acceptance.
`done` requires the operator's explicit go/no-go and an acceptance record in
`docs/decisions.md`. That go/no-go may already have been supplied; Step 0 handles
it without asking again. The approver records acceptance in
`docs/decisions.md` and only then moves the feature to `done`.

## Step 5: Human Handoff (required)

If acceptance was already recorded, report the accepted scope, decision pointer
and deferred observations, then give the next concrete action. Do not present
the go/no-go question again. Otherwise use the applicable lines below.

```
HUMAN:
1. [If ITERATION] Review blocking issues — do they match your testing experience?
   Feed fix instructions back, then re-run /bridge-gate after fixes
2. [If LAUNCH CANDIDATE] Final go/no-go is yours:
   - Did the app feel right during manual testing?
   - Are you comfortable deferring medium-severity issues to v1.1?
   - Any concerns not captured in the feedback?
3. Medium issues logged for v1.1 — create tracking issues if needed
```
