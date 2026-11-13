<!-- BRIDGE Relay request template (see .bridge/relay/README.md). Copy it to
docs/reviews/<slice>-ready-to-audit.md, replace every <placeholder>, delete this comment and
commit the file. A re-gate appends a row such as
| 2 | <YYYY-MM-DD> | Re-gate after <the findings repaired> | `<full SHA of the repair>` | -->
# <slice> — Ready to Audit

**Request:** independent gate, then eval on pass. The request to act on is the last row of the request log.
**Slice:** <slice: the report ID; for a list also give the selection as written and its explicit slices>. **Features:** <Fxx (status), ...>. **Acceptance tests:** <ATxx–ATyy>.
**Submitted revision:** `<full 40-character SHA of the submitted commit>`
**Product revisions:** `<full SHA of each commit that changes product files>`
**Planning base:** `<full SHA of the revision the slice started from>`. Review the delta with `git diff --stat <planning base> <submitted revision>`.
**Implemented by:** <harness> / <model>. A different harness or model gives the gate more independence.

This file is watched by the producer. It waits with `.bridge/relay/wait.sh` for
`docs/reviews/<slice>-gate-report-r<n>.md` (n is the number of the last request log row), then
`docs/reviews/<slice>-eval-scenarios.md`, and acts on what they say.
A commit is the readiness signal: an uncommitted edit to this file is not a request.

## What to do

1. Run the independent gate: `/bridge-gate` in Claude Code, `$bridge-gate` in Codex, or the
   gate procedure your harness uses, in **Independent gate** mode for <slice>. Use a fresh
   scratch worktree for each round, detached at the revision in the last row of the request
   log, and leave it for the operator to remove; the main checkout is not the submission.
2. Run every `commands_to_run` entry in `docs/context.json` there. <what slice_verify and slice_smoke name, and any slice-specific command>
3. Write `docs/reviews/<slice>-gate-report-r<n>.md`, n being the number of the request log row
   you act on (never edit an earlier round's file), with the usual summary line
   (`**OVERALL: PASS | PASS WITH WARNINGS | FAIL — …**`), the `gate_history` entry and any
   gate-owned blocks in the <slice> verify/smoke scripts. Commit on `<branch>` without pushing.
   Don't change product files; findings go in the report.
4. If the gate passes, including PASS WITH WARNINGS, run the evaluation: `/bridge-eval` or
   `$bridge-eval`, producing `docs/reviews/<slice>-eval-scenarios.md`,
   `tests/slices/<slice>-eval.sh` and the `eval_history` entry. Commit them the same way.
5. If the gate fails, list each blocking issue with file:line and a concrete expected outcome.
   The producer repairs within the slice and appends a re-gate row below, at most twice.

## Allowed write paths

- **Reviewer:** the gate report, the eval scenarios and `tests/slices/<slice>-eval.sh`, their
  `gate_history` and `eval_history` entries in `docs/context.json`, and the gate-owned fences
  in `tests/slices/<slice>-verify.sh` and `tests/slices/<slice>-smoke.sh`. <any other path the gate or eval procedure writes for this slice>
- **Producer:** <the slice's paths>, the ledgers and this file's request log.

## Protected paths

<paths neither side may change, from the slice's acceptance tests and non-goals>

## Notes for the reviewer

- **What <slice> is.** <what changed, and where its scope and non-goals are recorded>
- **Producer evidence (not a gate).** <each commands_to_run entry and its totals at the submitted revision; the make ledger-check command for the selected slices and its output>
- **Self-audit.** <docs/reviews/<slice>-self-audit.md and its open findings, or none>
- **Human-only checks.** <observations the eval lists as human-only and never infers>
- **Main-tree noise, not part of the submission.** <uncommitted or untracked files in the main checkout, or none>

## Request log

| # | Date | Request | Revision |
|---|---|---|---|
| 1 | <YYYY-MM-DD> | Independent gate, then eval on pass | `<full submitted SHA>` |

**Outcome:** <open until the operator decides: the gate verdict and its commit, the eval result and its commit, then acceptance or issues>
