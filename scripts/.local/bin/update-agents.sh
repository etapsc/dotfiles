#!/usr/bin/env bash
# update-agents.sh — check Claude Code, Codex, Grok, and Gemini (agy).
# Run each tool's installer only when a newer release is available, then
# print what changed and the version installed now.
#
# Usage: update-agents.sh [--check]
#   --check   report only; do not install
#
# Version sources:
#   claude  https://downloads.claude.ai/claude-code-releases/latest
#   codex   https://releases.openai.com/codex/channels/latest
#           (GitHub releases/latest if that feed is unreachable)
#   grok    grok update --check --json
#   agy     Antigravity CLI auto-updater banner ("Stable Version")
#
# Codex's own `codex update` always runs the full installer, including when
# the installed version is already the published release. This command skips
# that installer unless the published version is newer.
set -uo pipefail

CHECK_ONLY=0
case "${1:-}" in
  "") ;;
  --check) CHECK_ONLY=1 ;;
  -h|--help)
    cat <<'EOF'
Usage: update-agents.sh [--check]

Check Claude Code, Codex, Grok, and Gemini (agy). Install a tool only when
a newer release is available, then print what changed and every current version.

  --check   show what would change; do not install
EOF
    exit 0
    ;;
  *)
    printf 'unknown argument: %s\n' "$1" >&2
    printf 'Usage: update-agents.sh [--check]\n' >&2
    exit 2
    ;;
esac

if [[ -t 1 ]]; then
  b=$'\033[1m'
  g=$'\033[32m'
  y=$'\033[33m'
  r=$'\033[31m'
  n=$'\033[0m'
else
  b="" g="" y="" r="" n=""
fi

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/update-agents.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

updated_rows=""
current_rows=""
available_rows=""
missing_rows=""
checkfail_rows=""
updatefail_rows=""
fail_logs=""
had_failure=0

fetch() {
  curl -fsSL --connect-timeout 10 --max-time 20 "$1" 2>/dev/null
}

valid_ver() {
  [[ "$1" =~ ^[0-9]+(\.[0-9]+){1,3}(-[0-9A-Za-z.]+)?$ ]]
}

clean_ver() {
  printf '%s' "$1" | tr -d '[:space:]'
}

# Exit 0 when $1 is a newer dotted version than $2.
version_gt() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    split(a, A, /[^0-9]+/)
    split(b, B, /[^0-9]+/)
    for (i = 1; i <= 3; i++) {
      av = A[i] + 0
      bv = B[i] + 0
      if (av > bv) exit 0
      if (av < bv) exit 1
    }
    exit 1
  }'
}

version_of() {
  local bin="$1" line=""
  case "$bin" in
    claude) line="$(claude --version 2>/dev/null | awk 'NR==1 { print $1 }')" || line="" ;;
    codex)  line="$(codex --version 2>/dev/null | awk 'NR==1 { print $2 }')" || line="" ;;
    grok)   line="$(grok --version 2>/dev/null | awk 'NR==1 { print $2 }')" || line="" ;;
    agy)    line="$(agy --version 2>/dev/null | awk 'NR==1 { print $1 }')" || line="" ;;
  esac
  line="$(clean_ver "${line#v}")"
  if valid_ver "$line"; then
    printf '%s' "$line"
  fi
}

json_string() {
  # $1 = key. JSON on stdin. Prints the last string value for that key.
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n 1
}

claude_latest() {
  local raw
  raw="$(fetch "https://downloads.claude.ai/claude-code-releases/latest")" || return 1
  raw="$(clean_ver "$raw")"
  valid_ver "$raw" || return 1
  printf '%s' "$raw"
}

