#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd -P)"

plugin_path() {
  local candidate
  for candidate in "$@"; do
    if [[ -r "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

check_binary() {
  local name="$1"
  local version_args="$2"
  if command -v "$name" >/dev/null 2>&1; then
    local version
    version="$("$name" $version_args 2>/dev/null | head -n 1 || true)"
    printf 'OK   binary %-10s %s\n' "$name" "${version:-installed}"
  else
    printf 'MISS binary %s\n' "$name"
  fi
}

check_symlink() {
  local path="$1"
  if [[ -L "$path" ]]; then
    printf 'OK   symlink %s -> %s\n' "$path" "$(readlink "$path")"
  elif [[ -e "$path" ]]; then
    local resolved
    resolved="$(perl -MCwd=realpath -e 'my $path = shift; my $real = realpath($path); print $real if defined $real;' "$path")"
    case "$resolved" in
      "$repo_root"/*)
        printf 'OK   managed %s -> %s\n' "$path" "$resolved"
        ;;
      *)
        printf 'WARN path exists but is not repo-managed: %s\n' "$path"
        ;;
    esac
  else
    printf 'MISS symlink %s\n' "$path"
  fi
}

printf 'repo: %s\n' "$repo_root"

check_binary zsh '--version'
check_binary zellij '--version'
check_binary nvim '--version'
check_binary starship '--version'
check_binary alacritty '--version'
check_binary claude '--version'
check_binary codex '--version'

check_symlink "$HOME/.zshrc"
check_symlink "$HOME/.config/alacritty/alacritty.toml"
check_symlink "$HOME/.config/starship.toml"
check_symlink "$HOME/.config/zellij/config.kdl"
check_symlink "$HOME/.config/zellij/layouts/dev.kdl"
check_symlink "$HOME/.config/zellij/layouts/shell.kdl"
check_symlink "$HOME/.config/zellij/layouts/review.kdl"

autosuggest_path="$(plugin_path \
  "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh" || true)"
syntax_path="$(plugin_path \
  "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" || true)"

if [[ -n "$autosuggest_path" ]]; then
  printf 'OK   plugin zsh-autosuggestions %s\n' "$autosuggest_path"
else
  printf 'MISS plugin zsh-autosuggestions\n'
fi

if [[ -n "$syntax_path" ]]; then
  printf 'OK   plugin zsh-syntax-highlighting %s\n' "$syntax_path"
else
  printf 'MISS plugin zsh-syntax-highlighting\n'
fi
