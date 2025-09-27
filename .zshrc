# ── Antidote plugin manager ────────────────────────────────────────────────────
# (Make sure you have ~/.zsh_plugins.txt; Antidote will read it by default.)
if [ -r "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]; then
  source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
  # Load plugins now so fpath is set BEFORE we initialize completion
  antidote load
fi

# ── Completions: one-call, cached, secure-ish ─────────────────────────────────
# Use an XDG cache location and avoid noisy insecure-dir warnings on HPC
autoload -Uz compinit
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zstyle ':completion:*' rehash true
compinit -i -C -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

# ── Prompt (Starship) ─────────────────────────────────────────────────────────
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ── fzf extras (keybindings/completion) if installed ──────────────────────────
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# ── Aliases / Functions split files ───────────────────────────────────────────
[ -f "$HOME/.zsh_aliases" ]   && source "$HOME/.zsh_aliases"
[ -f "$HOME/.zsh_functions" ] && source "$HOME/.zsh_functions"

# ── History-substring-search keybinds (guarded) ───────────────────────────────
if (( $+functions[history-substring-search-up] )); then
  # use terminfo so it works across Ghostty/iTerm/tmux
  bindkey "${terminfo[kcuu1]}" history-substring-search-up
  bindkey "${terminfo[kcud1]}" history-substring-search-down
fi

# ── Optional: iTerm2 integration (safe no-op elsewhere) ───────────────────────
[ -f "${HOME}/.iterm2_shell_integration.zsh" ] && source "${HOME}/.iterm2_shell_integration.zsh"

# ── Misc ─────────────────────────────────────────────────────────────────────
unset PYTHONSTARTUP 2>/dev/null
