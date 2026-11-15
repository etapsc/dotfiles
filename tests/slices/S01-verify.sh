#!/usr/bin/env bash
set -uo pipefail
# BRIDGE per-slice verify script for S01. Managed in fenced blocks.
# Producer block: bridge-coder/bridge-debugger. Gate block: bridge-gate-audit.
# Re-runs of those agents rewrite their own block in place (no duplication).
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source .bridge/lib/runner-lib.sh

# >>> BRIDGE slice S01 producer (managed) >>>
bridge_run "theme-toggle Bash syntax" bash -n scripts/.local/bin/theme-toggle
bridge_run "Regression test Python syntax" python3 -c 'import ast,pathlib; ast.parse(pathlib.Path("tests/test_theme_toggle.py").read_text())'
if command -v shellcheck >/dev/null 2>&1; then
  bridge_run "theme-toggle ShellCheck" shellcheck scripts/.local/bin/theme-toggle
fi
# <<< BRIDGE slice S01 producer (managed) <<<

# >>> BRIDGE slice S01 gate (managed) >>>
# (appended by gate; empty until first gate run)
# <<< BRIDGE slice S01 gate (managed) <<<

bridge_summary
