#!/usr/bin/env bash
set -uo pipefail
# BRIDGE per-slice smoke script for S01. Managed in fenced blocks.
# Producer block: bridge-coder/bridge-debugger. Gate block: bridge-gate-audit.
# Re-runs of those agents rewrite their own block in place (no duplication).
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source .bridge/lib/runner-lib.sh

# >>> BRIDGE slice S01 producer (managed) >>>
bridge_run "Theme switching preserves configs and permissions and reports failed writes" python3 tests/test_theme_toggle.py
# <<< BRIDGE slice S01 producer (managed) <<<

# >>> BRIDGE slice S01 gate (managed) >>>
# (appended by gate; empty until first gate run)
# <<< BRIDGE slice S01 gate (managed) <<<

bridge_summary
