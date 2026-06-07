---
name: Bridge Eval Generate
description: Generate user test scenarios, E2E tests, and feedback template. Use only after a quality gate has passed.
user-invocable: false
context: fork
agent: bridge-evaluator
---

# Evaluation Pack Generation

## Precondition
Verify the most recent docs/gates-evals/{slice-range}-gate-report.md shows PASS. If not, abort and notify.

**Derive the slice range prefix** from the in-scope slices (matching the gate report). Examples: single slice -> `S22`, consecutive range -> `S10-S15`, non-consecutive -> `S10-S12-S15`. Use this prefix for the eval scenarios filename.

## Step 1: Manual Test Scenarios

Treat manual evaluation as the human-only remainder, not as a copy/paste command queue.

For every scenario:
- Classify each step as `automatable` or `human-only`.
- Automatable means a shell command, API call, browser automation, fixture setup, file inspection, or CLI workflow can verify it without subjective judgment.
- Human-only means real UX judgment, visual polish, external accounts, live credentials, exploratory product feel, or "start a browser and decide whether it feels right".
- Create or update executable coverage for all automatable steps under `tests/e2e/` using the project test framework when available; otherwise create/update `tests/e2e/{slice-range}-eval-automation.sh`.
- Run the automation when feasible, record the command/result in the eval scenarios file, and pre-check or annotate checklist items that the automation already verified.
- Leave only human-only checks for the operator to perform manually.

Create docs/gates-evals/{slice-range}-eval-scenarios.md:

```markdown
# Evaluation Scenarios
Generated: [timestamp]
Project: dotfiles

## How to Use
1. Set up application (see README)
2. Run the automation script first: [tests/e2e/{slice-range}-eval-automation.sh or equivalent]
3. Execute only the human-only scenario steps manually
4. Record results in checklists
5. Fill feedback form at bottom

## Automation Coverage
- Script/command: [path or command]
- Covers: [scenario/checklist items]
- Human-only remainder: [items that cannot be automated]

---

## Scenario N: [Feature Fxx] - [Happy Path / Edge Cases / Cross-Feature]
**Goal:** [what user accomplishes]
**Preconditions:** [setup]
**Linked:** [Fxx, ATxx, UFxx]

### Steps:
1. [Action] → Expected: [result]

### Checklist:
- [ ] Step N works as expected
- [ ] Automatable checks are covered by [script/command]
- [ ] Human-only checks are completed manually

---

## Feedback Form

### Overall Assessment
- [ ] Ready for launch  - [ ] Minor fixes  - [ ] Major fixes

### Ratings (1-5): Usability ___ | Performance ___ | Polish ___

### Issues Found
| # | Severity | Feature | Description | Steps to Reproduce |
|---|----------|---------|-------------|-------------------|

### Suggestions
[Free form]

### Would you use this? Why/why not?
[Free form]
```

## Step 2: E2E Tests
- Create or update in tests/e2e/ using project's test framework
- If the project has no framework, create/update a portable shell script named `tests/e2e/{slice-range}-eval-automation.sh`
- Map to e2e_critical_paths from quality_gates
- Happy path + key edge cases per feature
- Cover every automatable eval scenario step; do not leave copy/paste shell/API/file-inspection steps in the manual-only instructions

## Step 3: Update Context
Append to eval_history in docs/context.json:
```json
{ "date": "[timestamp]", "scenarios_generated": 0, "e2e_tests_generated": 0, "automation_script": "tests/e2e/{slice-range}-eval-automation.sh", "awaiting_feedback": true }
```

## Step 4: Output
```
EVALUATION PACK GENERATED ✓
Created: docs/gates-evals/{slice-range}-eval-scenarios.md ([X] scenarios), tests/e2e/*.spec.* ([Y] files)

HUMAN:
1. Run automated eval coverage yourself: [exact command]
2. Walk through only the human-only items in docs/gates-evals/{slice-range}-eval-scenarios.md — do not repeat checks already covered by automation unless you want a spot check
3. Actually use the application as a real user would for each human-only scenario
4. Fill in the feedback form at the bottom of docs/gates-evals/{slice-range}-eval-scenarios.md
5. Note any DX friction, performance issues, or "this feels wrong" moments
6. Paste your filled feedback into: /bridge-feedback [your feedback]

Estimated evaluation time: [X] minutes
```
