---
name: Bridge Context Create
description: Create context.json from requirements and current codebase. Invoke with $bridge-context-create in your prompt.
---

Context file docs/context.json is missing or needs to be created from scratch.

Follow `.agents/procedures/bridge-context-sync.md` to create it from docs/requirements.json and the current codebase.

Optionally point this skill at existing non-BRIDGE docs (README, PRD, wiki export, description files): they are ingested into docs/project-knowledge.md with per-source provenance dates. Without sources, the project-knowledge step proceeds code-only and never blocks context creation.
