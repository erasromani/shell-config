# ── Antidote plugin manager ────────────────────────────────────────────────────
if [ -r "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]; then
  source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
fi

# ── Completion ─────────────────────────────────────────────────────────────────
autoload -Uz compinit
compinit -i -C   # prime cache for builtins
# Load plugins (reads ~/.zsh_plugins.txt by default)
if typeset -f antidote >/dev/null 2>&1; then
  antidote load
fi
compinit -i -C   # refresh completions contributed by plugins

# ── Prompt (Starship) ──────────────────────────────────────────────────────────
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ── fzf extras (keybindings/completion) if installed ───────────────────────────
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# ── Personal aliases ───────────────────────────────────────────────────────────
[ -f "$HOME/.zsh_aliases" ] && source "$HOME/.zsh_aliases"

# ── History-substring-search keybinds ──────────────────────────────────────────
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
