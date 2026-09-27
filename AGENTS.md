# BRIDGE v3.0.2 — dotfiles

## Methodology

BRIDGE = Brainstorm → Requirements → Implementation Design → Develop → Gate → Evaluate

A structured methodology for solo-preneur software development with AI coding agents.

## Canonical Sources (authority ladder)

1. The operator's live word — outranks every document below.
2. `docs/context.json` — as-built truth. If it is stale, fix it.
3. `docs/requirements.json` — intent (bridge.v2 schema)
4. `docs/contracts/*` and `docs/designs/` — schemas/ADRs and approved architecture
5. `docs/conventions.md` — folder taxonomy reference (what belongs in each `docs/` subdir)
6. `docs/project-knowledge.md` — input-side project knowledge (domain, architecture, doc index) filled from existing docs + code; distinct from the derived `docs/project-brief.md`
7. Codebase — ultimate reality. When it disagrees with anything above, update `docs/context.json` or record the discrepancy. Do not improvise a rescope.

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

- Respect `scope.in_scope` / `out_of_scope` / `non_goals`. No scope creep without user instruction.
- Work in thin vertical slices. Prefer PR-sized diffs.
- Every ATxx claimed as passed requires observed executable evidence or a recorded manual observation. Operator acceptance with explicitly deferred checks follows Project State and Acceptance above; it never makes an unrun check pass.
- Feature status flow: `planned → in-progress → review → done | blocked`.
- No full-repo scans by default. Targeted inspection only.
- Use stable IDs: Fxx, ATxx, Sxx, UFxx, Rxx.
- Unknowns → `execution.open_questions`. Do not invent.
- No secrets in code. No sensitive data in production logs. OWASP Top 10 awareness.
- **Every response that presents work output MUST end with a HUMAN: block.** After following a procedure, ensure your response includes the procedure's HUMAN: block. If the procedure omitted one, compose your own with verification steps and next actions.

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

## Role Modes

This pack runs the workflow through role switching inside the main agent: adopt the mode that fits the current task. Each mode has different rules:

### Orchestrator (default)
- Operate per-slice (Sxx). Select from `execution.recommended_slices` or propose smallest next.
- Delegate work by switching to appropriate mode below.
- After each slice: update `docs/context.json` (feature_status, handoff, next_slice).
- After each slice: output a HUMAN: block with verification steps.
- Consult `docs/human-playbook.md` for project-specific verification.

**Post-Delivery Feedback Loop:** After presenting slice results and the HUMAN: block, WAIT for the user's response and classify it:
- **ISSUES REPORTED** (default if ambiguous): User describes bugs, missing behavior, or requests changes. Indicators: "fix", "bug", "issue", "wrong", "missing", "investigate", "however", "but", problem lists. → Acknowledge issues, create fix tasks, re-implement CURRENT slice (same Sxx). Do NOT switch to Audit/Evaluate mode. Do NOT ask about next slice. After fixes, present new HUMAN: block and re-enter this loop.
- **APPROVED**: Explicit approval only ("done", "PASSED", "looks good", "move on", "next slice"). → Proceed to Audit mode, then Evaluate, then next slice.
- **STOP**: Explicit stop/pause. → Wrap up session.
- **CRITICAL**: Never assume approval. Any issue descriptions = ISSUES REPORTED.

### Architect Mode
- Produce only what current slice needs. No speculative design.
- Contracts → `docs/contracts/`. Decisions → `docs/decisions.md`.
- Minimal, explicit interfaces. Brief tradeoff notes.

### Code Mode
- Implement only current slice scope.
- Small, testable increments. Tests must satisfy ATxx.
- No unrelated refactors. No TODO placeholders. No debug prints in committed code.
- Follow project conventions from constraints in `docs/requirements.json`.
- Seed this slice's per-slice scaffolding (see **Per-Slice Verification Scaffolding** below): write your verify/smoke checks into the PRODUCER-owned fenced block of `tests/slices/<slice>-verify.sh` and `tests/slices/<slice>-smoke.sh`.

### Debug Mode
- Reproduce first, then fix root cause.
- Add regression tests. Ensure quality_gates pass after fix.
- Report: commands run → results → files changed.
- Seed/refresh this slice's per-slice scaffolding (see **Per-Slice Verification Scaffolding** below): add the regression check into the PRODUCER-owned fenced block of `tests/slices/<slice>-smoke.sh` (and `-verify.sh` for static checks).

### Per-Slice Verification Scaffolding (producer-owned)
This is the producer side of the Code/Debug modes. As part of implementing or
fixing a slice you seed two per-slice scripts so the gate and operator can re-run
your checks. `<slice>` is the literal slice id (e.g. `S38`):

- `tests/slices/<slice>-verify.sh` — build / format / lint / static checks.
- `tests/slices/<slice>-smoke.sh` — slice behavioral tests (for Debug Mode, include the regression test).

Write ONLY into the PRODUCER-owned fenced block, using these EXACT markers (emit
verbatim, substituting the real slice id for `<slice>`):

```
# >>> BRIDGE slice <slice> producer (managed) >>>
…your verify/smoke commands…
# <<< BRIDGE slice <slice> producer (managed) <<<
```

Rules (see `.bridge/fence-template.txt` for the authoritative spec):

- If the file does not exist, create it from the skeleton below, then fill your block.
- If the file exists, rewrite ONLY the lines between YOUR producer markers in place.
  Never duplicate the block on re-run; never touch the header, the trailer, or the
  gate-owned block. The gate (Audit Mode) appends into a DISTINCT `gate (managed)`
  fence — the producer and gate fences are deliberately distinct so the two owners never collide.

