# arch-null zsh config

# ── History ───────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# ── Completion ────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ── Plugins ───────────────────────────────────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# ── Aliases ───────────────────────────────────────────────
alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza -la --tree --level=2 --icons'
alias cat='bat --plain'
alias grep='rg'
alias find='fd'
alias cd='z'

alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph -20'
alias gp='git push'

alias pac='sudo pacman -S'
alias pacs='pacman -Ss'
alias pacr='sudo pacman -Rns'
alias pacu='sudo pacman -Syu'

# ── Tools ─────────────────────────────────────────────────
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh) 2>/dev/null

# ── Key bindings ──────────────────────────────────────────
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
