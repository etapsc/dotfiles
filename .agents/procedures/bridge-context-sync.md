---
name: Bridge Context Sync
description: Create or update context.json to reflect current code reality. Use when context.json is missing, stale, or after significant code changes.
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
  "feature_status": [
    { "feature_id": "F01", "status": "planned|in-progress|review|done|blocked", "notes": "", "evidence": [] }
  ],
  "handoff": { "stopped_at": "", "next_immediate": "", "watch_out": "" },
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

## Project Knowledge (docs/project-knowledge.md)

Run in BOTH paths above, before the final output/summary step. `docs/project-knowledge.md` is INPUT-side (world → BRIDGE), filled from operator-provided existing docs plus targeted code inspection. It is NOT the derived `docs/project-brief.md` (output-side, full-overwrite) — never blur the two.

- The operator MAY pass source pointers when invoking bridge-context-create / bridge-context-update: README, PRD, wiki export, files under docs/, or arbitrary description text.
- Sources given: read them plus targeted code inspection of THIS repo only. Fill the matching skeleton sections, then append each ingested source with a date to the Ingested Sources provenance table.
- NO sources given: on create, fill what targeted code inspection alone supports (or leave the skeleton placeholders); on update, do NOT touch the file — an explicit no-op. Either way the context.json flow proceeds; this step never fails or blocks it.
- Refresh discipline: the file is operator-owned after first fill. Touch it only when the operator supplies new sources or explicitly requests a refresh. Refresh ONLY the affected sections and report what changed in the output summary. NEVER regenerate or silently overwrite the whole file.
- Workspace boundary: operate on THIS project's own docs/project-knowledge.md only. In a multi-repo workspace that is the workspace's own file — never scan or write a downstream repo's docs. If the template file is absent, note it and skip (no-op).
