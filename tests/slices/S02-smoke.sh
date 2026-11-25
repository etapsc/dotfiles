#!/usr/bin/env bash
set -uo pipefail
# BRIDGE per-slice smoke script for S02. Managed in fenced blocks.
# Producer block: bridge-coder/bridge-debugger. Gate block: bridge-gate-audit.
# Re-runs of those agents rewrite their own block in place (no duplication).
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source .bridge/lib/runner-lib.sh

# >>> BRIDGE slice S02 producer (managed) >>>
bridge_run "Audit layouts have Auditor/Provider pairs plus Shell and refuse unsafe input" python3 tests/test_audit_layout.py
# <<< BRIDGE slice S02 producer (managed) <<<

# >>> BRIDGE slice S02 gate (managed) >>>
# (appended by gate; empty until first gate run)
# <<< BRIDGE slice S02 gate (managed) <<<

bridge_summary
