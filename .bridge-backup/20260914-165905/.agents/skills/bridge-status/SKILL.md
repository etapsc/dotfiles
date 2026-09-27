---
name: Bridge Status
description: Generate or refresh docs/STATUS.md — a human-readable engineering status log for the project owner and contributors. Invoke with $bridge-status in your prompt.
---

You are generating a STATUS document for in-team consumption. This is a living engineering log: per-version milestones, in-flight branches, test/quality numbers, known issues, open questions, and what's next. It is NOT the same as `docs/project-brief.md` — that one is an external-agent handoff. STATUS is the internal status board.

## When to Use This Skill vs $bridge-project-brief

- **`$bridge-status`** → produces `docs/STATUS.md`, a richer engineering rollup. Includes worktree drift, in-flight branches, detailed test/quality numbers, full open-issue list. Audience: project owner, contributors, day-to-day operators.
- **`$bridge-project-brief`** → produces `docs/project-brief.md`, a portable explanation for outside readers. Canonical-only, excludes worktree drift, capped at ~2000 words. Audience: external AI agents, multi-agent councils, onboarding outsiders.

Both can coexist. Both are derived artifacts; both fully overwrite on each run.

## Inputs

Read these in order:

1. `docs/context.json` — feature status, slice history, gate history, eval history, handoff, watch-outs, parallel-track state if present
2. `docs/requirements.json` — features, acceptance tests, scope, recommended slices, open questions
3. `docs/contracts/*` — schemas/ADRs (if present, list them in the milestones table)
4. `docs/decisions.md` — architectural decision log (if present, surface relevant items in Open Questions)
5. `.bridge-version` — current version marker
6. Repo `git status` output — for In-Flight Branches section (current branch, dirty files, recent branches)

## Architecture Scan (lightweight)

Look at:
- Top-level directory structure (one level deep)
- README.md project description
- `commands_to_run` block from `context.json` (for the Test & Quality Summary)

Do NOT read source code. STATUS is a state report, not an architecture analysis — that's project-brief's job.

## Output

Write the complete document to `docs/STATUS.md`. If the file already exists, overwrite it entirely — this is a derived artifact, not a place for durable manual notes.

Use this section structure:

```markdown
# [project name] — Project Status

Last updated: [today's date]
Version: [from .bridge-version or requirements.json project.version]
Source of truth: docs/context.json (feature status), docs/requirements.json (intent)

[One-paragraph project summary — what it is, who it's for, current direction]

## In-Flight Branches

[Cross-branch coordination section. ALWAYS render this section.]

[If `context.json.parallel_tracks` exists OR `git branch` shows multiple non-master branches with recent activity:
  - One paragraph per active branch
  - Format: `branch-name (since YYYY-MM-DD): one-line goal. Key deliverables: ... Guardrails: ... Plan: docs/plans/...`
]

[If no parallel tracks and only the default branch is active:
  - Render exactly: `No active branches. Work is happening on master/main only.`
]

## Version Milestones

[One subsection per release/version line that has shipped or is planned. Use the slice history + feature status to group.]

### v[X.Y.Z] (label) — [Complete | In Progress | Planned]

[Optional 1-2 sentence summary of what this version delivers]

| Feature | Slice | Title | Key Deliverables | Status |
|---------|-------|-------|------------------|--------|
| Fxx | Sxx | ... | ... | done |

Slices [DONE | IN PROGRESS | PLANNED]: Sxx-Syy
[Optional: brief evidence pointer, e.g. "All gates PASS"]

## Workspace Examples

[If `workspaces/` directory exists in repo, list each workspace with one-line description.
 If no workspaces directory, render: "No workspace examples in this repo."]

## Test & Quality Summary

[Pull from context.json.commands_to_run if present. Run nothing — report the LAST KNOWN values from gate_history or context.json. If unavailable, render the row with "(run [command] to populate)".]

| Metric | Value | Notes |
|--------|-------|-------|
| Smoke tests | ... | from context.json or last gate report |
| E2E tests | ... | |
| Eval validator | ... | from validate-eval-scenarios.sh last run |
| Lint / typecheck | ... | "(not configured)" if absent |
| Coverage | ... | "(not configured)" if absent |
| Last gate | pass/fail on YYYY-MM-DD | from gate_history |

## Known Open Issues

[Source: gate_history blocking_issues + warnings from the most recent N gate reports, plus execution.open_questions from requirements.json. Format as bullets, each with severity (blocker/warning/note) and the issue text. Mark resolved items as struck-through or omit them.]

- [severity] [issue text] (from gate YYYY-MM-DD or OQxx)

## Open Questions

[Render as a small table. Pull from requirements.json execution.open_questions and any unresolved questions from gate_history notes.]

| ID | Topic | Status | Notes |
|----|-------|--------|-------|
| OQ01 | ... | open/closed | ... |

## What's Next

Next slice: [from context.json.next_slice or first planned slice in execution.recommended_slices]

[Bullet list of upcoming work, grouped by version target if multiple]
```

## Output Constraints

- **No word cap.** This is an engineering log; thoroughness beats brevity.
- **Tone:** Factual, log-style. Read like a project owner's status board.
- **Worktree drift INCLUDED.** Unlike project-brief, STATUS may reference uncommitted work, in-flight branches, and pending PRs. Pull from `git status` and `context.json.parallel_tracks` if present.
- **Fall back to placeholders, never invent.** Use "not yet documented", "not configured", or "(run [cmd] to populate)" rather than guessing values.
- **Always render every section.** Even if empty, render the heading + a placeholder line. Predictable structure makes downstream tooling easier.
- **No source code reading.** STATUS is state, not architecture.

## Required Closing (do not omit)

Your response MUST end with a HUMAN: block. Use this format:

```
HUMAN:
1. Review docs/STATUS.md — does it accurately represent the project's current state?
2. If anything important is missing (e.g. an in-flight branch the agent didn't see), record it in context.json.parallel_tracks or context.json.handoff before rerunning — STATUS overwrites on every run, manual edits inside STATUS.md will not survive
3. Decide: is this status snapshot ready to share with the team, or does context.json need a refresh first via $bridge-context-update?
```

The user will provide arguments inline with the skill invocation.
