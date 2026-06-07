#!/usr/bin/env bash
set -uo pipefail
# BRIDGE per-slice eval runner. Runs every tests/slices/*-eval.sh, aggregating a
# pass/fail summary across all children. Exits 0 with a clear notice when no
# matching slice scripts exist yet.
#
# BRIDGE-managed, pack-agnostic; byte-identical across packs and the repo root.
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1
source .bridge/lib/runner-lib.sh

scripts="$(bridge_collect_scripts 'tests/slices/'*-eval.sh)"

if [ -z "$scripts" ]; then
  bridge_no_scripts_notice "tests/slices/*-eval.sh"
  exit 0
fi

echo "== BRIDGE eval =="
# shellcheck disable=SC2086  # scripts is a newline list of existence-checked paths
bridge_run_scripts "tests/slices/*-eval.sh" $scripts
bridge_summary
