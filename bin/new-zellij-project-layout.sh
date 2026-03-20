#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: new-zellij-project-layout.sh [--force] <name> <directory>

Example:
  new-zellij-project-layout.sh bridge ~/Work/bridge
EOF
}

force=0
if [[ "${1:-}" == "--force" ]]; then
  force=1
  shift
fi

if [[ $# -ne 2 ]]; then
  usage >&2
  exit 1
fi

name="$1"
input_dir="$2"

case "$name" in
  ""|*/*)
    printf 'error: layout name must be a simple file-safe name\n' >&2
    exit 1
    ;;
esac

if [[ "$input_dir" == "~"* ]]; then
  input_dir="${HOME}${input_dir#\~}"
fi

if [[ ! -d "$input_dir" ]]; then
  printf 'error: directory does not exist: %s\n' "$input_dir" >&2
  exit 1
fi

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd -P)"
layouts_dir="$repo_root/zellij/.config/zellij/layouts/projects"
target_file="$layouts_dir/$name.kdl"
project_dir="$(CDPATH= cd -- "$input_dir" && pwd -P)"
timestamp="$(date '+%Y-%m-%dT%H:%M:%S%z')"

mkdir -p "$layouts_dir"

if [[ -e "$target_file" && $force -ne 1 ]]; then
  printf 'error: layout already exists: %s\n' "$target_file" >&2
  printf 'hint: rerun with --force to overwrite it\n' >&2
  exit 1
fi

cat >"$target_file" <<EOF
// name: $name
// path: $project_dir
// created: $timestamp
layout {
    cwd "$project_dir"
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        children
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
    tab name="agents" focus=true split_direction="vertical" {
        pane size="50%"
        pane size="50%"
    }
    tab name="code" {
        pane command="nvim"
    }
    tab name="shell" split_direction="vertical" {
        pane size="50%"
        pane size="50%"
    }
}
session_name "$name"
attach_to_session true
EOF

printf 'created: %s\n' "$target_file"
printf 'use with: zellij -l ~/.config/zellij/layouts/projects/%s.kdl\n' "$name"
