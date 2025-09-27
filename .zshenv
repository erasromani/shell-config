# ── Path setup (idempotent; used by interactive + non-interactive) ─────────────
for d in "$HOME/.local/bin" "$HOME/.fzf/bin"; do
  [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done
export PATH

# ── Ghostty TERM fix (applies everywhere, including scripts) ───────────────────
if [[ "$TERM" == "xterm-ghostty" ]]; then
  if command -v infocmp >/dev/null 2>&1 && infocmp xterm-ghostty >/dev/null 2>&1; then
    :  # keep TERM as-is
  else
    export TERM="xterm-256color"
  fi
fi
