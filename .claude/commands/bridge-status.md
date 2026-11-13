---
description: "Generate or refresh docs/STATUS.md — a human-readable engineering status log for the project owner and contributors"
---

You are generating a STATUS document for in-team consumption. This is a living engineering log: the facts of the latest version, what's next, per-version milestones, test/quality numbers, known issues and open questions; branches in flight appear when there are any. It is NOT the same as `docs/project-brief.md` — that one is an external-agent handoff. STATUS is the internal status board.

## When to Use This Command vs `bridge-project-brief`

- **`bridge-status`** → produces `docs/STATUS.md`, a richer engineering rollup. Includes worktree drift, in-flight branches, detailed test/quality numbers, full open-issue list. Audience: project owner, contributors, day-to-day operators.
- **`bridge-project-brief`** → produces `docs/project-brief.md`, a portable explanation for outside readers. Canonical-only, excludes worktree drift, capped at ~2000 words. Audience: external AI agents, multi-agent councils, onboarding outsiders.

Both can coexist. Both are derived artifacts; both fully overwrite on each run.

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

1. `docs/context.json` — feature status, slice history, gate history, eval history, handoff, watch-outs, parallel-track state if present
2. `docs/requirements.json` — features, acceptance tests, scope, recommended slices, open questions
3. `docs/contracts/*` — schemas/ADRs (if present, name the current ones in the version table that delivered them)
4. `docs/decisions.md` — scoped acceptance, publication and reopening records (link them from the Accepted cells, the tag lines and Known Open Issues; surface open items in Open Questions)
5. `.bridge-version` — current version marker
6. Git reads, for the Snapshot line, the Facts table, Version Milestones and In-Flight Branches:
   - tags and their commits: `git tag --sort=-creatordate` (or equivalent) and `git rev-list -1 <tag>`
   - the default-branch log for each version range: `git log <prev-tag>..<tag> --merges`, reading pull-request merge subjects (`Merge pull request #nnn`); `gh pr list --state merged` when `gh` is installed
   - the default branch, resolved by name and never read from the checked-out `HEAD`: `git symbolic-ref --short refs/remotes/origin/HEAD` (strip `origin/`), falling back to a local `main` or `master` that exists; its tip with `git rev-parse <default-branch>`; equal to, ahead of or behind its remote with `git rev-list --left-right --count <default-branch>...origin/<default-branch>`. When no default branch can be identified, or it has no remote counterpart, the Snapshot line says `unknown` for the missing part; a checked-out topic branch's tip is never labelled the default-branch tip
   - branch tips and unmerged commits: `git branch -a`, `git log -1 <branch>`, `git log <default-branch>..<branch>`, and each branch's latest pull request (merge subjects or `gh pr list --head <branch> --state all` when `gh` is installed: `gh` lists open pull requests only by default, so ask for all states and select the most recent; `unknown` when the lookup cannot run)

Read the current `docs/requirements.json` and `docs/context.json`. For a Complete version whose features or slices are no longer in the current files, make a targeted `previous_doc` read into `docs/archive/` for those IDs only, so an older milestone table keeps its recorded evidence instead of repeating stale prose; never scan the archive for anything else.

## Architecture Scan (lightweight)

Look at:
- Top-level directory structure (one level deep)
- README.md project description
- `commands_to_run` block from `context.json` (for the Test & Quality Summary)

Do NOT read source code. STATUS is a state report, not an architecture analysis — that's project-brief's job.

## Output

Write the complete document to `docs/STATUS.md`. If the file already exists, overwrite it entirely — this is a derived artifact, not a place for durable manual notes.

Use this section structure, in this order:

