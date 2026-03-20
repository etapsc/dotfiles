# Dotfiles

Terminal development environment: Alacritty, zsh, Starship, Zellij. Neovim is in a separate repo.

Replaces Oh My Zsh and Powerlevel10k with plain zsh, direct plugin loading, and Starship.

## Setup

### 1. Clone

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
```

### 2. Run bootstrap

The bootstrap script installs all dependencies, backs up any existing configs, deploys dotfiles via GNU Stow, and sets zsh as the default shell.

Ubuntu:

```bash
./bin/bootstrap-ubuntu.sh
exec zsh
```

macOS (requires [Homebrew](https://brew.sh)):

```bash
./bin/bootstrap-macos.sh
exec zsh
```

If you had Oh My Zsh or Powerlevel10k, the bootstrap backs up your old `~/.zshrc` to `~/.dotfiles-backup/<timestamp>/` and tells you when `~/.oh-my-zsh` and `~/.p10k.zsh` are safe to remove.

### 3. Verify

```bash
./bin/check-health.sh
```

This checks that all binaries are installed, symlinks point into the repo, and plugin files exist at expected paths.

## Zellij Layouts

Three built-in layouts:

- `dev.kdl` — `agents` + `code` (nvim) + `shell` tabs
- `review.kdl` — `review` (nvim) + `agents` + `git` tabs
- `shell.kdl` — plain two-pane workspace

```bash
zellij -l ~/.config/zellij/layouts/dev.kdl
```

### Project layouts

Generate a project-specific layout with:

```bash
./bin/new-zellij-project-layout.sh bridge ~/Work/bridge
zellij -l ~/.config/zellij/layouts/projects/bridge.kdl
```

Generated project layouts set the Zellij session name to the layout name and reattach if that session already exists.

Use `--force` to overwrite an existing layout.

## Uninstall

Remove symlinks and restore backed-up configs:

```bash
cd ~/dotfiles
stow -D zsh zellij alacritty starship
# then restore from ~/.dotfiles-backup/<timestamp>/ if needed
```

## Pinned Versions (Ubuntu)

The Ubuntu bootstrap pins tool versions not available in apt. Update these at the top of `bin/bootstrap-ubuntu.sh`:

| Tool | Variable | Current |
|------|----------|---------|
| Starship | `STARSHIP_VERSION` | 1.22.1 |
| Zellij | `ZELLIJ_VERSION` | 0.43.1 |
| Nerd Font | `NERD_FONT_VERSION` | 3.3.0 |

## Neovim

Not managed here. These dotfiles assume `nvim` is on `PATH` and wire it into the shell and Zellij layouts.
