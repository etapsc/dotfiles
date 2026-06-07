---
description: "(Re)scaffold/refresh the per-slice verification framework (.bridge/ + runners + Makefile wiring) in an existing project so the operator can run make verify from SSH, an iPad, or a phone"
---

You are the operator-invokable **(re)scaffold/refresh** of the per-slice verification framework — the manual, in-session equivalent of what `bridge.sh new` / `bridge.sh update` install. The goal: a human operator can run ONE stable command — `make verify` (and `make eval` / `make test-slice SLICE=Sxx`) — from an SSH session, an iPad, or a phone, instead of copying a long list of shell commands out of a handoff or re-entry brief each time.

You do this by ENSURING the BRIDGE verification scaffolding is present and current in the operator's project. You do NOT generate a per-run capsule and you do NOT author per-slice content — you ensure the FRAMEWORK that the per-slice scripts plug into.

## What you ensure present and current

Running this command in an existing project ensures the following exist (add when absent, preserve when present):

1. `.bridge/verify.mk`, `.bridge/lib/runner-lib.sh`, `.bridge/fence-template.txt`.
2. `tests/run-verify.sh`, `tests/run-eval.sh`, `tests/test-slice.sh`.
3. `tests/slices/` (the per-slice script directory, with a `.gitkeep`).
4. The project `Makefile` fenced `-include .bridge/verify.mk` block (via the SAFE/UNSAFE mechanism below).

The single stable operator command is **`make verify`** (which runs every `tests/slices/*-verify.sh` + `*-smoke.sh` via `tests/run-verify.sh`). `make eval` runs every `tests/slices/*-eval.sh`; `make test-slice SLICE=Sxx` runs one slice's scripts. The runners also work without make: `bash tests/run-verify.sh` / `bash tests/run-eval.sh` directly.

## This does NOT replace `/bridge-gate` or `/bridge-eval`

`bridge-verify-handoff` does **not replace `/bridge-gate` or `/bridge-eval`.** `/bridge-gate` is the quality DECISION (the auditor verdict) and appends gate checks into the per-slice fences. `/bridge-eval` GENERATES user-perspective scenarios and writes `tests/slices/<slice>-eval.sh`. `bridge-verify-handoff` only ensures the verification FRAMEWORK (the `.bridge/` files, the runners, the Makefile wiring) is present and wired. It scaffolds; it does not judge and it does not author per-slice content. If there is no gate decision or eval pack yet, run those first — this command does not substitute for them.

## Hard prohibitions

- MUST NOT generate `.bridge/verify-latest.sh`. That generated-capsule path is removed; verification runs through the per-slice scripts under `tests/slices/` via the runners.
- MUST NOT seed or write any `tests/slices/<slice>-verify.sh`, `<slice>-smoke.sh`, or `<slice>-eval.sh`. Per-slice content is owned by `bridge-coder`/`bridge-debugger` (the producer fence), `bridge-gate-audit` (the gate fence), and `bridge-eval-generate` (the eval file). This command ensures ONLY the framework — never the per-slice content.
- MUST NOT overwrite a present, user-edited scaffolding file whole. Add-only when absent; preserve when present. For the Makefile, only ever rewrite BRIDGE's own fenced block — never the rest of the file.

## `.bridge/verify.mk` — BRIDGE-managed include mechanism

`make verify` delegates through a **BRIDGE-managed include file** so BRIDGE never edits the body of a user-authored Makefile.

1. BRIDGE owns `.bridge/verify.mk` (BRIDGE-managed). It defines exactly the `verify` / `eval` / `test-slice` targets, each delegating to a runner:

   ```makefile
   # BRIDGE-managed. Defines verify / eval / test-slice. Safe to overwrite while
   # unmodified; user edits here are preserved by bridge.sh update.
   .PHONY: verify eval test-slice
   verify:
   	@bash tests/run-verify.sh
   eval:
   	@bash tests/run-eval.sh
   test-slice:
   	@bash tests/test-slice.sh "$(SLICE)"
   ```

2. The project `Makefile` gets a SINGLE BRIDGE-managed line, fenced by markers so it is detectable, idempotent, and removable:

   ```makefile
   # >>> BRIDGE verify (managed) >>>
   -include .bridge/verify.mk
   # <<< BRIDGE verify (managed) <<<
   ```

   The leading dash in `-include` means make does not error if `.bridge/verify.mk` is absent. The fenced markers make the line a single managed block.

BRIDGE owns `.bridge/verify.mk` and the fenced `-include` block ONLY. It never touches any other Makefile content. When `.bridge/verify.mk` is present and unmodified, refresh it to the current shipped content; when a user has edited it, preserve it.

## Makefile safe / unsafe decision logic

