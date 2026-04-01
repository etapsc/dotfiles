#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Pinned versions — update these when upgrading
STARSHIP_VERSION="1.22.1"
ZELLIJ_VERSION="0.43.1"
NERD_FONT_VERSION="3.3.0"

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd -P)"

log() {
  printf '[bootstrap-ubuntu] %s\n' "$*"
}

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    printf 'error: sudo is required on Ubuntu bootstrap\n' >&2
    exit 1
  fi
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

require_sudo

backup_dir="$HOME/.dotfiles-backup/$(date '+%Y%m%d-%H%M%S')"

# --- Install packages ---

log "updating apt package index"
sudo apt-get update

log "installing apt packages"
sudo apt-get install -y \
  zsh \
  stow \
  curl \
  unzip \
  gnupg \
  fontconfig \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  ripgrep \
  fd-find \
  fzf \
  bat

# batcat -> bat symlink (Debian/Ubuntu naming)
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  log "linking batcat to ~/.local/bin/bat"
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# fdfind -> fd symlink (Debian/Ubuntu naming)
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  log "linking fdfind to ~/.local/bin/fd"
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# starship (not in standard Ubuntu repos)
if ! command -v starship >/dev/null 2>&1; then
  log "installing starship ${STARSHIP_VERSION}"
  tmp="$(mktemp -d)"
  arch="$(uname -m)"
  curl -fsSL -o "$tmp/starship.tar.gz" \
    "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-${arch}-unknown-linux-musl.tar.gz"
  tar -xzf "$tmp/starship.tar.gz" -C "$tmp"
  sudo install -m 755 "$tmp/starship" /usr/local/bin/starship
  rm -rf "$tmp"
fi

# zellij (not in standard Ubuntu repos)
if ! command -v zellij >/dev/null 2>&1; then
  log "installing zellij ${ZELLIJ_VERSION}"
  tmp="$(mktemp -d)"
  arch="$(uname -m)"
  curl -fsSL "https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${arch}-unknown-linux-musl.tar.gz" \
    | tar -xz -C "$tmp"
  sudo install -m 755 "$tmp/zellij" /usr/local/bin/zellij
  rm -rf "$tmp"
fi

# eza (not in standard Ubuntu repos)
if ! command -v eza >/dev/null 2>&1; then
  log "adding eza apt repository"
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt-get update
  sudo apt-get install -y eza
fi

# alacritty (try apt first, available on Ubuntu 24.10+)
if ! command -v alacritty >/dev/null 2>&1; then
  if apt-cache show alacritty >/dev/null 2>&1; then
    log "installing alacritty from apt"
    sudo apt-get install -y alacritty
  else
    log "WARN: alacritty not in apt — install manually from https://alacritty.org"
  fi
fi

# JetBrains Mono Nerd Font
font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
if [[ ! -d "$font_dir" ]]; then
  log "installing JetBrains Mono Nerd Font ${NERD_FONT_VERSION}"
  mkdir -p "$font_dir"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/JetBrainsMono.tar.xz" \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VERSION}/JetBrainsMono.tar.xz"
  tar -xf "$tmp/JetBrainsMono.tar.xz" -C "$font_dir"
  rm -rf "$tmp"
  fc-cache -f "$font_dir"
fi

# --- Deploy configs ---

log "deploying dotfiles with stow"

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.config/alacritty/alacritty.toml"
backup_if_exists "$HOME/.config/starship.toml"
backup_if_exists "$HOME/.config/zellij/config.kdl"
backup_if_exists "$HOME/.config/zellij/layouts"
backup_if_exists "$HOME/.config/zsh/plugins"

cd "$repo_root"
stow -t "$HOME" zsh zellij alacritty starship

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
  sudo chsh -s "$zsh_path" "$(whoami)"
fi

# --- Post-install notes ---

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log "NOTE: ~/.oh-my-zsh still exists — safe to remove once you confirm the new setup works"
fi

if [[ -e "$HOME/.p10k.zsh" ]]; then
  log "NOTE: ~/.p10k.zsh still exists — no longer needed, safe to remove"
fi

log "bootstrap complete — run 'exec zsh' to start the new shell"
