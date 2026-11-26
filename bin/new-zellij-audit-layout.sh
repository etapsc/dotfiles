#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: new-zellij-audit-layout.sh [--force] [--session <session>] <name>

Asks how many projects to audit, then the path to each project and a short
label for it (press Enter to use the directory name). Writes
zellij/.config/zellij/layouts/projects/<name>.kdl with three tabs per
project, all opened in that project's directory: "<label> Auditor",
"<label> Provider", and "<label> other" split into two side-by-side panes.
A final "Shell" tab opens in the projects' common parent directory.
N projects give 3N+1 tabs.

The Zellij session is named after the layout unless --session gives another
name; the layout reattaches to that session if it already exists.

Answers can also be piped on stdin, one per line: the project count, then
for each project its path followed by its label (an empty line keeps the
directory name).

Examples:
  new-zellij-audit-layout.sh --session Tools audit-tools
  printf '%s\n' 2 ~/work/sn-api-server snapi ~/work/lumescope '' |
    new-zellij-audit-layout.sh --force --session Tools audit-tools
EOF
}

max_projects=20
safe_name='^[A-Za-z0-9_][A-Za-z0-9._-]*$'

force=0
session=""
session_given=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --session)
      if [[ $# -lt 2 ]]; then
        usage >&2
        exit 1
      fi
      session="$2"
      session_given=1
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      printf 'error: unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

name="$1"
if [[ ! "$name" =~ $safe_name ]]; then
  printf 'error: layout name may use only letters, digits, ".", "_" and "-": %s\n' "$name" >&2
  exit 1
fi

if [[ $session_given -ne 1 ]]; then
  session="$name"
fi
if [[ ! "$session" =~ $safe_name ]]; then
  printf 'error: session name may use only letters, digits, ".", "_" and "-": %s\n' "$session" >&2
  exit 1
fi

script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(CDPATH='' cd -- "$script_dir/.." && pwd -P)"
layouts_dir="$repo_root/zellij/.config/zellij/layouts/projects"
target_file="$layouts_dir/$name.kdl"

if [[ -e "$target_file" && $force -ne 1 ]]; then
  printf 'error: layout already exists: %s\n' "$target_file" >&2
  printf 'hint: rerun with --force to overwrite it\n' >&2
  exit 1
fi

# At a terminal an invalid answer is asked again; with piped answers it is fatal,
# because retrying would silently consume the next answer.
interactive=0
if [[ -t 0 ]]; then
  interactive=1
fi

invalid() {
  printf 'error: %s\n' "$1" >&2
  if [[ $interactive -ne 1 ]]; then
    exit 1
  fi
}

# ask <prompt> <variable>: read one line (readline with path completion at a terminal).
ask() {
  local answer
  if ! IFS= read -e -r -p "$1" answer; then
    printf '\nerror: input ended before all answers were given\n' >&2
    exit 1
  fi
  printf -v "$2" '%s' "$answer"
}

count=""
while :; do
  ask "How many projects? " count
  if [[ "$count" =~ ^[1-9][0-9]?$ ]] && (( count <= max_projects )); then
    break
  fi
  invalid "project count must be a whole number from 1 to $max_projects: $count"
done

labels=()
paths=()
for (( i = 1; i <= count; i++ )); do
  while :; do
    ask "Path to project $i: " input_dir
    if [[ "$input_dir" == "~"* ]]; then
      input_dir="${HOME}${input_dir#\~}"
    fi
    if [[ -z "$input_dir" || ! -d "$input_dir" ]]; then
      invalid "directory does not exist: $input_dir"
      continue
    fi
    project_dir="$(CDPATH='' cd -- "$input_dir" && pwd -P)"
    # The path is written into a KDL string, so refuse characters that would need escaping.
    if [[ "$project_dir" == *[\"\\]* ]]; then
      invalid "path contains a quote or backslash, which the layout cannot hold: $project_dir"
      continue
    fi
    break
  done

  default_label="$(basename -- "$project_dir")"
  while :; do
    ask "Label for project $i [$default_label]: " label
    label="${label:-$default_label}"
    if [[ ! "$label" =~ ^[A-Za-z0-9._-]+$ ]]; then
      invalid "label may use only letters, digits, \".\", \"_\" and \"-\": $label"
      continue
    fi
    duplicate=0
    for existing in "${labels[@]+"${labels[@]}"}"; do
      if [[ "$existing" == "$label" ]]; then
        duplicate=1
      fi
    done
    if [[ $duplicate -eq 1 ]]; then
      invalid "label is already used by another project: $label"
      continue
    fi
    break
  done

  labels+=("$label")
  paths+=("$project_dir")
done

# The Shell tab opens in the deepest directory that contains every project
# (with one project, its parent directory).
shell_dir="$(dirname -- "${paths[0]}")"
for project_dir in "${paths[@]}"; do
  while [[ "$shell_dir" != "/" && "$project_dir" != "$shell_dir"/* ]]; do
    shell_dir="$(dirname -- "$shell_dir")"
  done
done

timestamp="$(date '+%Y-%m-%dT%H:%M:%S%z')"
mkdir -p "$layouts_dir"

{
  printf '// name: %s\n' "$name"
  printf '// type: audit\n'
  printf '// session: %s\n' "$session"
  printf '// shell: %s\n' "$shell_dir"
  for (( i = 0; i < count; i++ )); do
    printf '// project: %s %s\n' "${labels[i]}" "${paths[i]}"
  done
  printf '// created: %s\n' "$timestamp"
  cat <<EOF
layout {
    cwd "$shell_dir"
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="tab-bar"
        }
        children
        pane size=1 borderless=true {
            plugin location="status-bar"
        }
    }
EOF
  for (( i = 0; i < count; i++ )); do
    focus=""
    if [[ $i -eq 0 ]]; then
      focus=" focus=true"
    fi
    printf '    tab name="%s Auditor" cwd="%s"%s\n' "${labels[i]}" "${paths[i]}" "$focus"
    printf '    tab name="%s Provider" cwd="%s"\n' "${labels[i]}" "${paths[i]}"
    printf '    tab name="%s other" cwd="%s" split_direction="vertical" {\n' "${labels[i]}" "${paths[i]}"
    printf '        pane size="50%%"\n'
    printf '        pane size="50%%"\n'
    printf '    }\n'
  done
  cat <<EOF
    tab name="Shell"
}
session_name "$session"
attach_to_session true
EOF
} >"$target_file"

printf 'created: %s (%d tabs, session %s)\n' "$target_file" $(( count * 3 + 1 )) "$session"
printf 'use with: zellij -l ~/.config/zellij/layouts/projects/%s.kdl\n' "$name"