Decide per project whether it is safe to auto-wire `make verify`.

### SAFE — auto-wire (write the managed `-include` block)

- No Makefile present → BRIDGE creates a minimal Makefile containing ONLY the fenced `-include .bridge/verify.mk` block.
- Makefile present WITHOUT the fenced block, and no conflicting non-BRIDGE `verify`/`eval`/`test-slice` target outside the fence → insert the fenced block once (idempotent).
- Makefile present WITH the fenced block → rewrite ONLY the content between the markers; leave the rest of the Makefile byte-for-byte unchanged.

In the SAFE case: ensure the `.bridge/` files + runners + `tests/slices/`, write/refresh `.bridge/verify.mk`, insert/refresh the fenced `-include` block, then tell the operator `make verify` is ready.

### UNSAFE — do NOT touch the Makefile, print manual instructions

Treat as UNSAFE (and refuse to auto-edit the Makefile) when ANY hold:

- A non-BRIDGE `verify`, `eval`, or `test-slice` target already exists outside BRIDGE's fenced block.
- A generated / "DO NOT EDIT" Makefile, or a whitespace-sensitive structure you cannot safely fence.
- The project uses a non-make build entry that owns these semantics (e.g. `Justfile`, `Taskfile.yml`, `package.json` scripts) — ensure the runners, skip make-wiring.
- You cannot confidently determine the Makefile is user-authored vs. generated.

When automatic Makefile wiring is unsafe, this command **preserves existing Makefile content** and prints clear **manual instructions** instead of editing it. Specifically, in the UNSAFE case you MUST:

1. Still ensure the `.bridge/` files, the runners, and `tests/slices/` are present (BRIDGE-owned; they never clobber user files).
2. NOT modify the user Makefile.
3. Print CLEAR manual instructions: the operator can either add the fenced `-include .bridge/verify.mk` block themselves, or just run `bash tests/run-verify.sh` / `bash tests/run-eval.sh` directly (the runners work without make).

## `context.json` commands_to_run — advisory only

This command no longer compiles `commands_to_run` into a generated runner. Read `docs/context.json` → `commands_to_run` **advisorily**: after (re)scaffolding, you MAY note in your HUMAN block which `commands_to_run` entries are not yet represented by any `tests/slices/*` script, and point the operator at the owning agent — `bridge-coder`/`bridge-debugger` (producer fence), `bridge-gate-audit` (gate fence), or `bridge-eval-generate` (eval file) — to capture them. Write those commands NOWHERE; do not invent commands.

## Boundary vs. `bridge.sh update`

`bridge.sh update` is the whole-pack migration (docs + agents/skills + scaffolding) under add-only/preserve; the verification scaffolding is one slice of that sync. `bridge-verify-handoff` is the narrow, in-session, agent-invokable entry point to ensure JUST the verification scaffolding is present/wired (and to safely (re)apply the Makefile `-include` where a blanket update's add-only logic left a user Makefile without the fenced block). Same files, same Makefile fence mechanism, narrower scope, SSH/iPad ergonomics. The two share one source of truth (the shipped scaffolding content + the fence); they must not diverge in scaffolding content.

## Idempotence

- `.bridge/` files and the runners are framework files: add when absent, preserve a user-edited copy, refresh an unmodified one. No per-run capsule is written.
- The fenced Makefile block is rewritten in place (content between markers only); re-running never appends a duplicate block.
- Removing BRIDGE verify wiring = delete the fenced block + `.bridge/verify.mk`; the project Makefile body is otherwise independent.

## Security

- This command (re)scaffolds BRIDGE-owned files and rewrites only its own Makefile fenced block; it embeds NO secrets, tokens, or credentials and invents NO commands.
- The runners use `set -uo pipefail`, the safe-glob guard, and `bash <fixed tests/slices/* path>` invocation; per-slice scripts (authored later by agents from canonical project sources) are the only thing that runs.

## Required Closing (do not omit)

Your response MUST end with a HUMAN: block. Use this format:

```
HUMAN:
1. Run `make verify` (or `bash tests/run-verify.sh`) — confirm the per-slice scripts run and the summary line reports N passed / M failed. Also try `make eval` (`bash tests/run-eval.sh`).
2. If Makefile wiring was skipped as UNSAFE, follow the printed manual instructions (add the fenced `-include .bridge/verify.mk` block yourself, or just run the runners directly).
3. Review any noted `commands_to_run` entries not yet represented by a `tests/slices/*` script — capture them via the owning agent (`/bridge-gate` for gate checks, `/bridge-eval` for scenarios, `/bridge-start` producers for verify/smoke). Decide: approve, or report what should be added.
```

$ARGUMENTS
