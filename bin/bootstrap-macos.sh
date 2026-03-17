#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd -P)"

log() {
  printf '[bootstrap-macos] %s\n' "$*"
}

backup_if_exists() {
  local path="$1"
  if [[ -L "$path" ]]; then
    mkdir -p "$backup_dir"
    local name
    name="$(basename "$path")"
    if cp -rL "$path" "$backup_dir/$name" 2>/dev/null; then
      log "backing up $path → $backup_dir/$name"
    else
      log "removing broken symlink $path"
    fi
    rm -f "$path"
  elif [[ -e "$path" ]]; then
    mkdir -p "$backup_dir"
    local name
    name="$(basename "$path")"
    log "backing up $path → $backup_dir/$name"
    mv "$path" "$backup_dir/$name"
  fi
}

if ! command -v brew >/dev/null 2>&1; then
  printf 'error: Homebrew is required. Install it first from https://brew.sh/\n' >&2
  exit 1
fi

backup_dir="$HOME/.dotfiles-backup/$(date '+%Y%m%d-%H%M%S')"

# --- Install packages ---

log "updating Homebrew"
brew update

log "installing formulae"
brew install \
  zsh \
  stow \
  alacritty \
  zellij \
  starship \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  ripgrep \
  fd \
  fzf \
  bat \
  eza

log "installing JetBrains Mono Nerd Font"
brew install --cask font-jetbrains-mono-nerd-font

# --- Deploy configs ---

log "deploying dotfiles with stow"

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.config/alacritty/alacritty.toml"
backup_if_exists "$HOME/.config/starship.toml"
backup_if_exists "$HOME/.config/zellij/config.kdl"
backup_if_exists "$HOME/.config/zellij/layouts"
backup_if_exists "$HOME/.config/zsh/plugins"

cd "$repo_root"
stow zsh zellij alacritty starship

if [[ -d "$backup_dir" ]]; then
  log "old configs backed up to $backup_dir"
fi

# --- Set default shell ---

zsh_path="$(command -v zsh)"
if [[ "$SHELL" != */zsh ]]; then
  if ! grep -qxF "$zsh_path" /etc/shells; then
    log "adding $zsh_path to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi
  log "setting zsh as default shell"
  chsh -s "$zsh_path"
fi

# --- Post-install notes ---

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log "NOTE: ~/.oh-my-zsh still exists — safe to remove once you confirm the new setup works"
fi

if [[ -e "$HOME/.p10k.zsh" ]]; then
  log "NOTE: ~/.p10k.zsh still exists — no longer needed, safe to remove"
fi

log "bootstrap complete — run 'exec zsh' to start the new shell"