```markdown
# [project name] — Project Status

Last updated: [today's date]
Version: [from .bridge-version or requirements.json project.version]
Source of truth: docs/context.json (as-built state and evidence), docs/requirements.json (intent), scoped operator decisions in docs/decisions.md
Snapshot: [default branch] at [current default-branch commit], [equal to | ahead of | behind | unknown] [origin/<default branch>], when this report was written

[One-paragraph project summary — what it is, who it's for, the latest release, current direction]

| Fact | State |
|------|-------|
| Latest version | [The latest released version, its tag commit, and the latest pull request merged between the previous tag and that tag — number and merge commit. `none in this range` when the range has no pull-request merge. `unknown` when the lookup cannot run (no tags, shallow clone, no merge history). This row never names the default-branch tip; that stays on the Snapshot line.] |
| Delivery / acceptance | [Accepted scope and its decision pointers; point to the version tables for the per-feature records] |
| Gate | [Latest gate verdict with revision and date; where each version's gate is recorded] |
| Automated evaluation | [Latest automated evaluation result and date; per version below] |
| Live evaluation | [Unobserved live work and deferrals, per version below; automated checks never stand in for it] |
| Publication | [Tag and release evidence of the latest version; earlier publications under each version] |

[The Facts table reports delivery, gate, automated evaluation, live evaluation and publication as separate rows. Use "unknown/not recorded" for absent evidence; never infer one row from another.]

## In-Flight Branches

[Conditional. Render this section only when a non-default branch carries unmerged commits toward a feature that is not done (planned, in-progress, review or blocked); use `context.json.parallel_tracks` and the branch tips. Parked reference branches named under Withdrawn or retired are excluded. So is the `bridge-ids` counter branch of `docs/bridge-ids.conf`, local or remote: it holds reserved ID numbers, never feature work. List the candidates with `git branch -a --no-merged <default-branch> --format='%(refname)' | grep -v -x -e refs/heads/bridge-ids -e 'refs/remotes/[^/]*/bridge-ids'`. When the list is empty, the section is omitted entirely: no heading, no placeholder.]

[One entry per branch in flight. Each entry opens with the branch name, its tip commit and its latest pull request (number and state, `none`, or `unknown`), then since-date, goal, deliverables, guardrails and plan path:
`branch-name` at `<tip commit>`, PR #nnn (open | merged | closed) | PR none | PR unknown (since YYYY-MM-DD): one-line goal. Key deliverables: ... Guardrails: ... Plan: docs/plans/...]

## What's Next

Next slice: [from context.json.next_slice or the first planned slice in execution.recommended_slices; "none" when nothing is planned]

[Bullet list of upcoming work and of what waits on the operator]

### Post-[latest version] — Not done

[Planned and in-progress features and slices after the latest release. An empty table when nothing is planned.]

| ID | Covers | Title | Disposition | Status |
|----|--------|-------|-------------|--------|
| Fxx | Sxx | ... | ... | planned |

### Ideas and Proposals (not scheduled)

[Open proposals, ideas and optional follow-ups from docs/proposals/ and docs/ideas/, plus where the archived ones live. None of these is planned work.]

| Item | Kind | State |
|------|------|-------|
| ... | ... | ... |

## Version Milestones

[One subsection per version, latest at the top and oldest at the bottom. Each feature or slice row carries its shipped scope, acceptance record, gate, automated evaluation, unobserved live work and status. A feature that shipped scope in several versions has a row in each. For a Complete version whose IDs are archived, the row's evidence comes from the targeted previous_doc read.]

### v[X.Y.Z] (published [date]) — [Complete | In Progress | Planned]

[Optional 1-2 sentence summary of what this version delivers]

| Feature | Slice | Scope shipped | Accepted | Gate | Automated eval | Unobserved live work | Status |
|---------|-------|---------------|----------|------|----------------|----------------------|--------|
| Fxx | Sxx | ... | [acceptance record] | [verdict, date, report] | [result, date] | [UFxx or —] | done |

Tag v[X.Y.Z] → [tag commit]. [Release checks and record links; "not tagged" for a version without a tag.]

### Withdrawn or retired — Not done

[Removed features and slices with their disposition and parked branches; the IDs stay allocated and are never reused. "None." when nothing was withdrawn.]

| ID | Covers | Title | Disposition | Status |
|----|--------|-------|-------------|--------|
| Fxx | Sxx | ... | ... | removed |

## Test & Quality Summary

[Pull from context.json.commands_to_run if present. Run nothing — report the LAST KNOWN values from gate_history or context.json. If unavailable, render the row with "(run [command] to populate)".]

| Metric | Last-known value | Scope / command |
|--------|------------------|-----------------|
| Smoke tests | ... | from context.json or the last gate report (its highest round file) |
| E2E tests | ... | |
| Eval validator | ... | from validate-eval-scenarios.sh last run |
| Lint / typecheck | ... | "(not configured)" if absent |
| Coverage | ... | "(not configured)" if absent |
| Last gate | pass/fail on YYYY-MM-DD | from gate_history |

## Known Open Issues

[Source: unresolved findings from the latest applicable gate for each scope (the highest round of its report), reconciled with later decisions, plus recorded discrepancies. Preserve each finding's recorded severity; label operator-deferred follow-ups separately. Do not resurrect resolved historical blockers or upgrade warnings into acceptance blockers. Cite the requirement or operator decision for every current blocker.]

| Version | Source | Severity | Finding |
|---------|--------|----------|---------|
| v[X.Y.Z] | [gate report Wn, context.json Dnn, ...] | [recorded severity] | ... |

## Open Questions

[Render as a small table. Pull from requirements.json execution.open_questions and any unresolved questions from gate_history notes.]

| ID | Topic | Status | Notes |
|----|-------|--------|-------|
| OQ01 | ... | open/closed | ... |
```

## Output Constraints

- **No word cap.** This is an engineering log; thoroughness beats brevity.
- **Tone:** Factual, log-style. Read like a project owner's status board.
- **Worktree drift INCLUDED.** Unlike project-brief, STATUS may reference uncommitted work, in-flight branches, and pending PRs. Pull from `git status`, the branch tips and `context.json.parallel_tracks` if present.
- **Fall back to placeholders, never invent.** Use "not yet documented", "not configured", or "(run [cmd] to populate)" rather than guessing values. A pull-request lookup that cannot run says `unknown`, never `none`.
- **Render every section except In-Flight Branches.** Even if empty, render the heading + a placeholder line (an empty table where the template shows one). In-Flight Branches is omitted when no branch is in flight. Predictable structure makes downstream tooling easier.
- **Run nothing.** Report the LAST KNOWN values from the records; this is a state report and it runs no test, build or check.
- **No source code reading.** STATUS is state, not architecture.

## Required Closing (do not omit)

Your response MUST end with a HUMAN: block. Use this format:

```
HUMAN:
1. Review docs/STATUS.md — does it accurately represent the project's current state?
2. If anything important is missing (e.g. an in-flight branch the agent didn't see), record it in context.json.parallel_tracks or context.json.handoff before rerunning — STATUS overwrites on every run, manual edits inside STATUS.md will not survive
3. Decide: is this status snapshot ready to share with the team, or does context.json need a refresh first via /bridge-context?
```

$ARGUMENTS
