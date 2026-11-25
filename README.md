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

Older or slower Macs, especially unsupported Monterey installs:

```bash
./bin/bootstrap-macos.sh --minimal
exec zsh
```

Minimal mode installs only zsh, Stow, Zellij, Starship, zsh plugins, and a few shell tools. It skips `brew update`, Alacritty, and the Nerd Font cask so one slow or unsupported GUI package does not block a usable terminal setup. Zellij is installed from its official prebuilt `zellij-no-web` macOS release instead of Homebrew to avoid slow source builds on older macOS versions.

If you had Oh My Zsh or Powerlevel10k, the bootstrap backs up your old `~/.zshrc` to `~/.dotfiles-backup/<timestamp>/` and tells you when `~/.oh-my-zsh` and `~/.p10k.zsh` are safe to remove.

### 3. Verify

```bash
./bin/check-health.sh
```

This checks that all binaries are installed, symlinks point into the repo, and plugin files exist at expected paths.

For a minimal macOS install, use:

```bash
./bin/check-health.sh --minimal
```

## Zellij Layouts

Three built-in layouts:

- `dev.kdl` — `agents` + `code` (nvim) + `shell` tabs
- `review.kdl` — `review` (nvim) + `agents` + `git` tabs
- `shell.kdl` — plain two-pane workspace

```bash
zellij -l ~/.config/zellij/layouts/dev.kdl
```

### Project layouts

Generate a project-specific layout with single-pane `claude`, `codex`, and
`grok` tabs, a `code` tab running Neovim, and two-pane `tools` and `shell`
tabs:

```bash
./bin/new-zellij-project-layout.sh bridge ~/Work/bridge
zellij -l ~/.config/zellij/layouts/projects/bridge.kdl
```

Generated project layouts set the Zellij session name to the layout name and reattach if that session already exists.

Use `--force` to overwrite an existing layout.

### Audit layouts

Generate a layout for auditing several repositories at once. The script asks
how many projects there are, then the path to each and a short label (Enter
keeps the directory name). Each project gets an `<label> Auditor` and an
`<label> Provider` tab, both opened in that repository; a final `Shell` tab
opens in the projects' common parent directory. N projects give 2N+1 tabs.

```bash
./bin/new-zellij-audit-layout.sh --session Tools audit-tools
zellij -l ~/.config/zellij/layouts/projects/audit-tools.kdl
```

Answers can be piped instead, one per line (count, then path and label for
each project; an empty label keeps the directory name). The `// session:` and
`// project:` header lines of an existing audit layout list the session name,
labels and paths to reuse when regenerating it on another host:

```bash
printf '%s\n' 2 ~/work/sn-api-server snapi ~/work/lumescope '' |
  ./bin/new-zellij-audit-layout.sh --force --session Tools audit-tools
```

The session is named after the layout unless `--session` names it. Like project
layouts, audit layouts reattach to that session if it already exists, so delete
an existing session of that name before its new tabs appear. Use `--force` to
overwrite an existing layout.

## Theme

`theme-toggle` switches the terminal (Alacritty + Zellij) and the three agent
CLIs between Catppuccin flavours in one shot.

```bash
theme-toggle                 # toggle latte <-> macchiato
theme-toggle mocha           # pick a flavour: latte | frappe | macchiato | mocha
theme-toggle light           # aliases for the toggle endpoints
theme-toggle dark
theme-toggle auto            # agents follow the terminal; terminal unchanged
theme-toggle status          # print the flavour and every agent's theme
```

Alacritty reloads live via `live_config_reload` and Zellij (>= 0.42) via its
config watcher. Restart existing agent sessions after editing their config.
Claude's auto mode and Grok's Terminal theme can then follow terminal colors;
Codex may still need a restart when the terminal background changes.

### Agent support

| CLI | Config | Key | Follows the terminal? |
|---|---|---|---|
| Claude Code | `~/.claude/settings.json` | `.theme` | yes — `auto` is "Auto (match terminal)" |
| Grok | `~/.grok/config.toml` | `[ui] theme` | yes — `terminal-default` takes every colour from the terminal palette |
| Codex | `~/.codex/config.toml` | `[tui] theme` | no |

`theme-toggle auto` also sets grok's `[features] terminal_theme = true`, because
the Terminal theme is still rollout-gated. Grok's own `theme = "auto"` follows
the *OS* appearance rather than the terminal, so it is deliberately not used.

Codex has no terminal-following mode and no TUI chrome theme at all: `[tui]
theme` and the `/theme` picker only select the syntect `.tmTheme` used for
**syntax highlighting**. Codex paints its chrome — the composer included — from
the terminal's ANSI palette plus the foreground/background it reads once at
startup via OSC 10/11, so a live flavour switch never reaches it. That is why
the composer stays dark after a toggle and why `/theme` cannot fix it. **Restart
codex.** Under `auto`, codex is pinned to the `.tmTheme` matching the current
flavour.

