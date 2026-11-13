# BRIDGE Folder Conventions

This file is the canonical reference for what belongs in each `docs/`
subdirectory. BRIDGE skills, agents, and tests all assume this taxonomy.

## Taxonomy

| Path | Purpose | Lifetime | Owner |
|------|---------|----------|-------|
| `docs/vision/` | Strategic direction, north-star intent, product positioning. Rare, durable. | Long-lived; rewritten at version boundaries. | Human operator (sometimes co-authored with `bridge-advisor`). |
| `docs/designs/` | Workstream-level WHAT: the shape of a multi-slice effort, system surface, integration story. One doc per workstream or theme, not per slice. | Long-lived; updated with Status notes as workstreams evolve. | `bridge-architect` (after S31 whitelist widening). |
| `docs/plans/` | Per-slice HOW: the concrete plan that turns a slice into code. One doc per slice (e.g. `Sxx-<topic>-plan.md`). | Slice-scoped; superseded once the slice lands. | `bridge-architect` (after S31 whitelist widening). |
| `docs/contracts/` | Long-lived interface specs: schemas, API contracts, data shapes that outlast any one slice. | Durable; versioned alongside the interface they describe. | `bridge-architect`. |
| `docs/process/` | Coordination artifacts: playbooks, gate reports, eval scenarios, handoff notes that govern HOW the team operates. | Mixed; gate/eval artifacts are per-slice, playbooks are durable. | Skills (`bridge-gate`, `bridge-eval`) and human operator. |
| `docs/decisions.md` | Append-only ADR log. One entry per architectural decision. Format: `YYYY-MM-DD: <decision> - <rationale>`. | Permanent; never edit past entries, only append. | `bridge-architect`, `bridge-end`, and any agent or operator making a decision. |
| `docs/requirements.json` | Controlled intent (`bridge.v2` schema): scope, features (`Fxx`), acceptance tests (`ATxx`), user flows (`UFxx`), recommended slices (`Sxx`), constraints, open questions. | Durable; scope, features, tests and slices change only through the requirements and feature commands, never rescoped silently. `bridge-context` may add `execution.open_questions` entries (see Records). | Requirements commands (`bridge-requirements`, `bridge-plan-feature`, `bridge-integrate-design`) and, for open-question entries only, `bridge-context`; the human operator approves scope. |
| `docs/context.json` | Current as-built state: feature status, current and next slice, handoff, `commands_to_run`, quality gates, open discrepancies. Includes recorded slice/gate/eval/feedback histories in the current single-file format. | Durable; updated after every significant change. Not a place for narrative. | Every command that changes project state (`bridge-start`, `bridge-end`, `bridge-gate`, `bridge-eval`, `bridge-feedback`, `bridge-context`). |
| `docs/archive/` | Older parts of `docs/context.json` and `docs/requirements.json`, split off by `.bridge/tools/archive.py` into `<doc>-NNN.json` files (a higher number is newer). Same schema as the current files, marked `"doc_state": "archived"` and chained by `previous_doc`. Agents follow the chain only when an item is not in the current file, or before allocating a new ID. | Permanent archive; never edited except to move an item back into the current file. | `.bridge/tools/archive.py`, run by the human operator. |
| `docs/history/` | Reserved path from the earlier context-history proposal. Not created or used by v3.0.2; the planned sharding design may choose a different layout. | Unimplemented candidate, not current storage. | No current writer; future design defines ownership. |
| `docs/bridge-memory.json` | Standing operator rules (`bridge.memory.v1` schema): the rulings, conventions and lessons in force now, as `D-CONV-n` rules, plus one `last_run` entry per agent harness. State, not a log: git history is its log and `docs/decisions.md` keeps the decision history. | Durable; created lazily by the first `bridge-persist` run, never by install or update. New rules are added directly; changes and removals only after the operator confirms. | `bridge-persist`, run in each agent harness; the human operator confirms changes. |
| `docs/issues/` | Long form of one discrepancy or open question (see Records): `YYYY-MM-DD-<ID>-<topic>.md`, holding the options, evidence tables and close-out steps that do not fit the entry. A repository may keep the folder private and excluded from exports. | Follows its entry's status; the file stays in place when the entry is archived. | The agent or operator who opens the entry; the Status line moves with the entry. |
| `docs/designs/evidence/` | Designs that are no longer inputs — superseded, or their cycle closed. Retained as history: they inform, they never veto, and they are never authority — the code and `docs/context.json` are. | Permanent archive. | Human operator (moves the design when it stops being an input). |
| `docs/proposals/` | Pre-commitment: scope reviews, direction proposals, critiques. Graduates into `docs/designs/` or is superseded. Harvested from quorum. | Short-lived; promoted or superseded, rarely edited in place. | Human operator, and any agent asked to write one. |
| `docs/proposals/archive/` | Proposals that already have a design and are ready to implement or already delivered. History only; not a current input. | Permanent archive. | Human operator (moves the proposal when it leaves pre-commitment). |
| `docs/reviews/` | Review evidence: gate reports (`<slice-range>-gate-report.md`), eval scenarios (`<slice-range>-eval-scenarios.md`), feedback (`<slice>-feedback.md`), plus the live eval catalog and feedback template. Renamed from `gates-evals/` in v3.0.0. Current format: one report per scope/slice range, read by name when needed; sharding is not implemented. | Permanent; a report is a closed record once written. | `bridge-gate` (`bridge-gate-audit` skill / `bridge-auditor` subagent) and `bridge-eval` (`bridge-eval-generate` skill / `bridge-evaluator` subagent); the operator files feedback here. |
| `docs/project-knowledge.md` | Input-side project knowledge for onboarding: purpose/domain, glossary, architecture map, stack/constraints, external doc index, known unknowns, ingested-sources provenance. | Durable; operator-owned after first fill, refreshed by context commands only on new sources or explicit request. | Operator + `bridge-context`. |
| `docs/project-knowledge-digests/` | Dated per-source or per-topic digests feeding `docs/project-knowledge.md`. Snapshots, never status: finding labels stay local to the digest and are cited as `<digest>#<label>`. May hold a `<digest>-notes/` working folder. | Permanent dated snapshots; a new source gets a new digest, an old one is not edited. | Operator + `bridge-context`. |
| `docs/project-brief.md` | Derived outward explanation of the project for readers outside the loop, generated from requirements, context and code. | Regenerated whole; never hand-merged. | `bridge-project-brief`. |
| `docs/operator-guide.md` | Operations: which tool to reach for, what writes where, how the loop runs in this repo. Optional. Harvested from normandy. | Durable; operator-owned. | Human operator. |
| `docs/human-playbook.md` | Manual verification checklists for the operator: per-slice verification steps, files to inspect, common pitfalls. | Durable; a row is appended per planned slice. | `bridge-requirements` (generate), `bridge-plan-feature` / `bridge-integrate-design` (append rows). |
| `docs/conventions.md` | This taxonomy. Shipped byte-identical in every pack; extended per repo. | Durable; an existing copy is never overwritten by `bridge.sh update`. While the file still carries a template section heading, an update appends a missing base row under its section and a missing template section whole; existing rows are never rewritten (a differing base row is reported). | BRIDGE (base rows) + human operator (local rows). |
| `docs/STATUS.md` | Current status snapshot, laid out by version, derived from `docs/requirements.json` and `docs/context.json`. | Regenerated; not hand-edited. | `bridge-status`. |
| `docs/*-release-notes.md` | Shipped changes and upgrade guidance, distinct from current state. | Release history; dated amendments preserve the original disposition. | Release/documentation maintainer. |
| `docs/STATUS-<range>.md` | Archived status for closed version ranges, moved out of `docs/STATUS.md` when the window rolls. | Permanent archive. | Human operator (split by hand when the window rolls). |
| `docs/ideas/` | Scratch: brainstorm output (e.g. `docs/ideas/brainstorm/YYYY-MM-DD/`), RFC drafts. Not canonical, not read by default. | Ephemeral; deleted, or promoted into `docs/proposals/` / `docs/designs/`. | `bridge-brainstorm` and the human operator. |
| `docs/bridge-ids.conf` | Opt-in to shared ID reservation for a team: one committed file holding `ref=bridge-ids` and, optionally, `remote=<name>` (default `origin`), nothing else. With it, new F, AT, S, UF, R and OQ numbers (open questions whose `id` is OQ and digits) come from the orphan counter branch `bridge-ids`, whose one file `ids` holds a `SERIES=N` line per series (the last number taken), instead of highest+1. Reserved IDs print with at least two digits (`F03`). A counter made before OQ was added gets its `OQ=N` line on the next reservation or `--sync`; from then on every clone needs a `reserve-ids.sh` that knows OQ (`bridge.sh update`). D numbers and open-question IDs of other forms are not reserved. Hand protocol, no agent pack needed: (1) before writing any numbered record, reserve with `bash .bridge/tools/reserve-ids.sh F=1 AT=3 S=1 -m "<title>"`, or by hand in a separate clone: `git fetch origin bridge-ids`, check out `FETCH_HEAD`, add your counts to `ids`, commit and `git push origin HEAD:bridge-ids` without force (a rejected push means someone reserved first: fetch, recount, retry; only a pushed commit confirms); (2) give the reserved IDs to whoever writes the records, agent or person; that instruction outranks any highest+1 text; (3) reserve what you expect, reserve more if short; unused numbers stay burned and are never reused; (4) read the history with `git fetch origin bridge-ids && git log FETCH_HEAD`. Setup: one person runs `bash .bridge/tools/reserve-ids.sh --init` (it seeds the counters from every pushed branch, so push open branches first) and commits this file. Hosting is described here, never configured by the toolkit: give `bridge-ids` its own branch rule that only blocks deletion and force-push (a rule over all branches that requires pull requests, signed commits or linear history rejects every reservation), and exclude it from CI push triggers (`branches-ignore`). Each repository runs its own counter branch. | Durable; committed by the operator when the team opts in, deleted to opt out. Absent means highest+1. Never created by install or update. | Human operator; read by `.bridge/tools/reserve-ids.sh` and the planning commands (`bridge-plan-feature`, `bridge-integrate-design`). |

