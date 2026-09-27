---
name: Bridge Context
description: "Create or refresh docs/context.json from requirements and current code reality. Invoke with $bridge-context in your prompt."
---

## TASK — CONTEXT SYNC

Follow `.agents/procedures/bridge-context-sync.md`. It decides create-versus-update by whether
`docs/context.json` already exists, so you do not have to pick a code path — but
say which situation you are in so the operator can see you read it correctly.

### Step 0: Select Mode (content-driven)

- **Create** — `docs/context.json` is missing, empty, or unusable. Build it from
  `docs/requirements.json` and targeted inspection of the current codebase.
- **Update** — `docs/context.json` exists. Reconcile it against current code
  reality: feature status, evidence, discrepancies, handoff, next slice.

State the selected mode in one line at the top of your output:

```
#### Selected Mode: Create | Update
[why — e.g. "no docs/context.json present" / "context.json last updated 2026-08-14"]
```

If the file exists but is unreadable or schema-invalid, say so explicitly and
treat it as **Create**, preserving the old file as `docs/context.json.bak` first.
Never silently discard a context file.

### Project knowledge (both modes)

Optionally point this command at non-BRIDGE docs (README, PRD, wiki export,
description files). They are ingested into `docs/project-knowledge.md` with
per-source provenance dates.

- **Create** without sources: the project-knowledge step proceeds code-only and
  never blocks context creation.
- **Update** without new sources or an explicit refresh request: the
  project-knowledge step is a no-op. When sources are supplied, refresh only the
  affected sections and report what changed. Never silently overwrite operator
  edits.

## Required Closing (do not omit)

Your response MUST end with a HUMAN: block:

```
HUMAN:
1. Selected Mode was [Create | Update] — does that match what you expected?
2. Review docs/context.json — does feature_status match reality?
3. [If sources were ingested] Review the changed sections of docs/project-knowledge.md
4. Decide: proceed to $bridge-start, or correct the context first
```

The user will provide arguments inline with the skill invocation.