Agent configs are not stow-managed, so `theme-toggle` edits them in place under
`$HOME`. Each write is a single-key upsert, staged in a temp file and validated
as JSON/TOML before it replaces the original; an unparseable result is refused
and the existing file is left untouched. Original file permissions are preserved.
A failed write returns a nonzero status and is not reported as a successful
agent update; other agent updates are still attempted.

### Following Ubuntu appearance

GNOME settings do not select the terminal palette. To connect a GNOME switcher
to this command, add this at the end of its `set_theme()` function, after its
already-matching/changed branches (the switcher provides `new_color_scheme`):

```bash
if [[ "$new_color_scheme" == "prefer-dark" ]]; then
  "$HOME/.local/bin/theme-toggle" dark
else
  "$HOME/.local/bin/theme-toggle" light
fi
```

The hook selects Latte for both GNOME `default` and `prefer-light`. It also runs
when GNOME already matches, so mismatched terminal and agent settings can catch
up. `theme-toggle auto` by itself only configures the agents; it does not watch
GNOME. For Grok to follow the desktop directly instead, select `/theme auto`;
on Linux it reads the XDG Desktop Portal appearance setting.

## Remote Control

`claude-remote-control` turns Claude Code Remote Control on or off for every
new interactive session. It sets only `remoteControlAtStartup` in
`~/.claude/settings.json` (the key `/config` calls **Enable Remote Control for
all sessions**).

```bash
claude-remote-control            # print the current value
claude-remote-control on         # new sessions auto-connect
claude-remote-control off        # new sessions do not auto-connect
claude-remote-control toggle     # flip; an unset key becomes on
claude-remote-control default    # remove the key; follow Claude / org default
```

A session that is already open keeps its current connection; start a new
`claude` to pick the change up. `off` writes an explicit `false`. A managed
`true` can still outrank that. `claude --remote-control` still turns Remote
Control on for one session.

The command lives in the `scripts` stow package (`scripts/.local/bin` →
`~/.local/bin`) and needs `jq`. It refuses to write the file when `~/.claude`
is a symlink into a git checkout.

## Agent updates

`update-agents.sh` checks Claude Code, Codex, Grok, and Gemini (`agy`). It
installs a tool only when a newer release is available, then prints what
changed and the version of each one.

```bash
update-agents.sh           # check, update what's behind, print versions
update-agents.sh --check   # report only
```

The command lives in the `scripts` stow package (`scripts/.local/bin` →
`~/.local/bin`). For Codex, it reads the release version from
`releases.openai.com` and runs `codex update` when that version is newer
than the one installed.

## Agent status lines

Claude Code, Grok, and Codex each show a custom status line. One command sets
them all up on a machine, and both bootstrap scripts run it:

```bash
./bin/setup-agent-statusline.sh           # link scripts, set config keys
./bin/setup-agent-statusline.sh --check   # report only (also run by check-health.sh)
```

| CLI | Script (stow package `agent-cli`) | Config key the command sets |
|---|---|---|
| Claude Code | `~/.claude/statusline.sh` | `~/.claude/settings.json` → `statusLine` |
| Grok | `~/.grok/statusline.sh` | `~/.grok/config.toml` → `[ui.status_line]` |
| Codex | none; built-in items | `~/.codex/config.toml` → `[tui] status_line`, `status_line_use_colors` |

Edit the scripts in `agent-cli/`; the links make every change live. To change
the Codex items or the Grok refresh interval, edit the values at the top of
`bin/setup-agent-statusline.sh` and re-run it.

`agent-cli` is stowed with `--no-folding`, so `~/.claude` and `~/.grok` stay
real directories even on a machine where they do not exist yet. Plain `stow`
would make them symlinks into this repo, and the CLIs would then write
credentials and history here. An existing script that differs from the repo
copy is moved to `~/.dotfiles-backup/<timestamp>/` first.

The configs themselves are not stow-managed, because they also hold
permissions, trusted projects, plugin state, and `theme-toggle`'s theme keys.
The command changes only the keys above, validates each file as JSON or TOML
before replacing it, and leaves a file alone when it already matches or when
the edit would not parse. Codex and Grok write their `config.toml` on first
run, so on a new machine start each once, then re-run the command.

Requirements: `stow`, `jq`, and `python3` 3.11+ (for TOML validation). The
scripts themselves need `git`, `python3`, and, for Grok, `jq`; `gh` is optional
and adds the PR number.

## Uninstall

Remove symlinks and restore backed-up configs:

```bash
cd ~/dotfiles
stow -D zsh zellij alacritty starship agent-cli
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
