# Environment / PATH
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less -FRX"

export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="$HOME/.local/share/pnpm"
export CHROME_EXECUTABLE="/usr/bin/microsoft-edge"

typeset -gU path PATH

for dir in \
  "$HOME/.local/bin" \
  "$HOME/.cargo/bin" \
  "$HOME/.local/share/pnpm" \
  "$HOME/.pulumi/bin" \
  "$HOME/.opencode/bin" \
  "$HOME/.lmstudio/bin" \
  "$HOME/.local/share/JetBrains/Toolbox/scripts" \
  "$HOME/work/flutter/bin" \
  "$HOME/go/bin" \
  "$HOME/raid/work/emsdk" \
  "$HOME/raid/work/emsdk/upstream/emscripten" \
  "$HOME/raid/work/vcpkg" \
  "$HOME/Android/Sdk/emulator" \
  "$HOME/Android/Sdk/platform-tools" \
  "/opt/nvim" \
  "/opt/homebrew/bin" \
  "/opt/homebrew/sbin" \
  "/usr/local/go/bin" \
  "/usr/local/cuda/bin" \
  "/usr/local/cuda-12.6/bin"; do
  [[ -d "$dir" ]] && path=("$dir" $path)
done

[[ -d "$HOME/Android/Sdk" ]] && export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
[[ -n "${ANDROID_SDK_ROOT:-}" ]] && export ANDROID_HOME="$ANDROID_SDK_ROOT"
[[ -d "/usr/local/cuda" ]] && export CUDA_HOME="/usr/local/cuda"
[[ -n "${CUDA_HOME:-}" ]] && export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
[[ -x "$CHROME_EXECUTABLE" ]] || unset CHROME_EXECUTABLE

export PATH

# History
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000

setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Completion (compinit)
autoload -Uz compinit
mkdir -p "$HOME/.cache/zsh"
compinit -d "$HOME/.cache/zsh/zcompdump-$HOST-$ZSH_VERSION"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Keybindings
bindkey -e

autoload -Uz select-word-style up-line-or-beginning-search down-line-or-beginning-search
select-word-style shell
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

[[ -n "${terminfo[kcuu1]-}" ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
[[ -n "${terminfo[kcud1]-}" ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

[[ -n "${terminfo[khome]-}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[OH' beginning-of-line

[[ -n "${terminfo[kend]-}" ]] && bindkey "${terminfo[kend]}" end-of-line
bindkey '^[[F' end-of-line
bindkey '^[OF' end-of-line

[[ -n "${terminfo[kdch1]-}" ]] && bindkey "${terminfo[kdch1]}" delete-char
bindkey '^[[3~' delete-char

bindkey '^[[D' backward-char
bindkey '^[OD' backward-char
bindkey '^[[C' forward-char
bindkey '^[OC' forward-char

bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[5D' backward-word
bindkey '^[[5C' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word

# Aliases
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'

if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
fi

if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

# Helper functions
source_first_existing() {
  local candidate
  for candidate in "$@"; do
    if [[ -r "$candidate" ]]; then
      source "$candidate"
      return 0
    fi
  done
  return 1
}

# Tool init
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
fi

if [[ -s "$NVM_DIR/bash_completion" ]]; then
  source "$NVM_DIR/bash_completion"
fi

if [[ -r /etc/zsh_command_not_found ]]; then
  source /etc/zsh_command_not_found
fi

# Plugin sourcing
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

source_first_existing \
  "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

source_first_existing \
  "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Prompt
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  PROMPT='%~ %# '
fi
