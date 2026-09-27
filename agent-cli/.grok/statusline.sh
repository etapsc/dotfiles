#!/usr/bin/env bash
# Status row for Grok. Prints one line. Segments that Grok cannot source
# are left out: permission profile, sandbox mode, and the five-hour and
# weekly usage limits are not in the status payload.
input=$(cat)

field() {
  jq -r "$1" <<<"$input"
}

DIR=$(field '.cwd // .workspace.current_dir // empty')
THREAD=$(field '.session_name // empty')
PROJECT=$(field '.workspace.repo.name // empty')
BRANCH=$(field '.workspace.branch // empty')
VERSION=$(field '.version // empty')
REMAINING=$(field '.context_window.remaining_percentage // empty')
WINDOW=$(field '.context_window.context_window_size // empty')
USED=$(field '(.context_window.session_input_tokens // 0) + (.context_window.session_output_tokens // 0)')
HAS_USED=$(field 'if (.context_window.session_input_tokens == null and .context_window.session_output_tokens == null) then "" else "yes" end')
TRIGGER=$(field '.trigger // "state"')
SESSION=$(field '.session_id // "default"')

fmt_num() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n/1000000
    else if (n >= 10000) printf "%.0fk", n/1000
    else if (n >= 1000) printf "%.1fk", n/1000
    else printf "%d", n
  }'
}

parts=()

if [[ -n "$DIR" ]]; then
  parts+=("${DIR##*/}")
fi

if [[ -n "$THREAD" ]]; then
  parts+=("$THREAD")
fi

if [[ -n "$PROJECT" ]]; then
  parts+=("$PROJECT")
fi

if [[ -n "$BRANCH" ]]; then
  parts+=("$BRANCH")
fi

pr_number() {
  command -v gh >/dev/null 2>&1 || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  local safe cache n
  safe=$(printf '%s' "$SESSION" | tr -c 'A-Za-z0-9_-' '_')
  cache="${HOME}/.grok/statusline-cache/${safe}.pr"
  mkdir -p "${HOME}/.grok/statusline-cache"
  if [[ "$TRIGGER" == "refresh_interval" || ! -f "$cache" ]]; then
    n=$(python3 - << 'PY' 2>/dev/null || true
import subprocess, sys
try:
    p = subprocess.run(
        ["gh", "pr", "view", "--json", "number", "-q", ".number"],
        capture_output=True, text=True, timeout=3,
    )
except Exception:
    sys.exit(0)
if p.returncode == 0:
    sys.stdout.write(p.stdout.strip())
PY
)
    printf '%s' "$n" > "$cache"
  fi
  n=$(tr -d '[:space:]' < "$cache" 2>/dev/null || true)
  [[ -n "$n" && "$n" != "null" ]] && printf '#%s' "$n"
}

pr=$(pr_number || true)
if [[ -n "$pr" ]]; then
  parts+=("$pr")
fi

branch_changes() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  local base counts behind ahead
  base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
  if [[ -z "$base" ]]; then
    if git show-ref --verify --quiet refs/heads/main; then
      base=main
    elif git show-ref --verify --quiet refs/heads/master; then
      base=master
    else
      return 0
    fi
  fi
  counts=$(git rev-list --left-right --count "${base}...HEAD" 2>/dev/null) || return 0
  behind=${counts%%$'\t'*}
  ahead=${counts##*$'\t'}
  [[ "$behind" =~ ^[0-9]+$ && "$ahead" =~ ^[0-9]+$ ]] || return 0
  if [[ "$ahead" == 0 && "$behind" == 0 ]]; then
    return 0
  fi
  printf '↑%s ↓%s' "$ahead" "$behind"
}

delta=$(branch_changes || true)
if [[ -n "$delta" ]]; then
  parts+=("$delta")
fi

if [[ -n "$REMAINING" ]]; then
  parts+=("${REMAINING}% left")
fi

if [[ -n "$WINDOW" && "$WINDOW" != "0" ]]; then
  parts+=("$(fmt_num "$WINDOW") ctx")
fi

if [[ -n "$HAS_USED" && "$USED" != "0" ]]; then
  parts+=("$(fmt_num "$USED") used")
fi

if [[ -n "$VERSION" ]]; then
  parts+=("$VERSION")
fi

out=""
for part in "${parts[@]}"; do
  if [[ -z "$out" ]]; then
    out="$part"
  else
    out="$out │ $part"
  fi
done
if [[ -n "$out" ]]; then
  printf '%s\n' "$out"
fi
