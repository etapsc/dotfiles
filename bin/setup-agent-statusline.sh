#!/usr/bin/env bash
# setup-agent-statusline.sh — install the Claude Code, Grok and Codex status
# lines on this machine. Safe to re-run; a second run changes nothing.
#
#   1. Links the status line scripts from the agent-cli stow package:
#        ~/.claude/statusline.sh   ~/.grok/statusline.sh
#      --no-folding keeps ~/.claude and ~/.grok real directories. Without it,
#      stow would turn a missing ~/.claude into a symlink into this repo, and
#      the CLI would then write credentials and history here. An existing
#      script that differs from the repo copy is moved to ~/.dotfiles-backup.
#   2. Sets the status line keys in each CLI's own config:
#        claude  ~/.claude/settings.json  .statusLine
#        grok    ~/.grok/config.toml      [ui.status_line]
#        codex   ~/.codex/config.toml     [tui] status_line, status_line_use_colors
#
# The agent configs are not stow-managed: they also hold permissions, trusted
# projects, plugin state and theme-toggle's theme keys. Only the keys above are
# touched. Each file is edited in a temp copy beside it, validated as JSON or
# TOML, and renamed over the original only when it changed and still parses.
# Claude's settings.json is created if missing; Codex and Grok write their
# config.toml on first run, so start them once and re-run this.
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd -P)"
pkg="agent-cli"
scripts=(.claude/statusline.sh .grok/statusline.sh)

# --- the status lines --------------------------------------------------------

claude_statusline='{"type":"command","command":"~/.claude/statusline.sh"}'

grok_type='"command"'
grok_command='"~/.grok/statusline.sh"'
grok_refresh_interval='120'

codex_items=(
  model-with-reasoning current-dir thread-name project-name git-branch
  pull-request-number branch-changes permissions context-remaining
  five-hour-limit weekly-limit codex-version context-window-size used-tokens
)

# -----------------------------------------------------------------------------

usage() {
  cat <<'EOF'
Usage: setup-agent-statusline.sh [--check]

Links the agent-cli status line scripts and sets the status line keys in the
Claude Code, Grok and Codex configs.

Options:
  --check     Report whether this machine matches; change nothing.
              Exits 1 when something is missing or differs.
  -h, --help  Show this help.
EOF
}

check=0
problems=0
cleanup=()
trap 'rm -f "${cleanup[@]+"${cleanup[@]}"}"' EXIT

report() {
  printf '%-4s %-7s %s\n' "$1" "$2" "$3"
}

problem() {
  report "$@"
  problems=$((problems + 1))
}

# resolve <path> — follow symlinks so an edit lands on the real file instead of
# replacing the link.
resolve() {
  local p="$1" link
  while [[ -L "$p" ]]; do
    link="$(readlink "$p")"
    case "$link" in
      /*) p="$link" ;;
      *)  p="$(dirname "$p")/$link" ;;
    esac
  done
  printf '%s\n' "$p"
}

# stage <file> — a copy of <file> to edit. It sits beside the file, with the
# same permissions, so the final rename keeps the mode and stays on one
# filesystem. --check never renames, so its copies go to $TMPDIR.
stage() {
  local dir
  dir="$(dirname "$1")"
  if ((check)); then
    dir="${TMPDIR:-/tmp}"
  fi
  local tmp
  tmp="$(mktemp "$dir/.setup-agent-statusline.XXXXXX")"
  cp -p "$1" "$tmp"
  printf '%s\n' "$tmp"
}

toml_string_array() {
  local out="" item
  for item in "$@"; do
    out+="${out:+, }\"$item\""
  done
  printf '[%s]' "$out"
}

# One key upsert inside one table. Reads the file twice: pass 1 learns whether
# the table and key exist, pass 2 rewrites. An existing key is replaced where
# it sits, keeping its indentation (a multi-line array value is replaced
# whole); a missing key goes after the table's last non-blank line; a missing
# table is appended. Sub-tables such as [tui.model_availability_nux] never
# match, because the header must equal HDR exactly.
toml_upsert='
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function header(t) { sub(/[ \t]*#.*$/, "", t); return t }
function iskey(t) { return t ~ ("^" key "[ \t]*=") }
function brackets(s,   o) { o = gsub(/\[/, "[", s); return o - gsub(/\]/, "]", s) }
function flush() { printf "%s", held; held = "" }
function addkey() { print indent key " = " val; added = 1 }
BEGIN { hdr = ENVIRON["HDR"]; key = ENVIRON["KEY"]; val = ENVIRON["VAL"] }
NR == FNR {
  t = trim($0)
  if (substr(t, 1, 1) == "[") { intable = (header(t) == hdr); if (intable) sawtable = 1; next }
  if (intable && iskey(t)) haskey = 1
  next
}
FNR == 1 { intable = 0 }
depth > 0 { depth += brackets($0); next }
{
  t = trim($0)
  if (substr(t, 1, 1) == "[") {
    if (intable && !haskey && !added) addkey()
    flush()
    intable = (header(t) == hdr)
    if (intable) { match($0, /^[ \t]*/); indent = substr($0, 1, RLENGTH) }
    print
    next
  }
  if (intable && iskey(t)) {
    flush()
    match($0, /^[ \t]*/)
    print substr($0, 1, RLENGTH) key " = " val
    rest = t; sub(/^[^=]*=/, "", rest)
    depth = brackets(rest)
    next
  }
  if (intable && t == "") { held = held $0 "\n"; next }
  flush()
  print
}
END {
  if (intable && !haskey && !added) addkey()
  flush()
  if (!sawtable) { print ""; print hdr; print key " = " val }
}
'

