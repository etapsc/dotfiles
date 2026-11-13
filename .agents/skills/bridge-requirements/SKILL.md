---
name: Bridge Requirements
description: "Phase 1: Generate requirements.json and context.json — from brainstorm output, a written project description, or existing code. Invoke with $bridge-requirements in your prompt."
---

You are following the BRIDGE v2 methodology for solo-preneur software development with AI dev teams.

BRIDGE = Brainstorm → Requirements → Implementation Design → Develop → Gate → Evaluate

## TASK - PHASE 1: GENERATE REQUIREMENTS PACK (bridge.v2)

### Step 0: Select Mode (content-driven)

This command covers three ways into Phase 1. Pick the mode that matches the input;
mode selection is content-driven, never inferred from a flag.

- **From Brainstorm** — Phase 0 brainstorm output is present above, or is provided
  below. Use it as the source material.
- **From Description** — no brainstorm ran. The operator supplies a written
  project description, PRD, spec, or requirements prose. Phase 0 is skipped.
- **From Existing Code** — source code is present and docs/requirements.json is
  missing or still the installed template (no features in it or in a previous_doc
  chain, and an empty context.json feature_status). Any operator README, PRD or
  notes are supplementary. Follow the From Existing Code mode section below.

State the selected mode at the top of your output:

```
#### Selected Mode: From Brainstorm | From Description | From Existing Code
[one sentence on why that mode fits this input]
```

If both a brainstorm and a written description are present, prefer **From
Brainstorm** and treat the description as supplementary. A brainstorm still
selects From Brainstorm when source code is present. A written description still
selects From Description when source code is present, unless the operator asks
to describe what is built or to onboard the codebase. Stop and ask only when
there is no brainstorm, no description and no source code — do not invent a
project.

When source code is present, there is no brainstorm or description, and the
ledgers are real (docs/requirements.json or its previous_doc chain lists a
feature, or context.json feature_status is non-empty), select From Existing Code
so its ledger guard runs: stop without writing. Point the operator to
$bridge-context for status against the code, or to $bridge-plan-feature for new
work.

All three modes produce the same three files with the same schemas. From
Description mode should stay lean and execution-oriented: scope, constraints,
acceptance tests, and slices matter most.

### From Existing Code mode

Use this section only when Step 0 selected **From Existing Code**. It records
what is already built as the as-built baseline. Take the steps in order.

1. **Ledger guard, before the inventory.** Read docs/requirements.json, every
   file in its previous_doc chain, and docs/context.json. If any of them lists a
   feature, or context.json feature_status is non-empty, the ledgers are real:
   stop without writing. Point the operator to $bridge-context for status against
   the code, or to $bridge-plan-feature for new work. Never overwrite, regenerate
   or restart IDs in docs/requirements.json, docs/context.json or
   docs/human-playbook.md.
2. **Targeted inventory, not a full-repo scan.** Read the manifests and build
   files, the top-level tree, the entry points (CLI commands, routes, public APIs,
   handlers), the test layout and the CI config, plus any README, PRD or docs the
   operator names. When the codebase is large, ask the operator to name the areas
   to read first.
3. **Existing capabilities become features.** Record each existing capability as
   a feature that describes current behavior, with characterization acceptance
   tests: they state what the code does now, not what it should do. Each enters
   context.json feature_status at `review`, not `planned` and not `done`. Add a
   context.json recent_decisions entry recording that these features existed
   before BRIDGE (the as-built baseline). Write only the same three files with
   the same schemas as the other modes.
4. **Evidence only from commands you ran.** Add a context.json evidence entry
   only for a test command you actually ran, with the command, its exit code and
   the revision (git SHA), for example
   `"AT03": {"class": "executable", "command": "npm test", "exit_code": 0, "revision": "<git sha>", "dirty": false, "at": "<today>"}`.
   An evidence entry goes only on an AT whose behavior that command actually
   exercises; a suite run is not evidence for an AT it does not cover, which
   stays unobserved. Every other AT stays unobserved and gets no evidence
   entry. Nothing is marked passed by inference. Do not generate test code.
