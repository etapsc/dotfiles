# Architectural Decision Log - dotfiles

<!-- Append decisions in reverse chronological order -->
<!-- Format: YYYY-MM-DD: [Decision] - [Rationale] -->

2026-07-21: Project-specific Zellij layouts use six role-specific tabs (`claude`, `codex`, `grok`, `code`, `tools`, and `shell`) - Dedicated single-pane agent shells keep each assistant context separate without forcing CLI startup; `code` launches Neovim, while `tools` and `shell` retain two panes for parallel terminal work.

2026-07-04: Catppuccin theme switching is a manual `theme-toggle` command, not OS-appearance- or schedule-driven - User explicitly does not want the terminal to follow macOS light/dark mode; a single command flipping both Alacritty and Zellij (live config reload) covers the need with zero daemons.

2026-07-04: User-facing commands ship via a `scripts` stow package (`scripts/.local/bin` -> `~/.local/bin`) - Keeps repo tooling (`bin/`) separate from installed commands; `~/.local/bin` is already first on PATH and both bootstrap scripts stow the package.

2026-07-04: No custom font-size tooling - Alacritty's built-in Cmd+= / Cmd+- / Cmd+0 bindings suffice; Zellij renders no text of its own, so terminal font size covers everything.