# --- 1. scripts --------------------------------------------------------------

check_links() {
  local rel target
  for rel in "${scripts[@]}"; do
    target="$HOME/$rel"
    if [[ -L "$target" && "$target" -ef "$repo_root/$pkg/$rel" ]]; then
      report OK symlink "$target -> $(readlink "$target")"
    else
      problem MISS symlink "$target"
    fi
  done
}

link_scripts() {
  local rel target backup_dir=""

  if ! command -v stow >/dev/null 2>&1; then
    problem FAIL symlink "stow not found; install it (the bootstrap scripts do)"
    return
  fi

  for rel in "${scripts[@]}"; do
    target="$HOME/$rel"
    if [[ -L "$target" || ! -e "$target" ]]; then
      continue
    fi
    if cmp -s "$target" "$repo_root/$pkg/$rel"; then
      rm -f "$target"
    else
      backup_dir="${backup_dir:-$HOME/.dotfiles-backup/$(date '+%Y%m%d-%H%M%S')}"
      mkdir -p "$backup_dir/$(dirname "$rel")"
      mv "$target" "$backup_dir/$rel"
      report BAK symlink "$target moved to $backup_dir/$rel"
    fi
  done

  if ! stow --no-folding --restow -d "$repo_root" -t "$HOME" "$pkg"; then
    problem FAIL symlink "stow could not link $pkg (see above)"
    return
  fi
  check_links
}

# --- 2. config keys ----------------------------------------------------------

setup_claude() {
  local file="$HOME/.claude/settings.json" tmp label=".statusLine"

  if ! command -v jq >/dev/null 2>&1; then
    problem FAIL claude "jq not found; install it to edit $file"
    return
  fi
  if [[ ! -e "$file" ]]; then
    if ((check)); then
      problem MISS claude "$file"
      return
    fi
    mkdir -p "$(dirname "$file")"
    printf '{}\n' > "$file"
  fi
  file="$(resolve "$file")"

  if jq -e --argjson v "$claude_statusline" '.statusLine == $v' "$file" >/dev/null 2>&1; then
    report OK claude "$label in $file"
    return
  fi
  if ((check)); then
    problem DIFF claude "$label in $file; run bin/setup-agent-statusline.sh"
    return
  fi

  tmp="$(stage "$file")"
  cleanup+=("$tmp")
  if jq --argjson v "$claude_statusline" '.statusLine = $v' "$file" > "$tmp" 2>/dev/null; then
    mv -f "$tmp" "$file"
    report SET claude "$label in $file"
  else
    problem FAIL claude "$file does not parse as JSON; left untouched"
  fi
}

# setup_toml <cli> <file> <table> <label> <key> <value> [<key> <value> ...]
setup_toml() {
  local cli="$1" file="$2" table="$3" label="$4" tmp next
  shift 4

  if [[ ! -e "$file" ]]; then
    report SKIP "$cli" "$file not found; run $cli once, then re-run"
    return
  fi
  if ! python3 -c 'import tomllib' 2>/dev/null; then
    problem FAIL "$cli" "needs python3 >= 3.11 (tomllib) to validate $file"
    return
  fi
  file="$(resolve "$file")"

  tmp="$(stage "$file")"
  next="$(stage "$file")"
  cleanup+=("$tmp" "$next")
  while (($#)); do
    HDR="[$table]" KEY="$1" VAL="$2" awk "$toml_upsert" "$tmp" "$tmp" > "$next"
    cat "$next" > "$tmp"
    shift 2
  done

  if cmp -s "$tmp" "$file"; then
    report OK "$cli" "$label in $file"
    return
  fi
  if ((check)); then
    problem DIFF "$cli" "$label in $file; run bin/setup-agent-statusline.sh"
    return
  fi
  if ! python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$tmp" 2>/dev/null; then
    problem FAIL "$cli" "edit would not parse as TOML; $file left untouched"
    return
  fi
  mv -f "$tmp" "$file"
  report SET "$cli" "$label in $file"
}

# -----------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      check=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if ((check)); then
  check_links
else
  link_scripts
fi

setup_claude

setup_toml codex "$HOME/.codex/config.toml" tui "[tui] status_line" \
  status_line "$(toml_string_array "${codex_items[@]}")" \
  status_line_use_colors true

setup_toml grok "$HOME/.grok/config.toml" ui.status_line "[ui.status_line]" \
  type "$grok_type" \
  command "$grok_command" \
  refresh_interval "$grok_refresh_interval"

if ((problems)); then
  exit 1
fi