5. **Unknowns go to execution.open_questions:** unclear intent, dead code and
   capabilities without tests.
6. **New intent is separate.** Anything the operator wants next enters as
   `planned` features with slices, now or later through $bridge-plan-feature.
7. **Afterwards,** recommend $bridge-context to fill docs/project-knowledge.md
   from the same sources. This mode does not write docs/project-knowledge.md.

End with the Required Closing, including its From Existing Code item.

### The output

Generate TWO JSON files to be saved in the project, plus the playbook in Step 3.

Rules:
- Output JSON only per file. No prose between them.
- Every feature has stable IDs (F01, F02…) with acceptance tests (AT01, AT02…).
- Include scope (in_scope / out_of_scope / non_goals / assumptions).
- Include constraints, quality_gates, and execution.recommended_slices.
- If something is unknown, put it in execution.open_questions - do not invent.

### File 1: Save to docs/requirements.json

```json
{
  "schema_version": "bridge.v2",
  "project": {
    "name": "",
    "one_liner": "",
    "mission": "",
    "target_users": [""],
    "success_metrics": [""]
  },
  "scope": {
    "in_scope": [""],
    "out_of_scope": [""],
    "non_goals": [""],
    "assumptions": [""]
  },
  "constraints": {
    "languages": [""],
    "platforms": [""],
    "must_use": [""],
    "must_not_use": [""],
    "compliance_security_notes": [""]
  },
  "domain_model": {
    "core_entities": [
      { "name": "", "description": "", "key_fields": [""] }
    ],
    "state_machine_notes": [""]
  },
  "features": [
    {
      "id": "F01",
      "title": "",
      "priority": "must|should|could",
      "description": "",
      "acceptance_tests": [
        { "id": "AT01", "given": "", "when": "", "then": "" }
      ],
      "dependencies": [],
      "non_goals": [""]
    }
  ],
  "user_flows": [
    {
      "id": "UF01",
      "title": "",
      "preconditions": [""],
      "steps": [""],
      "postconditions": [""],
      "linked_features": ["F01"]
    }
  ],
  "nfr": {
    "performance_budgets": [""],
    "reliability": [""],
    "security": [""],
    "observability": [""],
    "scalability": [""]
  },
  "interfaces": {
    "apis": [
      { "name": "", "type": "http|grpc|cli", "notes": "", "schema_ref": "" }
    ],
    "external_services": [
      { "name": "", "purpose": "", "contracts_or_sdks": [""] }
    ]
  },
  "quality_gates": {
    "ci_required": true,
    "tests": {
      "unit": true,
      "integration": true,
      "e2e": "optional|required",
      "coverage_target": "80%"
    },
    "linters_typechecks": [""],
    "security_checks": [""],
    "performance_budgets": {
      "bundle_size": "",
      "api_response": "",
      "page_load": ""
    }
  },
  "execution": {
    "recommended_slices": [
      { "slice_id": "S01", "goal": "", "features": ["F01"], "exit_criteria": ["AT01"] }
    ],
    "open_questions": [
      { "id": "OQ01", "topic": "", "status": "open|answered|withdrawn", "default": "", "answered_on": null, "decision_pointer": null }
    ],
    "risks": [
      { "id": "R01", "risk": "", "impact": "low|med|high", "mitigation": "" }
    ]
  }
}
```

### File 2: Save to docs/context.json

```json
{
  "schema_version": "context.v1",
  "updated": "[TODAY'S DATE]",
  "project": { "name": "" },
  "feature_status": { "F01": "planned" },
  "evidence": {},
  "handoff": {
    "stopped_at": "Project initialization",
    "next_immediate": "Set up project scaffolding",
    "watch_out": []
  },
  "next_slice": { "slice_id": "S01", "goal": "", "features": ["F01"], "acceptance_tests": ["AT01"] },
  "commands_to_run": { "test": "", "lint": "", "typecheck": "", "dev": "" },
  "recent_decisions": [],
  "blockers": [],
  "discrepancies": [],
  "gate_history": [],
  "eval_history": []
}
```

Now produce both JSON files from the selected mode's input. Save them to the docs/ directory.

### File 3: Save to docs/human-playbook.md

