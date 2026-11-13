# BRIDGE Relay

Relay carries a selection of slices through an independent gate, at most two repairs and the
automated evaluation, then hands it back to you for acceptance. A producer session and a
reviewer session hand the work back and forth through commits instead of through you.

The kit is three files in `.bridge/relay/`, installed and updated by `bridge.sh` with the rest
of `.bridge/`:

| File | What it is |
|---|---|
| `.bridge/relay/README.md` | This page: the entries, the producer and reviewer steps, and what to do if a side can't wait. |
| `.bridge/relay/ready-to-audit-template.md` | The request the producer fills in and commits as `docs/reviews/<slice>-ready-to-audit.md`. |
| `.bridge/relay/wait.sh` | A read-only Bash 3.2 script that waits for the next commit, on any ref but `refs/stash`, that changes a path. |

There is no coordinator, daemon or state file. The request file and the commits are the whole
protocol.

## Entries

Use `/bridge-start` and `/bridge-gate` in Claude Code, `$bridge-start` and `$bridge-gate` in
Codex:

| Command | Side | What it does |
|---|---|---|
| `bridge-start with-relay <selection>` | producer | Builds the selection without approval pauses, then follows the producer steps. |
| `bridge-start start-relay <selection>` | producer | For work already built (after a plain `bridge-start`, or a `with-relay` run that stopped before committing its request): follows the producer steps. Its slices may already be at `review`; the other Selection checks still apply. |
| `bridge-gate with-relay <selection>` | reviewer | Follows the reviewer steps: gates a committed request, or waits for one. It may start before the build finishes. |

Give both sessions the same selection. In another harness, ask the agent to follow the
producer or reviewer steps below for that selection. There is no `bridge-eval with-relay`:
after a passing gate, the ordinary eval with the same selection resumes evaluation. To resume
a repair wait, start the reviewer again; it reads the request log and does not reset the
two-repair limit.

When the run ends, read the producer's HUMAN block, the gate report and the eval scenarios,
then accept (optionally with deferrals) through `/bridge-feedback` or `$bridge-feedback`, or
report issues. The reviewer leaves one gate worktree per round under `.claude/worktrees/`;
remove them yourself when you're done.

## Selections

`<selection>` is one slice or a comma-separated list such as `S14-15,S17`, with the syntax and
checks in the slice-plan procedure's Selection section. In the steps below, `<slice>` stands
for the selection's report ID: consecutive runs collapse to their first and last ID joined by a
hyphen and separate runs join with an underscore (`S14-S15_S17`, `S75-S79`); a single slice is
its own ID. The request lists the explicit slices, features and acceptance tests, and the gate
judges exactly those. Before the request, every selected slice's verify and smoke scripts pass
along with the `commands_to_run` entries.

## When to use it

- The work's checks pass, or will after the build, and you want an independent gate by a
  different harness or model, followed by the eval.
- Both sessions work in the same repository on the same machine. Any harness that can run
  shell commands can take either side.

## Producer steps

```text
<slice> is the selection's report ID (see Selections). Start each wait.sh in the background so you can
act when it exits.

1. After every commands_to_run entry passes, fill docs/reviews/<slice>-ready-to-audit.md
   from .bridge/relay/ready-to-audit-template.md with the full submitted SHA and commit it.
   Before the request commit, commit every change to the slice's paths and the ledgers,
   so nothing under them is uncommitted.
   Then wait with .bridge/relay/wait.sh for docs/reviews/<slice>-gate-report-r<n>.md, where n
   is the number of the request log row you committed:
   bash .bridge/relay/wait.sh docs/reviews/<slice>-gate-report-r<n>.md --after <SHA of the request commit>
2. Read each report at the SHA wait.sh printed: git show <sha>:<path>. On PASS,
   including PASS WITH WARNINGS, wait the same way for
   docs/reviews/<slice>-eval-scenarios.md, with --after <SHA of the report commit>.
3. On a gate FAIL or an eval product failure, repair only within the slice: fix what the
   findings name, re-run the checks, commit and append a re-gate row with the new full SHA
   to the request log, commit it, and wait as in step 1 for the next round's file.
   Do this at most two times.
4. Stop and report on the limit, a disputed requirement, a needed scope change or a timeout
   (wait.sh exit 3), on any other non-zero wait.sh exit (1 or 2), and on an eval failure
   that is not a product failure.
5. Commit locally on the current branch only, and only this slice's paths, the ledgers and
   the request. Never edit the gate report, the eval outputs or the gate-owned fences in
   tests/slices/<slice>-*.sh. Never push, tag, reset, revert, remove a worktree or record
   acceptance.
6. When the eval passes, end with a HUMAN block that says first whether anything blocks
   acceptance, then names each human-only check by its heading under the gate report's
   Human-only checks section with its Where and first step, then gives the two choices with
   the acceptance command: perform the checks first, or accept with them recorded as
   deferred through /bridge-feedback or $bridge-feedback, naming the gate report and the
   eval scenarios.
```

