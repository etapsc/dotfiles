#!/usr/bin/env bash
# BRIDGE-managed shared runner library. Sourced by the per-slice runners
# (tests/run-verify.sh, tests/run-eval.sh, tests/test-slice.sh).
#
# Provides the repo's pass/fail summary idiom plus the "no matching slice
# scripts yet -> exit 0 with a clear message" behavior. Safe under
# `set -uo pipefail` (no unbound-variable crashes, no `set -e` early aborts:
# every child runs and a summary is printed at the end).
#
# This file is BRIDGE-managed and pack-agnostic; it is byte-identical across
# the claude-code and codex packs and the BRIDGE repo root.

# Counters. Initialized defensively so `set -u` never trips on first use.
BRIDGE_PASS=${BRIDGE_PASS:-0}
BRIDGE_FAIL=${BRIDGE_FAIL:-0}

# bridge_run "<label>" <cmd...>
# Runs a command, prints `+ <label>` on success / `- <label>` on failure,
# and updates the pass/fail counters. Never aborts the caller.
bridge_run() {
  local label="$1"; shift
  if "$@"; then
    printf '  + %s\n' "$label"
    BRIDGE_PASS=$((BRIDGE_PASS + 1))
  else
    printf '  - %s\n' "$label"
    BRIDGE_FAIL=$((BRIDGE_FAIL + 1))
  fi
}

# bridge_summary
# Prints `N passed, M failed` and returns non-zero iff any check failed.
bridge_summary() {
  printf '%d passed, %d failed\n' "$BRIDGE_PASS" "$BRIDGE_FAIL"
  [ "$BRIDGE_FAIL" -eq 0 ]
}

# bridge_no_scripts_notice "<glob description>"
# Prints a single clear line explaining that no matching slice scripts exist
# yet. Callers use this then `exit 0` so an empty tests/slices/ is a clean
# no-op rather than an error.
bridge_no_scripts_notice() {
  local glob_desc="$1"
  printf 'No matching slice scripts yet (%s); nothing to run.\n' "$glob_desc"
}

# bridge_run_scripts "<glob description>" <script...>
# Runs each given per-slice script as `bash <script>`, aggregating pass/fail
# via bridge_run. A non-zero child exit is reflected as a failed check.
# Callers pass an already-expanded, existence-checked list (see the safe-glob
# helper below) so a literal unmatched glob is never executed as a filename.
bridge_run_scripts() {
  local glob_desc="$1"; shift
  local script
  for script in "$@"; do
    [ -e "$script" ] || continue
    bridge_run "$script" bash "$script"
  done
}

# bridge_collect_scripts <glob...>
# Echoes (newline-separated) the paths that actually exist among the given
# globs. An unmatched glob expands to itself under bash; the `[ -e ]` guard
# drops those literals so callers get a clean, possibly-empty list.
bridge_collect_scripts() {
  local pattern f
  for pattern in "$@"; do
    for f in $pattern; do
      [ -e "$f" ] && printf '%s\n' "$f"
    done
  done
}
