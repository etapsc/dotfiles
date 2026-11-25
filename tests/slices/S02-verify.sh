#!/usr/bin/env bash
set -uo pipefail
# BRIDGE per-slice verify script for S02. Managed in fenced blocks.
# Producer block: bridge-coder/bridge-debugger. Gate block: bridge-gate-audit.
# Re-runs of those agents rewrite their own block in place (no duplication).
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source .bridge/lib/runner-lib.sh

# >>> BRIDGE slice S02 producer (managed) >>>
bridge_run "audit layout generator Bash syntax" bash -n bin/new-zellij-audit-layout.sh
bridge_run "Audit layout test Python syntax" python3 -c 'import ast,pathlib; ast.parse(pathlib.Path("tests/test_audit_layout.py").read_text())'
if command -v shellcheck >/dev/null 2>&1; then
  bridge_run "audit layout generator ShellCheck" shellcheck bin/new-zellij-audit-layout.sh
fi
# <<< BRIDGE slice S02 producer (managed) <<<

# >>> BRIDGE slice S02 gate (managed) >>>
# (appended by gate; empty until first gate run)
# <<< BRIDGE slice S02 gate (managed) <<<

bridge_summary