## Designs vs. Plans (the distinction that matters)

A `design` answers "what is the shape of this workstream?" — system surface,
contracts touched, the cross-slice story. A `plan` answers "for this one
slice, what files change and in what order?" If you find yourself writing a
design that only covers one slice, it is probably a plan. If you find
yourself writing a plan that spans multiple slices, it is probably a design.

## Decisions vs. Designs

`docs/decisions.md` records what was decided and why, in one or two
paragraphs. `docs/designs/` records how the decided shape will be realised.
A design references the decisions that constrain it; a decision does not
reproduce the design.

## Lazy creation

`docs/contracts/` is created at install time because contracts are needed
from slice 1. `docs/designs/`, `docs/plans/`, `docs/process/`, and
`docs/vision/` are created lazily when their first artifact lands. Do not
pre-create empty directories.

## Records: what goes where

One rule for unsettled items: file each by what closes it. Entries stay short;
anything longer than a paragraph goes to an issue file.

| Item | Test | Lives in | Closes with |
|------|------|----------|-------------|
| Open question (OQ) | Someone must decide what we want | `docs/requirements.json` `execution.open_questions` | an entry in `docs/decisions.md`; `status` answered or withdrawn |
| Discrepancy (D) | Two sources disagree, or the product is wrong | `docs/context.json` `discrepancies` | a fix to one side, a won't-fix or a superseding entry; `status` leaves open |
| Issue file | A D or OQ needs more than a paragraph | `docs/issues/YYYY-MM-DD-<ID>-<topic>.md` | follows its entry; its Status line changes in the same commit |
| Blocker | It stops the current slice | `docs/context.json` `blockers` (the shipped template carries the key; a ledger without it has none) | the slice can proceed |
| Watch-out | A hazard with an expiry condition: an item closing, an observation recorded, a revision no longer read by any check | `docs/context.json` `handoff.watch_out` | that condition is met, whether or not its feature is done |
| Standing rule | Applies to all future work; nothing expires it | `docs/bridge-memory.json` (`D-CONV-n`) or a row in this file | the operator changes it |
| Decision | An answer and its reason | `docs/decisions.md`, anchored | never; a later entry supersedes it |
| Finding | Seen in a dated digest or review report | that digest or report, under its own label | promoted to a D when it needs tracking; otherwise it stays where it was seen |