## Reviewer steps

```text
<slice> is the selection's report ID (see Selections). Start each wait.sh in the background so you can
act when it exits.

1. Note the HEAD SHA, then check it: unless docs/reviews/<slice>-ready-to-audit.md is
   committed there with a request log row you have not gated yet, wait with .bridge/relay/wait.sh
   for the request:
   bash .bridge/relay/wait.sh docs/reviews/<slice>-ready-to-audit.md --after <HEAD SHA at your check>
   A missing, uncommitted or unfinished request means the producer is still working: start
   that wait at once and never stop to ask the operator whether to wait.
2. Follow the request in its last row: run the Independent gate in a scratch worktree at
   the submitted SHA, re-running every commands_to_run entry there. Use a fresh worktree
   path for each round, such as .claude/worktrees/gate-<slice>-<n>. Port the outputs as
   the gate procedure says, but skip its cleanup step and leave the worktree for the
   operator to remove. The producer's totals and the main checkout are not evidence.
   Once the request has arrived, name the gate report and the eval with the request
   file's prefix, the part of its name before -ready-to-audit.md, instead of recomputing
   the ID. The gate report of round n is docs/reviews/<slice>-gate-report-r<n>.md, n being
   the number of the request log row you act on; never edit or replace an earlier round's
   file.
3. Commit only the gate report, its context entries and gate-owned fences, never product
   files. Findings go in the report. If docs/context.json has uncommitted changes before
   you add your entries, stop and report.
4. After a pass, including PASS WITH WARNINGS, run the eval and commit its outputs the same
   way.
5. Then wait for the next re-gate row and gate it the same way:
   bash .bridge/relay/wait.sh docs/reviews/<slice>-ready-to-audit.md --after <SHA of your last commit>
   Stop after an eval that passes, or when a wait times out (exit 3).
6. Commit locally on the current branch only. Never push, tag, reset, revert, remove a
   worktree or record acceptance.
```

## If a side can't wait on its own

Some harnesses can't keep a background command running, or aren't re-invoked when it exits.
Grok Build may be one of them; the live run records which side waited on its own.

- **Reviewer:** start it, or restart it, with the same command once the request is committed.
  Its first step sees the committed request and gates it right away. Do the same after each
  re-gate row.
- **Producer:** once the gate report or the eval scenarios are committed, tell it to continue
  the Relay run. It reads the report at the commit that added it and goes on from the step
  it was waiting in.

Either way you start a session, but you no longer carry results between them.

## .bridge/relay/wait.sh

`bash .bridge/relay/wait.sh <path> [--after <sha>|none] [--interval-sec N] [--timeout-min N]`

- Prints `<full SHA> <subject>` of the newest commit, on any ref but `refs/stash` or on a
  worktree HEAD, that changes `<path>` and is not old, then exits 0. A `git stash` never
  ends a wait.
- Old means: reachable from a ref or HEAD when the wait started (default); `<sha>` and its
  ancestors (`--after <sha>`); nothing (`--after none`). With `--after <request commit>`, a
  report committed before the wait started still counts. So does a matching commit on any
  ref other than `refs/stash`, including one on another branch that isn't an ancestor of
  `--after`.
- It checks every 60 seconds and exits 3 after 12 hours (720 minutes) by default. A missing or
  invalid argument, or a directory outside a Git work tree, exits 2.
- It is read-only. It runs `git rev-parse`, `git rev-list` and `git log` only, never
  `git status` or `git fetch`, and needs nothing but Bash and Git.

## Authority

Running a Relay entry is your live instruction for that run. It authorizes local commits on the
current branch, limited to that run's paths: the slice's files, the ledgers and the request
for the producer; the gate report, the eval outputs, their context entries and the gate-owned fences
for the reviewer. It never authorizes a push, a tag, a reset, a revert, removing a worktree or
recording acceptance. A finished run is not acceptance: you accept through the feedback
procedure, and missing human observations stay unobserved.

## The live run

The kit's tests check only its files and `wait.sh` in disposable repositories. Whether each
side waited on its own in a real run, and how many handoffs you still made, is something to
observe and record yourself, never something to infer from those tests.
