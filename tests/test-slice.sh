#!/usr/bin/env bash
set -uo pipefail
# BRIDGE single-slice runner. Runs one slice's verify + smoke + eval scripts.
#
#   bash tests/test-slice.sh <slice>   e.g. bash tests/test-slice.sh S37
#
# Missing argument -> usage + non-zero (a usage error is distinct from the
# valid-but-empty case). When the slice has none of its three scripts, prints a
# clear notice naming the slice and exits 0.
#
# BRIDGE-managed, pack-agnostic; byte-identical across packs and the repo root.
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1
source .bridge/lib/runner-lib.sh

slice="${1:-}"
if [ -z "$slice" ]; then
  echo "Usage: bash tests/test-slice.sh <slice>   (e.g. S37)" >&2
  exit 2
fi

scripts="$(bridge_collect_scripts \
  "tests/slices/${slice}-verify.sh" \
  "tests/slices/${slice}-smoke.sh" \
  "tests/slices/${slice}-eval.sh")"

if [ -z "$scripts" ]; then
  bridge_no_scripts_notice "tests/slices/${slice}-{verify,smoke,eval}.sh"
  exit 0
fi

echo "== BRIDGE test-slice ${slice} =="
# shellcheck disable=SC2086  # scripts is a newline list of existence-checked paths
bridge_run_scripts "tests/slices/${slice}-{verify,smoke,eval}.sh" $scripts
bridge_summary
