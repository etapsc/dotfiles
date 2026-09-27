# BRIDGE v3.0.2 — dotfiles

## Methodology

BRIDGE = Brainstorm → Requirements → Implementation Design → Develop → Gate → Evaluate

## Canonical Sources (authority ladder)

1. The operator's live word — outranks every document below.
2. docs/context.json — as-built truth. If it is stale, fix it.
3. docs/requirements.json — intent (bridge.v2 schema)
4. docs/contracts/* and docs/designs/ — schemas/ADRs and approved architecture
5. docs/conventions.md — folder taxonomy reference (what belongs in each docs/ subdir)
6. docs/project-knowledge.md — input-side project knowledge (domain, architecture, doc index) filled from existing docs + code; distinct from the derived docs/project-brief.md
7. Codebase — ultimate reality. When it disagrees with anything above, update docs/context.json or record the discrepancy. Do not improvise a rescope.

## Project State and Acceptance

Report these separately: delivery/acceptance, gate verdict and revision, automated
evaluation, live evaluation, and publication. A PASS does not automatically mean
accepted; a warning does not automatically mean blocked. `awaiting_feedback: true`
means observations are outstanding, not that an accepted feature must return to
`review`. A version marker describes the project or installed toolkit; a Git tag
and a published release are separate facts.

Explicit operator acceptance already given in the conversation is authorization
to record it; do not ask for the same approval again. During a state-writing task,
append the scoped acceptance to `docs/decisions.md`, add its pointer and any
explicit deferrals to `context.json.feedback_history`, then synchronize
`context.json.feature_status`, requirements feature statuses, slice status and
handoff. Refresh requested derived reports from that reconciled state. Read-only
commands report a discrepancy without changing files.

Keep ordinary unaccepted work at `review`. If the operator explicitly accepts with
deferred checks or a known coverage limitation, record that disposition and mark
the accepted scope `done`; keep those checks deferred/unobserved. Acceptance never
changes test outcomes, erases a failed gate, expands a gate's revision coverage,
or authorizes publication. Warnings are non-blocking unless an applicable
requirement or explicit operator decision makes one blocking; cite that source.
Never reopen accepted work solely because an older report says `review`, live
feedback is deferred, or a release tag is absent. Reopen it for a reported issue
or a new scoped change, preserving the earlier acceptance record.

## Hard Constraints

- Respect scope.in_scope / out_of_scope / non_goals. No scope creep without user instruction.
- Work in thin vertical slices. Prefer PR-sized diffs.
- Every ATxx claimed as passed requires observed executable evidence or a recorded manual observation. Operator acceptance with explicitly deferred checks follows Project State and Acceptance above; it never makes an unrun check pass.
- Feature status flow: planned → in-progress → review → done | blocked.
- No full-repo scans by default. Targeted inspection only.
- Use stable IDs: Fxx, ATxx, Sxx, UFxx, Rxx.
- Unknowns → execution.open_questions. Do not invent.
- No secrets in code. No sensitive data in production logs. OWASP Top 10 awareness.
- **Every response that presents work output MUST end with a HUMAN: block.** After receiving subagent output, relay the subagent's HUMAN: block verbatim — or compose one if the subagent omitted it. Never summarize subagent results without a HUMAN: block.
- **Never call the `AskUserQuestion` tool.** All clarifications, decisions, and option choices go in a HUMAN: block per the Human Handoff Protocol below. The deny rule in `.claude/settings.json` enforces this; following it without trying avoids the deny/retry cycle.

## Discrepancy Protocol

- Code ≠ context.json → update context.json.
- Code ≠ requirements.json → record discrepancy in context.json, propose fix, do NOT silently rescope.

## Human Handoff Protocol

The human operator drives BRIDGE. Every significant output MUST end with a `HUMAN:` block:

```
HUMAN:
1. [Concrete verification step — what to run, what to check]
2. [Decision required, if any — with options]
3. [What to feed back next]
```

Required at: slice completion, gate results, open questions, blockers, session end.
Never declare a slice "done" without telling the human exactly how to verify it.

## Delegation Model

Use subagents for isolated, focused work. The main session acts as orchestrator.

- **bridge-architect** — design/contracts for current slice. Read-only except docs/contracts/ and docs/decisions.md.
- **bridge-coder** — implement current slice scope. Small testable increments. Tests satisfy ATxx. No unrelated refactors.
- **bridge-debugger** — reproduce first, fix root cause, add regression tests. Report: commands → results → files changed.
- **bridge-auditor** — never fixes code. Verifies ATxx evidence, checks scope, runs quality gates. In Independent gate mode produces docs/reviews/{slice-range}-gate-report.md and the gate_history entry; in Self-audit mode produces docs/reviews/{slice-range}-self-audit.md and writes no context.
- **bridge-evaluator** — only after gate passes. Generates test scenarios from user perspective. Maps to user_flows and acceptance_tests.

Pass only relevant context when delegating: relevant JSON slices + file paths, not the whole repo.

**After receiving subagent output:** Always present the subagent's HUMAN: block to the user (or compose one if the subagent omitted it). Never relay subagent results without a HUMAN: block.

## Post-Delivery Feedback Loop

After presenting slice results and the HUMAN: block, WAIT for the user's response.
Classify it before taking any action:

**ISSUES REPORTED** (default if ambiguous):
User describes bugs, missing behavior, or requests changes to CURRENT slice deliverables.
Indicators: "fix", "bug", "issue", "wrong", "missing", "doesn't work", "investigate", "implement", "however", "but", numbered problem lists, behavioral descriptions.
→ Acknowledge the reported issues explicitly. Create numbered fix tasks. Re-enter implementation for the CURRENT slice (same Sxx) by delegating to bridge-coder/bridge-debugger as needed. Do NOT delegate to bridge-auditor or bridge-evaluator. Do NOT ask about next slice. After fixes, present results with a new HUMAN: block and re-enter this loop.

**APPROVED**: Explicit approval only — "done", "approved", "PASSED", "looks good", "move on", "next slice", "continue".
→ Proceed to bridge-auditor, then bridge-evaluator, then next slice selection.

**STOP**: Explicit stop/pause request. → Run session wrap-up.

CRITICAL: Never assume approval. If the response contains ANY issue descriptions, treat as ISSUES REPORTED even if it also contains partial approval.

## Available Skills

These skills are auto-discovered. Key ones:

- **bridge-slice-plan** — plan and execute thin vertical slices
- **bridge-gate-audit** — run quality gate checks, produce gate report
- **bridge-eval-generate** — generate evaluation scenarios, E2E tests, feedback template
- **bridge-session-management** — session re-entry briefs and wrap-up procedures
- **bridge-context-sync** — create or update context.json from code reality
- **bridge-feedback-process** — triage evaluation feedback, decide iterate vs launch

## Local harness extensions
If `.ai-local/index.md` exists, read it and follow its instructions too.
It lists optional per-developer harness directories. They are ADDITIVE —
nothing there overrides this file, docs/requirements.json, or docs/context.json.