**Discrepancy fields**, all present in every entry: `id` (`Dnn`), `kind`, `status`,
`opened`, `observed_revision`, `summary`, `evidence_paths`, `proposed_fix`, `resolved_on`,
`resolution`, `owner_repo`, `cross_repo` and `links` with `oq`, `features`, `issue_file`
and `findings` (`<digest-or-report>#<label>`). `kind` is one of `code-vs-requirements`,
`code-vs-context`, `docs-vs-code` (any other document against the code), `defect` (no
document is wrong, the product is) or `process` (ci, release, governance, tooling). A defect
with no feature yet is a D first; once a feature is planned it links it and closes when the
feature is done.

**Open-question fields:** `id`, `topic`, `status`, `default`, `answered_on`,
`decision_pointer` (`docs/decisions.md#<anchor>`); optional `answer`, `decide_by`,
`resolution_owner`, `blocks_slices`, `issue_file`. If closing a D needs a decision, link one
OQ and keep the options only there.

**Status words.** Discrepancy: `open`, `resolved`, `wont-fix`, `superseded`. Open question:
`open`, `answered`, `withdrawn`. The date goes in `resolved_on` / `answered_on` and the
reason in `resolution` / `decision_pointer`, never in `status`. Closed means a status in the
vocabulary other than `open` (the archive tool's contract in the BRIDGE repository,
`docs/contracts/archive-split.md` there; packs do not ship it).