codex_latest() {
  local json tag
  json="$(fetch "https://releases.openai.com/codex/channels/latest")" || json=""
  if [[ -z "$json" ]]; then
    json="$(fetch "https://api.github.com/repos/openai/codex/releases/latest")" || return 1
  fi
  tag="$(printf '%s' "$json" | json_string tag_name)"
  tag="$(clean_ver "${tag#rust-v}")"
  valid_ver "$tag" || return 1
  printf '%s' "$tag"
}

agy_latest() {
  local raw ver
  raw="$(fetch "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app")" || return 1
  ver="$(printf '%s' "$raw" | sed -n 's/.*Stable Version:[[:space:]]*\([0-9]\{1,\}\(\.[0-9]\{1,\}\)\{1,3\}\).*/\1/p' | head -n 1)"
  ver="$(clean_ver "$ver")"
  valid_ver "$ver" || return 1
  printf '%s' "$ver"
}

row() {
  printf '  %-8s  %s\n' "$1" "$2"
}

add_updated()    { updated_rows="${updated_rows}$(row "$1" "$2")"$'\n'; }
add_current()    { current_rows="${current_rows}$(row "$1" "$2")"$'\n'; }
add_available()  { available_rows="${available_rows}$(row "$1" "$2")"$'\n'; }
add_missing()    { missing_rows="${missing_rows}$(row "$1" "$2")"$'\n'; }
add_checkfail()  { checkfail_rows="${checkfail_rows}$(row "$1" "$2")"$'\n'; had_failure=1; }
add_updatefail() { updatefail_rows="${updatefail_rows}$(row "$1" "$2")"$'\n'; had_failure=1; }

show_log() {
  local log="$1"
  [[ -s "$log" ]] || return 0
  fail_logs="${fail_logs}$(tail -n 20 "$log" | sed 's/^/    /')"$'\n'
}

install_update() {
  local name="$1" bin="$2" before="$3" latest="$4"
  local log now
  log="$tmpdir/${bin}.log"
  printf 'Updating %s (%s → %s)…\n' "$name" "$before" "$latest" >&2
  if "$bin" update >"$log" 2>&1; then
    hash -r
    now="$(version_of "$bin")"
    if [[ -n "$now" && "$now" != "$before" ]]; then
      add_updated "$name" "$before → $now"
    elif [[ -n "$now" ]]; then
      add_current "$name" "$now"
    else
      add_updatefail "$name" "$before (version unreadable after update)"
      show_log "$log"
    fi
  else
    add_updatefail "$name" "${before:-unknown}"
    show_log "$log"
  fi
}

# Captured installer used only when the version feed is down. Claude and agy
# exit without reinstalling when already current. Codex does not, so it has
# no fallback here.
fallback_update() {
  local name="$1" bin="$2" before="$3"
  local log now
  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    add_checkfail "$name" "${before:-unknown} (could not read the latest version)"
    return
  fi
  log="$tmpdir/${bin}.log"
  printf 'Checking %s with its own updater…\n' "$name" >&2
  if "$bin" update >"$log" 2>&1; then
    hash -r
    now="$(version_of "$bin")"
    if grep -Eqi 'up to date|already on the latest' "$log"; then
      add_current "$name" "${now:-$before}"
    elif [[ -n "$now" && -n "$before" && "$now" != "$before" ]]; then
      add_updated "$name" "$before → $now"
    elif [[ -n "$now" ]]; then
      add_current "$name" "$now"
    else
      add_updatefail "$name" "${before:-unknown}"
      show_log "$log"
    fi
  else
    add_updatefail "$name" "${before:-unknown}"
    show_log "$log"
  fi
}

check_claude() {
  local before="" latest=""
  if ! command -v claude >/dev/null 2>&1; then
    add_missing "Claude" "claude is not on PATH"
    return
  fi
  before="$(version_of claude)"
  if [[ -z "$before" ]]; then
    add_checkfail "Claude" "installed, version unreadable"
    return
  fi
  latest="$(claude_latest)" || latest=""
  if [[ -z "$latest" ]]; then
    fallback_update "Claude" claude "$before"
    return
  fi
  if [[ -n "$before" ]] && version_gt "$latest" "$before"; then
    if [[ "$CHECK_ONLY" -eq 1 ]]; then
      add_available "Claude" "$before → $latest"
    else
      install_update "Claude" claude "$before" "$latest"
    fi
  else
    add_current "Claude" "${before:-$latest}"
  fi
}

check_codex() {
  local before="" latest=""
  if ! command -v codex >/dev/null 2>&1; then
    add_missing "Codex" "codex is not on PATH"
    return
  fi
  before="$(version_of codex)"
  if [[ -z "$before" ]]; then
    add_checkfail "Codex" "installed, version unreadable"
    return
  fi
  latest="$(codex_latest)" || latest=""
  if [[ -z "$latest" ]]; then
    add_checkfail "Codex" "${before:-unknown} (could not read the latest version)"
    return
  fi
  if [[ -n "$before" ]] && version_gt "$latest" "$before"; then
    if [[ "$CHECK_ONLY" -eq 1 ]]; then
      add_available "Codex" "$before → $latest"
    else
      install_update "Codex" codex "$before" "$latest"
    fi
  else
    add_current "Codex" "${before:-$latest}"
  fi
}

check_grok() {
  local before="" json="" current="" latest="" available="" err=""
  if ! command -v grok >/dev/null 2>&1; then
    add_missing "Grok" "grok is not on PATH"
    return
  fi
  before="$(version_of grok)"
  if [[ -z "$before" ]]; then
    add_checkfail "Grok" "installed, version unreadable"
    return
  fi
  json="$(grok update --check --json 2>/dev/null)" || json=""
  if [[ -z "$json" ]]; then
    add_checkfail "Grok" "${before:-unknown} (could not read the latest version)"
    return
  fi
  current="$(printf '%s' "$json" | json_string currentVersion)"
  latest="$(printf '%s' "$json" | json_string latestVersion)"
  # BSD sed has no alternation in basic regex, so match the boolean literally.
  case "$json" in
    *'"updateAvailable": true'*|*'"updateAvailable":true'*) available=true ;;
    *'"updateAvailable": false'*|*'"updateAvailable":false'*) available=false ;;
    *) available="" ;;
  esac
  err="$(printf '%s' "$json" | json_string error)"
  [[ -n "$current" ]] && before="$current"
  if [[ -n "$err" ]]; then
    add_checkfail "Grok" "${before:-unknown} ($err)"
    return
  fi
  if [[ -z "$available" ]]; then
    add_checkfail "Grok" "${before:-unknown} (could not read the latest version)"
    return
  fi
  if [[ "$available" == "true" ]]; then
    if [[ "$CHECK_ONLY" -eq 1 ]]; then
      add_available "Grok" "${before:-?} → ${latest:-newer}"
    else
      install_update "Grok" grok "${before:-unknown}" "${latest:-newer}"
    fi
  else
    add_current "Grok" "${before:-${latest:-unknown}}"
  fi
}

