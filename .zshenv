# ── PATH setup (idempotent; used by interactive + non-interactive) ────────────
for d in "$HOME/.local/bin" "$HOME/.fzf/bin"; do
  [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done
export PATH

# ── MANPATH (optional; keep system defaults) ──────────────────────────────────
# Leading/trailing empty entry (the ":") tells man to include system defaults.
if [ -d "$HOME/.local/share/man" ]; then
  case ":${MANPATH:-:}:" in
    *":$HOME/.local/share/man:"*) ;;  # already present
    *) export MANPATH="$HOME/.local/share/man:${MANPATH:-:}" ;;
  esac
fi

# ── Editors ──────────────────────────────────────────────────────────────────
# if [[ -n $SSH_CONNECTION ]]; then
#   export VISUAL='vim'
#   export EDITOR='vim'
# else
#   export VISUAL='nvim'
#   export EDITOR='nvim'
# fi

# ── Ghostty TERM fix (applies everywhere, including scripts) ───────────────────
if [[ "$TERM" == "xterm-ghostty" ]]; then
  if command -v infocmp >/dev/null 2>&1 && infocmp xterm-ghostty >/dev/null 2>&1; then
    :  # keep TERM as-is
  else
    export TERM="xterm-256color"
  fi
fi