**IDs from another repository** are written `repo:ID` (`supernode-dev:D12`), one prefix per
listed ID and one per range (`supernode-dev:D07–D11`); this repository's own IDs stay bare.
Pull requests are not BRIDGE IDs: `repo #nnn`, or `#nnn` for this repository. An item two
repositories track has one owner, where it is decided and where the issue file lives:
`owner_repo` names it and `cross_repo` lists the related `repo:ID (note)` entries.

**Issue files** are the long form of one D or OQ, one file per entry, named by date and ID.
The first lines are `# <ID> — <topic>` and `**Status:** <word>`; the JSON entry is
authoritative and the Status line changes in the same commit. A repository may keep the
folder private and excluded from exports.

**Watch-outs** name their hazard and its expiry condition and leave when that condition is
met, whether or not their feature is done. An entry with no expiry condition is a candidate
standing rule: offer it to `bridge-persist` or as a row in this file; never move it
automatically.

## Per-slice verification scaffolding

BRIDGE ships an executable per-slice verification layer alongside the `docs/`
taxonomy. It is pack-agnostic (byte-identical across packs and the repo root)
and BRIDGE-managed.

| Path | Purpose | Lifetime | Owner |
|------|---------|----------|-------|
| `.bridge/verify.mk` | Makefile include defining the `verify` / `eval` / `test-slice` targets, delegating to the runners. | Durable; BRIDGE-managed (preserved on update). | BRIDGE. |
| `.bridge/lib/runner-lib.sh` | Shared `bridge_run` / `bridge_summary` / `bridge_no_scripts_notice` helpers sourced by the runners. | Durable; BRIDGE-managed. | BRIDGE. |
| `.bridge/fence-template.txt` | The fence/marker spec the agents follow when writing per-slice scripts. | Durable; BRIDGE-managed reference. | BRIDGE. |
| `tests/slices/` | Per-slice executable verification: `<slice>-{verify,smoke,eval}.sh`. `*-verify.sh` = build/format/lint/static; `*-smoke.sh` = slice behavior; `*-eval.sh` = real user-facing scenario commands (not a test-suite re-run). Producer (coder/debugger) and gate (gate-audit) co-own `*-verify.sh`/`*-smoke.sh` via distinct fenced managed blocks; eval-generate owns `*-eval.sh`. | Slice-scoped; one file set per slice. | BRIDGE agents. |
| `tests/run-verify.sh` / `tests/run-eval.sh` / `tests/test-slice.sh` | Runners that execute the matching `tests/slices/*` scripts. Run via `make verify` / `make eval` / `make test-slice SLICE=Sxx`. | Durable; BRIDGE-managed. | BRIDGE. |
| `tests/ledger-check.sh --ids` | Duplicate-ID check (F70, F71), callable on its own from CI: fails when one F, AT, S, UF, R or OQ ID is defined twice in docs/requirements.json and its previous_doc chain (definition sites only, open questions by their `id`; numbers compare by value, so `F3` and `F03` are one ID; references never count). One-line CI call on a pull request's merge result: `bash tests/ledger-check.sh --ids` (bash and python3; exit 0 with one OK line, 1 with one FAIL line per duplicate or broken chain). `make ledger-check` runs the same check as one more FAIL line; `make verify` does not. | Durable; BRIDGE-managed (part of the ledger-check script, refreshed on update). | BRIDGE. |
| `tests/ledger-check.sh` | Producer pre-flight (F66): docs/context.json at or under 212 KiB, recent_decisions at most 5, handoff.watch_out at most 20, and a non-empty verify or smoke script for every slice named on the command line. Run via `make ledger-check SLICES="Sxx Syy"`; the Relay request records its output and the gate reads it as a warning, never a blocker. | Durable; BRIDGE-managed (refreshed on update). | BRIDGE. |

