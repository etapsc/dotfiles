---
name: "source-command-bridge-context-update"
description: "Sync context.json with current code reality"
---

# source-command-bridge-context-update

Use this skill when the user asks to run the migrated source command `bridge-context-update`.

## Command Template

Use the bridge-context-sync skill to update docs/context.json against current code reality.

Optionally point this command at new or updated non-BRIDGE docs (README, PRD, wiki export, description files): they are ingested into docs/project-knowledge.md with per-source provenance dates, refreshing only the affected sections. Without new sources or an explicit refresh request, the project-knowledge step is a no-op.
