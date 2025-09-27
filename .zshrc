# ── Paths (user-space bins; idempotent appends) ────────────────────────────────
for d in "$HOME/.local/bin" "$HOME/.fzf/bin"; do
  [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done

# ── Antidote plugin manager ───────────────────────────────────────────────────
source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"

autoload -Uz compinit
compinit -i -C   # cached completion

antidote load
compinit -i -C   # refresh completions from plugins

# ── Prompt (Starship) ─────────────────────────────────────────────────────────
command -v starship >/dev/null && eval "$(starship init zsh)"

# ── fzf extras (keybindings/completion) if installed ──────────────────────────
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# ── Personal aliases ──────────────────────────────────────────────────────────
[ -f "$HOME/.zsh_aliases" ] && source "$HOME/.zsh_aliases"

# ── History-substring-search keybinds ─────────────────────────────────────────
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ── Miscellaneous ────────────────────────────────────────────────────────────
# Fix Ghostty TERM issue (fallback to xterm-256color)
if [[ "$TERM" == "xterm-ghostty" ]]; then
  if command -v infocmp >/dev/null 2>&1 && infocmp xterm-ghostty >/dev/null 2>&1; then
    :  # ok, keep TERM as-is
  else
    export TERM="xterm-256color"
  fi
fi