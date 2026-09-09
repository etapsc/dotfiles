---
description: "Create context.json from requirements and current codebase"
---

Context file docs/context.json is missing or needs to be created from scratch.

Use the bridge-context-sync skill to create it from docs/requirements.json and the current codebase.

Optionally point this command at existing non-BRIDGE docs (README, PRD, wiki export, description files): they are ingested into docs/project-knowledge.md with per-source provenance dates. Without sources, the project-knowledge step proceeds code-only and never blocks context creation.
