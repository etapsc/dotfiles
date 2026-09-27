---
name: Bridge Project Brief
description: Generate or refresh docs/project-brief.md — a portable project explanation for external agents and discussions. Invoke with $bridge-project-brief in your prompt.
---

You are generating a project brief for external consumption. This document explains the project to outside AI agents, multi-agent councils, quorum-style discussions, and anyone onboarding to this codebase for the first time.

## State Interpretation

Follow Project State and Acceptance in the repository entrypoint. Read the latest
scoped acceptance/reopening in `docs/decisions.md` and `context.json.feedback_history`
alongside current feature statuses. Report delivery/acceptance, gate verdict with
revision, automated eval, live eval and publication as separate facts. Preserve
explicit acceptance even when live evaluation is deferred; do not turn warnings,
`awaiting_feedback`, older `review` prose, or a missing tag into an acceptance
blocker. A blocker needs an applicable requirement or operator decision cited by
name. Historical results keep their original scope and do not cover later edits.
Project/installed version metadata does not prove a tag or published release.

These are derived reports, so do not hide a contradiction by changing only this
file. If the task authorizes reconciliation, first record the operator's existing
decision and synchronize canonical state through Context/Feedback, then generate
this report. Do not request approval already supplied. If only reporting is
authorized, identify the authoritative decision and the exact stale field;
Status may show that discrepancy, while Brief waits for canonical reconciliation.

## Inputs

Read these in order:

1. `docs/context.json` — current state, feature status, handoff, gate history
2. `docs/requirements.json` — scope, features, acceptance tests, constraints
3. `docs/contracts/*` — schemas and architectural decisions (if present)
4. `docs/decisions.md` — architectural decision log (if present)

## Architecture Scan

After reading the docs, scan for architecture signals:

1. Package manifests in the repo root (package.json, Cargo.toml, go.mod, pyproject.toml, etc.)
2. Top-level directory structure (1 level deep only)
3. README.md and any AGENTS.md
4. CI/CD config files (.github/workflows/, .gitlab-ci.yml, etc.)
5. Docker/container config (Dockerfile, docker-compose.yml)
6. Entrypoints (main files, CLI definitions, server startup files)

Do NOT read source code files unless a specific architectural claim needs validation.

If the directory scan reveals directories that are not referenced in `docs/requirements.json`, `docs/context.json`, or `README.md`, ignore them unless they materially affect an external reader's understanding of the documented product surface. If they do matter, mention them briefly as present in the repo but not part of the documented product surface.

## Source Interpretation

When sources differ:

- the operator's live word outranks documents; persist authorized decisions before deriving the brief
- reconciled `docs/context.json` wins for current state and handoff; gate/eval history supplies revision-scoped evidence, not an acceptance veto
- `docs/requirements.json` wins for intended scope, feature inventory, user flows, and acceptance tests
- repository inspection validates architecture only; it must not become a substitute for stale BRIDGE artifacts
- do not overstate pack symmetry: the supported packs share BRIDGE methodology and command surface, but not the same internal implementation model

## Preconditions

This command is for canonical-state summarization, not reconciliation.

Before generating the brief, verify that:

- `docs/requirements.json` and `docs/context.json` exist and are current
- canonical state records the latest acceptance/reopening and any explicit deferrals
- gate/eval artifacts identify the revisions they actually tested; their historical
  `review` wording or a documented coverage gap does not by itself make state stale
- any authorized canonical reconciliation has completed; explicitly deferred live
  evaluation does not require another Gate/Eval before generating this summary

If the canonical BRIDGE artifacts are stale, contradictory, or obviously behind the intended current state:

- do NOT try to reconcile them inside the brief
- tell the human to refresh the BRIDGE artifacts first
- stop instead of generating a misleading brief

## Output

Write the complete document to `docs/project-brief.md`. If the file already exists, overwrite it entirely — this is a derived artifact, not a place for durable manual notes.

Use this exact section structure:

```markdown
# Project Brief — [project name]

Last updated: [today's date]
Version: [from requirements.json project.version or inferred]
Status: [active development | maintenance | planning | blocked]

## For External Agents

When using this brief as context:
- Treat docs/requirements.json as the source of truth for scope and acceptance tests
- Treat docs/context.json as the source of truth for current state and handoff
- This brief is a summary of reconciled canonical state; the operator's live word remains highest authority, with acceptance recorded in docs/decisions.md
- Respect scope.out_of_scope and scope.non_goals when proposing features
- Use stable IDs (Fxx, ATxx, Sxx, UFxx, Rxx) when referring to project elements
- Do not assume features marked "planned" are committed — they are candidates

Recommended context packet for external discussions:
1. This file (docs/project-brief.md)
2. docs/requirements.json
3. docs/context.json
4. Optionally: a specific design note, issue, or feature proposal

## What This Project Does
[2-3 sentences: what it does, who it's for, what problem it solves, key differentiator]

## Architecture Overview
[What the system is and isn't. Core components. Key patterns. Install/packaging model if applicable. Do not claim all packs share the same internal implementation model.]

## Repository Map
[Top-level directory structure with purpose of each major area. Release artifacts if applicable. Mention potentially stale directories only if they materially affect external understanding.]

## Key Workflows
[Primary user journeys — keep to 3-5 workflows, one line each. Distinguish: greenfield (brainstorm -> requirements -> start), existing BRIDGE project (scope -> feature -> start), and non-BRIDGE onboarding (description/scope -> requirements-only -> context create/update -> start).]

## Current State
[Feature status table from reconciled requirements + context. Active or next slice if present. Separately state delivery/acceptance with its decision pointer, gate verdict and revision, automated eval, live eval/deferrals, and publication evidence. Recent activity recorded in canonical docs only.]

## Constraints and Non-Goals
[Technical constraints and explicit non-goals from requirements.json scope]

## Open Questions and Future Direction
[Planned features not yet started, open questions, active proposals]

## Origin and Evolution
[Brief project history — 2-3 sentences. Truncate this section first if over word limit.]
```

## Output Constraints

- **Word limit:** Keep the total document under 2000 words. If the project is complex, truncate from the bottom up — Origin/Evolution first, then Open Questions. Architecture and Current State are the most valuable sections.
- **Tone:** Factual, compact, oriented toward a reader who has never seen this project.
- **No invention:** If you cannot confirm a claim from the repository, label it: `inferred`, `unknown`, or `not yet documented`. Never invent architecture or capabilities.
- **Summarize, don't duplicate:** Link to canonical files. Do not copy full requirements or full context into the brief.
- **Canonical-only mode:** Do not describe uncommitted worktree drift, temporary implementation state, or chat-only intentions. If canonical BRIDGE artifacts are stale, stop and ask for them to be refreshed first.

## Required Closing (do not omit)

Your response MUST end with a HUMAN: block. Use this format:

```
HUMAN:
1. Review docs/project-brief.md — does it accurately represent the project?
2. If anything important is missing, record it in a separate decision note or proposal — do not rely on manual edits inside project-brief.md (it gets overwritten on refresh)
3. Decide: is this ready to feed to external agents, or does it need a rerun?
```

The user will provide arguments inline with the skill invocation.