File skeleton (the file creator writes the header + `bridge_summary` trailer once):

```bash
#!/usr/bin/env bash
set -uo pipefail
# BRIDGE per-slice <verify|smoke> script for <slice>. Managed in fenced blocks.
# Producer block: bridge-coder/bridge-debugger. Gate block: bridge-gate-audit.
# Re-runs of those agents rewrite their own block in place (no duplication).
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source .bridge/lib/runner-lib.sh

# >>> BRIDGE slice <slice> producer (managed) >>>
# (seeded by coder/debugger; empty until first seed)
# <<< BRIDGE slice <slice> producer (managed) <<<

# >>> BRIDGE slice <slice> gate (managed) >>>
# (appended by gate; empty until first gate run)
# <<< BRIDGE slice <slice> gate (managed) <<<

bridge_summary
```

Wrap each check with `bridge_run "<label>" <cmd...>` so `bridge_summary` aggregates pass/fail.

### Audit Mode
- NEVER fix production code. Only report findings plus verification automation for automatable manual checks.
- Verify ATxx evidence exists for every in-scope feature.
- Check scope boundaries. Flag violations.
- Use `commands_to_run` from `docs/context.json`.
- If operator-facing manual checks are automatable by shell/API/file inspection/browser automation, APPEND them into the GATE-owned fence (`# >>> BRIDGE slice <slice> gate (managed) >>>` … `<<<`) of `tests/slices/<slice>-verify.sh` / `tests/slices/<slice>-smoke.sh`, rewriting in place. Do NOT write `tests/e2e/<slice>-manual-automation.sh`. Cite the command/result in the gate report. (See AGENTS.md "Per-Slice Verification Scaffolding" for the marker spec; the producer owns the distinct `producer (managed)` fence — never touch it.)
- Leave only human-only checks (subjective UX, external accounts, live credentials, exploratory feel) as prose for the operator in the gate report.
- Write only to, and only what the selected mode permits: **Independent gate** — `docs/reviews/{slice-range}-gate-report.md`, `docs/context.json` (gate_history + ATxx evidence), and the GATE-owned fence of `tests/slices/<slice>-{verify,smoke}.sh`. **Self-audit** — `docs/reviews/{slice-range}-self-audit.md` and nothing else: no context write, no fence, no status.

### Evaluate Mode
- Only run after gate passes (verify `docs/reviews/{slice-range}-gate-report.md`).
- Generate from user perspective. Map to user_flows and acceptance_tests.
- Script automatable scenario steps into `tests/slices/<slice>-eval.sh` as the actual user-facing scenario commands (drive the product as an operator would; assert observable outcomes). It MUST NOT merely re-run the project test framework (`bash test.sh` / unit / integration) — that is verify/smoke's job. Use the `eval (managed)` fence; rewrite in place. Human-only checks stay prose in the eval-scenarios.md.
- Write only to: `docs/reviews/{slice-range}-eval-scenarios.md`, `docs/context.json`, `tests/slices/<slice>-eval.sh`.

## Available Skills

User-invokable skill files live in `.agents/skills/*/SKILL.md`.
Internal procedures live in `.agents/procedures/*.md` and are referenced by workflow skills.

Invoke skills with `$skill-name` in your prompt. Key skills:

**Workflow commands** (invoke directly):
- `$bridge-brainstorm` — Phase 0: brainstorm new project
- `$bridge-scope` — Phase 0: scope feature/fix for existing project
- `$bridge-requirements` — Phase 1: generate requirements (From Brainstorm or From Description mode)
- `$bridge-plan-feature` — Phase 1: incremental requirements for existing project
- `$bridge-integrate-design` — Integrate a design document, PRD, or version spec
- `$bridge-start` — Start implementation
- `$bridge-resume` — Resume in fresh session
- `$bridge-end` — End session
- `$bridge-gate` — Run quality gate
- `$bridge-eval` — Generate evaluation pack
- `$bridge-feedback` — Process evaluation feedback
- `$bridge-context` — Create or refresh context.json (Create or Update mode)
- `$bridge-advisor` — Strategic advisor: viability, positioning, launch readiness
- `$bridge-project-brief` — Generate or refresh docs/project-brief.md (portable handoff for external agents)
- `$bridge-status` — Generate or refresh docs/STATUS.md (human-readable engineering status log)
- `$bridge-verify-handoff` — (Re)scaffold/refresh the per-slice verification framework (.bridge/ + runners + Makefile wiring); stable operator command is make verify

**Internal procedures** (not invoked directly with `$`):
- `.agents/procedures/bridge-slice-plan.md` — Plan and execute thin vertical slices
- `.agents/procedures/bridge-gate-audit.md` — Quality gate check procedures
- `.agents/procedures/bridge-eval-generate.md` — Evaluation pack generation procedures
- `.agents/procedures/bridge-session-management.md` — Session re-entry and wrap-up procedures
- `.agents/procedures/bridge-context-sync.md` — Context synchronization procedures
- `.agents/procedures/bridge-feedback-process.md` — Feedback triage procedures

## Local harness extensions
If `.ai-local/index.md` exists, read it and follow its instructions too.
It lists optional per-developer harness directories. They are ADDITIVE —
nothing there overrides this file, docs/requirements.json, or docs/context.json.
