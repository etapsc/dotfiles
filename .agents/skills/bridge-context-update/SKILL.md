---
name: Bridge Context Update
description: Sync context.json with current code reality. Invoke with $bridge-context-update in your prompt.
---

Follow `.agents/procedures/bridge-context-sync.md` to update docs/context.json against current code reality.

Optionally point this skill at new or updated non-BRIDGE docs (README, PRD, wiki export, description files): they are ingested into docs/project-knowledge.md with per-source provenance dates, refreshing only the affected sections. Without new sources or an explicit refresh request, the project-knowledge step is a no-op.
