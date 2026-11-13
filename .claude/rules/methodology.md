# BRIDGE Methodology Rules

## Phase Flow

Brainstorm → Requirements → Implementation Design → Develop → Gate → Evaluate

## Feature Status Flow

`planned` → `in-progress` → `review` → `done` | `blocked`

## Slice Discipline

- Work in thin vertical slices. Prefer PR-sized diffs.
- Every acceptance test (ATxx) requires executable evidence before claiming "done".
- Use stable IDs: Fxx (features), ATxx (acceptance tests), Sxx (slices), UFxx (user flows), Rxx (requirements).

## Scope Control

- Respect `scope.in_scope`, `out_of_scope`, and `non_goals` from requirements.json.
- No scope creep without explicit user instruction.
- Unknowns go to `execution.open_questions`, filed per Discrepancy Handling below — do not invent answers.

## Discrepancy Handling

- Code differs from context.json → update context.json.
- Code differs from requirements.json → record discrepancy in context.json, propose fix. Do NOT silently rescope.
- Someone must decide → open question. Sources disagree or the product is wrong → discrepancy, with one linked open question holding the options. More than a paragraph → issue file in `docs/issues/`, named by its ID.
- A hazard for the next session → `handoff.watch_out` entry naming its expiry condition; with no expiry condition it is a candidate standing rule — offer it to `bridge-persist` or a `docs/conventions.md` row, never move it automatically. Fields, kinds, status words: `docs/conventions.md`, "Records: what goes where".

## Targeted Inspection

- No full-repo scans by default.
- Targeted file inspection only — read what you need for the current task.
