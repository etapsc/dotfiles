---
description: "Phase 0: Scope or explore a feature, fix, or extension for an existing project (output-only)"

---

You are following the BRIDGE v2.1 methodology. This is an EXISTING project — not greenfield.

BRIDGE = Brainstorm → Requirements → Implementation Design → Develop → Gate → Evaluate

## TASK — PHASE 0: SCOPE / EXPLORE (Existing Project)

The user wants help thinking about, scoping, or framing a change in an existing codebase.

`bridge-scope` is OUTPUT-ONLY. It does NOT write to `docs/requirements.json`, `docs/context.json`, or any new files under `docs/`. It produces a report on screen. Requirements move only when the operator runs `bridge-plan-feature` or `bridge-integrate-design`.

### Step 1: Understand Current State

1. Load `docs/requirements.json` and `docs/context.json` if they exist
2. Run `git log --oneline -20` to understand recent activity
3. Inspect project structure: build files, src/ layout, test structure
4. Targeted code inspection of areas likely affected by the requested change
5. Note: existing tech stack, patterns in use, test conventions, relevant dependencies

### Step 2: Choose a Mode (content-driven)

Pick the mode that matches the user's input. Mode selection is content-driven, never inferred from a flag:

- **Exploration Mode** — vague request, "should we", "would it make sense", "I'm not sure", multiple competing directions, weak product opinion, or no concrete change spelled out yet.
- **Scope Mode** — concrete feature, fix, refactor, or extension with a clear intended change. Operator already knows what they want done.
- **Mixed Mode** — operator has a likely direction but still asks for tradeoffs, alternatives, or a sanity check. Produce Exploration first, then a clearly-labeled recommended Scope direction marked **NOT YET COMMITTED**.

State the selected mode at the top of the output and briefly say why that mode fits. If the request is ambiguous, prefer Mixed Mode over guessing.

### Step 3a: Exploration Mode output

Use this format when the request is vague:

```
### Phase 0 — Exploration Report (NOT YET COMMITTED)

#### Selected Mode: Exploration
[1-2 sentences on why exploration fits this request]

#### Problem Framing
[What problem the operator is actually trying to solve, restated in concrete terms]

#### Alternatives
1. [Option A — short description]
2. [Option B — short description]
3. [Option C — short description, or "do nothing" if relevant]

#### Tradeoffs
[Per-option: what is gained, what is given up, what is uncertain]

#### Product / Codebase Fit
[How each option fits the current product direction, the existing architecture, and the patterns already in use]

#### Kill Criteria
[Conditions under which this idea should be dropped rather than built]

#### Open Questions
[What the operator needs to decide or learn before committing to any option]

#### Recommended Next Command
[Either: "Choose one option and run /bridge-plan-feature with only that selected direction" OR "Run /bridge-scope again with a tighter framing because X is still unclear" OR "Run /bridge-integrate-design if the operator already has a written PRD/spec to integrate"]
```

This output IS the deliverable. Do not write requirements, context, or new docs artifacts. Do not allocate Fxx / ATxx / Sxx IDs.

### Step 3b: Scope Mode output

Use this format when the request is concrete:

```
### Phase 0 — Scope Report

#### Selected Mode: Scope
[1-2 sentences on why scope mode fits this request]

#### Change Summary
[1-2 sentences: what changes and why]

#### Type
[feature | fix | refactor | extension | integration]

#### Impact Analysis
- **Files likely affected:** [list with brief reason]
- **Files that MUST NOT change:** [boundaries]
- **Dependencies added/removed:** [if any]
- **Risk areas:** [what could break]

#### Existing Patterns to Follow
[How the codebase currently handles similar concerns — naming, error handling, testing, module structure. The implementation MUST follow these conventions.]

#### Approach
[2-5 bullets: high-level implementation strategy]

#### Acceptance Criteria (draft)
1. [Given/When/Then — what "done" looks like]
2. [Edge cases to handle]
3. [What should NOT change in behavior]

#### Open Questions
[Anything the human needs to decide before proceeding]

#### Estimated Scope
[S/M/L — number of slices likely needed, which existing features are touched]
```

This output IS the deliverable. Do not append to `docs/requirements.json` or `docs/context.json` — that happens in `bridge-plan-feature`.

### Step 3c: Mixed Mode output

Use this format when the operator has a likely direction but still wants tradeoffs. Produce Exploration first, then a Scope recommendation explicitly marked as NOT YET COMMITTED:

```
### Phase 0 — Mixed Report (NOT YET COMMITTED)

#### Selected Mode: Mixed
[1-2 sentences on why mixed mode fits this request]

#### Part 1 — Exploration
[Use the full Exploration Mode template above]

#### Part 2 — Recommended Scope Direction (NOT YET COMMITTED)
[Use the full Scope Mode template above, prefixed with: "This is a recommended direction only. It is NOT YET COMMITTED. The operator must confirm or revise before running /bridge-plan-feature."]
```

### Step 4: Human Handoff

End with a HUMAN block that asks the operator to pick or refine a direction BEFORE `bridge-plan-feature` formalizes anything:

```
HUMAN:
1. Selected mode is [Exploration | Scope | Mixed] because [why]
2. If Exploration / Mixed: pick ONE option (or ask for another exploration pass with tighter framing)
3. If Scope: confirm the impact analysis and approach, or tell me what to change
4. When you have a single chosen direction, run: /bridge-plan-feature [paste the selected option or "proceed with the scope above"]
5. If you have a written PRD or design doc instead of a fuzzy idea, run: /bridge-integrate-design [paste or attach the document]
6. Reminder: this scope output is on-screen only — no requirements, context, or docs artifacts were written.
```

Now scan the project and run Phase 0 against this request:

$ARGUMENTS
