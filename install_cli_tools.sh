#!/usr/bin/env bash
set -euo pipefail

# Install Starship, fzf, and Antidote in user space.
# - Starship -> ~/.local/bin
# - fzf      -> ~/.fzf (with binaries in ~/.fzf/bin)
# - Antidote -> ${ZDOTDIR:-$HOME}/.antidote
#
# Optional: pass --write-zshrc to append helpful lines to your ~/.zshrc.

PREFIX="${HOME}/.local"
BIN_DIR="${PREFIX}/bin"
FZF_DIR="${HOME}/.fzf"
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

mkdir -p "$BIN_DIR"

log() { printf "\033[1;34m[install]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

install_starship() {
  if have starship; then
    log "starship already present: $(starship --version)"
    return
  fi
  if have curl; then
    log "Installing starship to $BIN_DIR ..."
    # Official installer: https://starship.rs
    curl -fsSL https://starship.rs/install.sh | bash -s -- -y -b "$BIN_DIR"
    log "starship installed."
  else
    warn "curl not found; skipping starship install."
  fi
}

install_fzf() {
  if [[ -x "$FZF_DIR/bin/fzf" ]]; then
    log "fzf already present: $("$FZF_DIR/bin/fzf" --version | head -n1)"
    if [[ -d "$FZF_DIR/.git" ]] && have git; then
      log "Updating fzf ..."
      git -C "$FZF_DIR" pull --ff-only || warn "fzf update skipped."
      "$FZF_DIR/install" --bin --no-update-rc || true
    fi
    return
  fi
  if ! have git; then
    warn "git not found; cannot install fzf."
    return
  fi
  log "Installing fzf to $FZF_DIR ..."
  git clone --depth 1 https://github.com/junegunn/fzf "$FZF_DIR" || true
  "$FZF_DIR/install" --bin --no-update-rc || true
  log "fzf installed."
}

install_antidote() {
  if [[ -d "$ANTIDOTE_DIR/.git" ]]; then
    if have git; then
      log "Updating Antidote ..."
      git -C "$ANTIDOTE_DIR" pull --ff-only
      log "Antidote updated."
    fi
    return
  fi
  if ! have git; then
    warn "git not found; cannot install Antidote."
    return
  fi
  log "Installing Antidote to $ANTIDOTE_DIR ..."
  git clone --depth=1 https://github.com/mattmc3/antidote "$ANTIDOTE_DIR"
  log "Antidote installed."
}

ensure_zshrc_snippets() {
  [[ -f "$ZSHRC" ]] || touch "$ZSHRC"

  add_line() {
    local line="$1"
    grep -Fqx "$line" "$ZSHRC" 2>/dev/null || { printf '%s\n' "$line" >> "$ZSHRC"; log "Appended to $ZSHRC: $line"; }
  }

  # Ensure ~/.local/bin and ~/.fzf/bin are on PATH (idempotent prepend)
  add_line 'for d in "$HOME/.local/bin" "$HOME/.fzf/bin"; do [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac; done'

  # Starship init (only if available)
  if have starship; then
    add_line 'command -v starship >/dev/null && eval "$(starship init zsh)"'
  fi

  # fzf keybindings/completion (only if installer created it)
  if [[ -f "$HOME/.fzf.zsh" ]]; then
    add_line '[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"'
  fi
}

main() {
  log "Installing to: $BIN_DIR"
  install_starship
  install_fzf
  install_antidote
  log "All done."

  cat <<'INFO'

Next steps:
- Open a new shell, or run:  source ~/.zshrc
- If starship isn't detected, ensure ~/.local/bin is on your PATH.

Tip: re-run this script anytime; it safely updates what’s already installed.
INFO
}

if [[ "${1:-}" == "--write-zshrc" ]]; then
  main
  ensure_zshrc_snippets
else
  main
fi
