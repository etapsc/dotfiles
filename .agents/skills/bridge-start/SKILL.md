---
name: Bridge Start
description: Start BRIDGE implementation - plan and execute slices from requirements. Invoke with $bridge-start in your prompt.
---

Load docs/requirements.json and docs/context.json.

## Specialist Loading

Before planning the slice, if the user explicitly says `no specialists` for this start invocation, skip this section. Otherwise check `execution.specialists_recommended` in requirements.json. If it exists and is non-empty:

1. Determine the active slice features:
   - If the invocation names a selection (one slice or a list; Selection in `.agents/procedures/bridge-slice-plan.md`), use the features of its slices; they win over `next_slice`
   - Else prefer `context.json.next_slice.features` when present
   - Else if `context.json.next_slice.slice_id` exists, resolve that slice ID in `requirements.json.execution.recommended_slices`
   - Else if `context.json.current_slice` is a slice ID, resolve that ID in `requirements.json.execution.recommended_slices`
2. For each matching specialist, read the specialist file from `.agents/specialists/<id>.md`
3. Output a SPECIALISTS LOADED block:

```
SPECIALISTS LOADED for [Sxx]:
- [specialist-name] (confidence: high) — [rationale]. Applies to: [roles]
- [specialist-name] (confidence: medium) — [rationale]. Applies to: [roles]

To skip specialist guidance: tell me "no specialists" or edit execution.specialists_recommended in requirements.json.
```

4. When working on the slice, read and apply the guidance sections matching your current role from each loaded specialist file

If `execution.specialists_recommended` is empty or absent, skip this step silently.

## Slice Execution

Plan and execute the next slice using `.agents/procedures/bridge-slice-plan.md`. Switch to architect mode (if design needed), code mode (implementation), debug mode (if tests fail).

If the invocation names a selection, run it as the Selection section of `.agents/procedures/bridge-slice-plan.md` says. Otherwise start with the first recommended slice or the slice indicated in context.json next_slice.

**Design cost stop.** A selection whose plan or contract proposes a new executable outside tests/slices/ (a tool, renderer or script), more than 200 lines of new code and tests combined, or a contract over 20 KB is not started until docs/decisions.md carries the cost comparison for it (the architect's table, the proposed design against the simplest alternative, with the chosen row named). The comparison cites the design file it summarizes, under docs/designs/ with the gaps the architect found; a comparison without that file is not enough, so if the architect returned its design only as a message, write that file before asking for the row. Stop before any edit and name it: the HUMAN block names the missing comparison and the decision entry that should carry it, and cites the design file's path. A plan under both thresholds that adds no executable needs no comparison before it starts.

## Relay

If the arguments begin with `with-relay` or `start-relay`, the rest is the selection. Resolve the current repository; if its `.bridge/relay/README.md` is missing, say so and stop before any work (`bridge.sh update` installs it).

- `with-relay`: build the selection as a list run (Selection in `.agents/procedures/bridge-slice-plan.md`) with no approval pause, even for one slice, then follow the producer steps in `.bridge/relay/README.md`.
- `start-relay`: the work is already built, so do not build it again. Its slices may be at `review` as well as `planned` or `in-progress`; the other Selection checks still apply. Confirm its checks pass, then follow the producer steps in `.bridge/relay/README.md`.

The README's Authority section sets what the run may commit. Never push, tag or record acceptance.

## HUMAN: Block (required)

After completing the slice, you MUST end your response with a HUMAN: block as specified in the slice-plan procedure. Never present slice results without a HUMAN: block.

The user will provide arguments inline with the skill invocation.