check_agy() {
  local before="" latest=""
  if ! command -v agy >/dev/null 2>&1; then
    add_missing "Gemini" "agy is not on PATH"
    return
  fi
  before="$(version_of agy)"
  if [[ -z "$before" ]]; then
    add_checkfail "Gemini" "installed, version unreadable"
    return
  fi
  latest="$(agy_latest)" || latest=""
  if [[ -z "$latest" ]]; then
    fallback_update "Gemini" agy "$before"
    return
  fi
  if [[ -n "$before" ]] && version_gt "$latest" "$before"; then
    if [[ "$CHECK_ONLY" -eq 1 ]]; then
      add_available "Gemini" "$before → $latest"
    else
      install_update "Gemini" agy "$before" "$latest"
    fi
  else
    add_current "Gemini" "${before:-$latest}"
  fi
}

print_group() {
  local title="$1" body="$2" color="$3"
  [[ -n "$body" ]] || return 0
  printf '%s%s%s%s\n' "$b" "$color" "$title" "$n"
  printf '%s' "$body"
  printf '\n'
}

printf 'Checking Claude, Codex, Grok, and Gemini…\n' >&2
check_claude
check_codex
check_grok
check_agy

printf '\n%sAgent updates%s\n\n' "$b" "$n"
if [[ "$CHECK_ONLY" -eq 0 && -z "$updated_rows" ]]; then
  printf '%sUpdated%s\n' "$b" "$n"
  printf '  (none)\n\n'
fi
if [[ "$CHECK_ONLY" -eq 1 && -z "$available_rows" ]]; then
  printf '%sWould update%s\n' "$b" "$n"
  printf '  (none)\n\n'
fi
print_group "Updated" "$updated_rows" "$g"
print_group "Would update" "$available_rows" "$y"
print_group "Already current" "$current_rows" ""
print_group "Not installed" "$missing_rows" "$y"
print_group "Could not check" "$checkfail_rows" "$r"
print_group "Update failed" "$updatefail_rows" "$r"
if [[ -n "$fail_logs" ]]; then
  printf '%sUpdater output%s\n%s\n' "$b" "$n" "$fail_logs"
fi
if [[ -n "$updated_rows" ]]; then
  printf 'Restart any open session of an updated tool so it picks up the new binary.\n'
fi

if [[ "$had_failure" -ne 0 ]]; then
  exit 1
fi
exit 0