`tests/e2e/` remains the project's own test framework; the per-slice runners are
additive and start empty (a fresh install exits 0 with a "no slice scripts yet"
notice until the first slice seeds a script).

## Tooling outside docs/

Paths BRIDGE ships or writes outside `docs/` that are not the per-slice verification layer.

| Path | Purpose | Lifetime | Owner |
|------|---------|----------|-------|
| `.bridge/tools/` | `archive.py`, the one tool that splits the ledgers into `docs/archive/` (see Archived records). | Durable; BRIDGE-managed. | BRIDGE; run by the human operator. |
| `.bridge/relay/` | The Relay kit: `README.md`, `ready-to-audit-template.md`, `wait.sh`. Producer and reviewer sessions hand slices through commits; no daemon or state file. | Durable; BRIDGE-managed. | BRIDGE. |
| `.ai-local/` | Personal harness extensions per developer, each under `.ai-local/<name>/`; `.ai-local/index.md` is the optional pointer the entrypoint reads. Gitignored except the shipped `README.md`. | Local; never committed, never rewritten by update (the README is added when absent). | Each developer. |
| `.bridge-backup/` | Timestamped copies (`<UTC stamp>/`) of the files `bridge.sh update` replaced in that run. | Ephemeral; read by nothing. Delete or ignore once the update is checked. | `bridge.sh update` writes it; the human operator prunes it. |

## Plans vs. Requirements and Context

`docs/requirements.json` is canonical scope and `docs/context.json` is
canonical state. A plan references their IDs — `Fxx`, `ATxx`, `Sxx` — and
reads them for truth. It does not restate feature status, acceptance results
or gate verdicts. A plan that starts tracking status has become a competing
status record; the canonical files win. Update the JSON, not the plan.

## Archived records

`docs/context.json` and `docs/requirements.json` may be split with
`.bridge/tools/archive.py`: old items move into `docs/archive/<doc>-NNN.json` with
the same schema, and each file's `previous_doc` names the next older file. Write
only to the current files. Reviews stay in `docs/reviews/` and are not archived.