Generate a project-specific Human Operator Playbook based on the requirements and slices you just produced. Structure:

```markdown
# Human Operator Playbook - [Project Name]
Generated from requirements.json

## Workflow Per Slice

### Before Each Slice
[Project-specific verification commands: build, test, lint — derived from constraints and quality_gates]

### After Each Slice
[How to smoke test — derived from the stack, interfaces, and what each slice produces]

## Slice Verification Guide

For each slice in execution.recommended_slices, generate a row:

| Slice | Features | What YOU Test Manually | What to Read/Inspect | Decisions Needed |
|-------|----------|----------------------|---------------------|-----------------|
| S01   | F01, F02 | [concrete smoke test] | [key files to review] | [open questions relevant to this slice] |

## Common Pitfalls
[3-5 project-specific warnings based on the stack, constraints, and risks — e.g. "agent generates tests that only test mocks", "agent refactors previous slices", etc.]

## Codex Prompt Template
The exact prompt to feed Codex for each subsequent slice:
```
Continue BRIDGE v2.1. Current state is in docs/context.json.
Execute next_slice [Sxx]: [goal].
Features: [Fxx list].
Exit criteria: [ATxx list].

Rules:
- Run [test/lint/typecheck commands from quality_gates] before declaring done
- Update docs/context.json: feature_status (object map of id to status) and the top-level evidence map keyed by ATxx
- Do NOT refactor previous slice code unless a test is failing
- If you hit an open question, STOP and ask — do not silently skip
```

## Big Picture Cadence
[Visual showing the verify → feed → verify loop with estimated time per cycle]

## Open Questions Requiring Human Decision
[List all execution.open_questions with context for decision-making]
```

Tailor every section to THIS project's stack, constraints, features, and slices. Do not leave placeholders — fill in concrete commands, file paths, and test procedures based on the requirements you just generated.

### Step 4: Specialist Recommendation

After generating requirements.json, scan the project's features, domain model, constraints, and scope against the specialist catalog at `.agents/specialists/catalog.md`.

For each specialist in the catalog:
1. Read the specialist file (e.g., `.agents/specialists/api-design.md`) and check its `triggers.keywords` and `triggers.feature_patterns` against the generated requirements
2. If keywords appear in feature titles, descriptions, domain model entities, constraint text, or scope items — the specialist is relevant
3. Determine confidence: high (3+ keyword matches or pattern+keyword), medium (1-2 keywords), low (pattern-only)

Persist matches in `execution.specialists_recommended` within the requirements.json you just generated:

```json
"specialists_recommended": [
  {
    "id": "specialist-id",
    "rationale": "Why this specialist is relevant to this project",
    "source": "bridge-requirements",
    "mode": "from-brainstorm|from-description|from-existing-code",
    "matched_signals": ["keyword1", "keyword2"],
    "applicable_features": ["F01", "F03"],
    "confidence": "high|medium|low"
  }
]
```

Only recommend specialists with at least one matched signal. Do not recommend specialists that have no keyword or pattern matches. Present the recommendations in the output summary so the human can review them.

## Required Closing (do not omit)

Your response MUST end with a HUMAN: block. Use this format:

```
HUMAN:
0. Selected Mode was [From Brainstorm | From Description | From Existing Code] — was that the right read of your input?
1. Review docs/requirements.json — are scope, features, and acceptance tests correct?
2. Review docs/context.json — does the initial state look right?
3. Check specialist recommendations — are they relevant? Override if needed
4. Decide: proceed to $bridge-start, or adjust requirements first
5. [From Existing Code only] Accept the as-built baseline? Only your explicit acceptance moves the pre-existing features from review to done; it is recorded in docs/decisions.md and context.json.feedback_history under the Project State and Acceptance rules, with unobserved checks kept deferred. Record your acceptance, or your corrections, with $bridge-feedback. Anything you want next enters separately as planned features with slices, now or later through $bridge-plan-feature. Run $bridge-context next to fill docs/project-knowledge.md, which this mode does not write. Then run $bridge-start for the first planned slice; in this mode that order replaces item 4.
```

The user will provide arguments inline with the skill invocation.
