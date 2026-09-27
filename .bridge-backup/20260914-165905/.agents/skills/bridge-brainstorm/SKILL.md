---
name: Bridge Brainstorm
description: "Phase 0: Brainstorm a new project idea using BRIDGE methodology. Invoke with $bridge-brainstorm in your prompt."
---

You are following the BRIDGE v2 methodology for solo-preneur software development with AI dev teams.

BRIDGE = Brainstorm → Requirements → Implementation Design → Develop → Gate → Evaluate

Simulate these roles in one response:
- **Product Strategist** - market potential, monetization, risks, positioning
- **Technical Lead** - feasibility, integration paths, scalability

## TASK - PHASE 0: BRAINSTORM

I want to brainstorm an idea for: **$ARGUMENTS**

`bridge-brainstorm` is mode-aware. Pick the mode from the CONTENT of the request
and the current workspace state — never from a flag — then emit that mode's
output block. State the chosen mode at the top of your output with a
`#### Selected Mode: <Name>` header (mirrors `bridge-scope`'s precedent).

## Mode Selection (content-driven)

`<Name>` MUST be one of these four literals: `Greenfield`, `Existing-Workspace`,
`Parallel`, `Synthesis`. Choose using these rules:

- **Greenfield** (default) — context is empty/greenfield, or the request is a
  brand-new product/project idea with no existing BRIDGE workspace to protect.
  When in doubt for a fresh idea, default here.
- **Existing-Workspace** — the request is to brainstorm product, factory, or
  portfolio ideas INSIDE an existing BRIDGE workspace (requirements.json /
  context.json present), and the operator is not asking for per-agent parallel
  prompts or a synthesis of prior outputs.
- **Parallel** — the operator asks for multiple simultaneous agents, per-agent
  prompts, fan-out brainstorming, or "run N brainstorms at once."
- **Synthesis** — the operator supplies (or points at) multiple existing
  brainstorm outputs and asks to compare, rank, or pick a direction.

If the request is ambiguous between Existing-Workspace and Parallel, prefer
Existing-Workspace and state the assumption in the `Selected Mode:` header.

## Boundary Rules (govern all non-greenfield modes)

1. **No canonical writes.** `bridge-brainstorm` does NOT write or edit any
   canonical BRIDGE doc: `docs/requirements.json`, `docs/context.json`,
   `docs/decisions.md`, `docs/STATUS.md`, `docs/project-brief.md`. Those are
   edited only with explicit operator approval, by the commands that own them
   (`$bridge-requirements`, `$bridge-plan-feature`, `$bridge-integrate-design`,
   etc.). Brainstorm never allocates Fxx/ATxx/Sxx IDs.
2. **Scratch outputs only, opt-in.** Any optional written output goes ONLY under
   the dated scratch directory below. Writing scratch files is optional — offer
   it, do not assume it.
3. **Phase 0 ideation only.** Parallel mode produces ideation prompts, not
   parallel execution/implementation planning. It must not imply concurrent
   agents may safely write canonical docs or run implementation.
4. **Feature exploration stays in `$bridge-scope`.** Existing-project FEATURE
   scoping/exploration is owned by `$bridge-scope`. Existing-Workspace mode here
   is for product/factory/portfolio IDEATION, not feature impact analysis. When
   the operator wants to scope a concrete feature, route them to `$bridge-scope`.

### Scratch directory convention

Optional scratch outputs live ONLY at this literal path shape:

```
docs/ideas/brainstorm/YYYY-MM-DD/<unique-topic>.md
```

- `YYYY-MM-DD` is today's date. `<unique-topic>` is a short kebab-case slug
  unique within that day's folder.
- In parallel mode, each parallel agent owns exactly ONE such file — no two
  agents write to the same file. One topic → one file → one owner.
- `docs/ideas/` is NOT a canonical BRIDGE doc location; it is scratch space,
  created lazily only when the operator opts into writing a scratch file.

---

## Mode 1 — Greenfield idea mode (DEFAULT)

Output format:

### Phase 0 - Brainstorm Results

#### Selected Mode: Greenfield
[1-2 sentences on why greenfield fits this request and the current workspace state]

#### Elevator Pitch
[1-2 sentences]

#### Wedge + Kill Criteria
- **Wedge:** What narrow initial use-case wins first and why
- **Kill Criteria** (2-4 bullets): What would make us stop within 1-2 weeks

#### Project Description
[2-3 paragraphs. Clear enough for a human AND usable as LLM context in subsequent prompts.]

#### High-Level Architecture & Stack
- 5-10 bullets: components + rationale
- Build vs Buy shortlist (top 3 dependency decisions)

#### Market Analysis
- **Target Audience / ICP:**
- **Competitors / Alternatives:**
- **Differentiators:**
- **Risks:**

#### Launch Strategy
- **Key Messages:**
- **Channels:**
- **Launch Hooks:**
- **Timeline:** (brief)

Then end with the greenfield HUMAN block:

```
HUMAN:
1. Review the brainstorm — does the wedge feel compelling enough to continue?
2. Check kill criteria — are any already triggered?
3. Decide: proceed to $bridge-requirements, refine the idea, or kill it
```

---

## Mode 2 — Existing-Workspace / Orchestrator mode

For brainstorming product, factory, or portfolio ideas inside an existing BRIDGE
workspace WITHOUT mutating canonical BRIDGE docs.

### Phase 0 — Existing-Workspace Brainstorm (NO CANONICAL WRITES)

#### Selected Mode: Existing-Workspace
[1-2 sentences on why this mode fits + which canonical docs are being protected]

#### Workspace Context (read-only)
[Brief read-only summary of current product/portfolio state pulled from
requirements.json/context.json — observations only, nothing written back]

#### Ideas Explored
[Product / factory / portfolio idea options, each with a one-line framing]

#### Tradeoffs & Fit
[Per-idea: what is gained, what is given up, how it fits the current workspace]

#### Boundaries Respected
- No edits to docs/requirements.json, docs/context.json, docs/decisions.md,
  docs/STATUS.md, or docs/project-brief.md.
- For concrete feature scoping, use $bridge-scope, not this mode.

#### Optional Scratch Output
[If the operator wants this captured, offer to write
docs/ideas/brainstorm/YYYY-MM-DD/<unique-topic>.md — opt-in only]

#### Recommended Next Command
[e.g. "Run $bridge-scope to scope a concrete feature", or
"Run $bridge-requirements to formalize a new product", or
"Re-run $bridge-brainstorm in synthesis mode once you have multiple outputs"]

Then end with a HUMAN block:

```
HUMAN:
1. Review the ideas explored against the protected workspace state.
2. Decide whether to capture any idea as an opt-in scratch file under docs/ideas/brainstorm/YYYY-MM-DD/.
3. Pick the recommended next command (e.g. $bridge-scope or $bridge-requirements) — nothing canonical is written until you do.
```

---

## Mode 3 — Parallel brainstorm mode

Produces safe per-agent prompts and scratch-output rules for multiple
simultaneous agents. This is Phase 0 ideation fan-out, NOT execution planning.

### Phase 0 — Parallel Brainstorm Setup (IDEATION ONLY)

#### Selected Mode: Parallel
[1-2 sentences on why parallel fits + how many agents/topics]

#### Per-Agent Assignments
[A table or list. Each agent gets exactly ONE unique topic and ONE unique
output file:]
- Agent 1 — Topic: <topic-a> — Output file: docs/ideas/brainstorm/YYYY-MM-DD/<topic-a>.md
- Agent 2 — Topic: <topic-b> — Output file: docs/ideas/brainstorm/YYYY-MM-DD/<topic-b>.md
- ...

#### Per-Agent Prompt Template
[A ready-to-paste prompt each agent runs. The prompt MUST instruct the agent to
write ONLY to its assigned docs/ideas/brainstorm/YYYY-MM-DD/<unique-topic>.md
file, and to make NO edits to any canonical BRIDGE doc.]

#### Safety Rules (MUST state all)
- No edits to canonical BRIDGE files (requirements.json, context.json,
  decisions.md, STATUS.md, project-brief.md) unless explicitly approved.
- Optional scratch files ONLY under docs/ideas/brainstorm/YYYY-MM-DD/.
- Each parallel agent owns exactly ONE unique topic/output file — no shared files.
- This is ideation only, not parallel execution or implementation planning.
- Final synthesis is a SEPARATE step (run $bridge-brainstorm in synthesis mode).

#### Recommended Next Command
[After agents finish: "Run $bridge-brainstorm in synthesis mode over the
docs/ideas/brainstorm/YYYY-MM-DD/ outputs"]

Then end with a HUMAN block:

```
HUMAN:
1. Confirm each parallel agent has exactly one unique topic and one output file under docs/ideas/brainstorm/YYYY-MM-DD/.
2. Dispatch the per-agent prompts (ideation only — no canonical writes, no implementation).
3. When agents finish, run $bridge-brainstorm in synthesis mode over their outputs.
```

---

## Mode 4 — Synthesis mode

Consumes multiple brainstorm outputs and produces a ranked slate with tradeoffs
and a recommended next command, WITHOUT converting alternatives into
Fxx/ATxx/Sxx entries.

### Phase 0 — Brainstorm Synthesis (RANKED SLATE — NOT YET COMMITTED)

#### Selected Mode: Synthesis
[1-2 sentences on which outputs were consumed]

#### Inputs Consumed
[List the brainstorm outputs / scratch files synthesized, e.g.
docs/ideas/brainstorm/YYYY-MM-DD/*.md or pasted outputs]

#### Ranked Slate
[Ordered list, strongest first. Each entry: rank, one-line description, and the
single biggest reason it ranks where it does:]
1. <Option> — [why #1]
2. <Option> — [why #2]
3. <Option> — [why #3]

#### Tradeoffs
[Per ranked option: what is gained, what is given up, what is uncertain]

#### Recommended Next Command
[ONE next step, e.g. "Run $bridge-requirements with option 1", or
"Run $bridge-scope on option 2", or "Re-run synthesis after another parallel pass"]

#### Boundary
This slate is exploratory and NOT YET COMMITTED. It allocates NO Fxx/ATxx/Sxx
IDs and writes NO canonical BRIDGE docs. Requirements move only when the operator
runs the recommended formalization command.

Then end with a HUMAN block:

```
HUMAN:
1. Review the ranked slate and its tradeoffs — the slate is NOT YET COMMITTED and allocates no Fxx/ATxx/Sxx.
2. Pick exactly ONE ranked option to carry forward.
3. Run the recommended next command (e.g. $bridge-requirements or $bridge-scope) on that option to formalize it.
```
