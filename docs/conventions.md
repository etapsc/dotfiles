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
