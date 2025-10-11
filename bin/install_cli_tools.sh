#!/usr/bin/env bash
# setup_dev_min.sh — Starship, fzf, Antidote, latest-stable Neovim (build from source), and TPM.
# No .zshrc edits. Safe to re-run.
set -euo pipefail

PREFIX="${HOME}/.local"
BIN_DIR="${PREFIX}/bin"
FZF_DIR="${HOME}/.fzf"
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"

# Tmux (XDG) locations
TMUX_XDG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
TMUX_PLUGINS_DIR="${TMUX_XDG_DIR}/plugins"
TPM_DIR="${TMUX_PLUGINS_DIR}/tpm"

mkdir -p "$BIN_DIR"

log()  { printf "\033[1;34m[setup]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m  %s\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
nproc_compat() { command -v nproc >/dev/null && nproc || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2; }

# --- Starship ---
install_starship() {
  if have starship; then
    log "starship already present: $(starship --version)"
    return
  fi
  if have curl; then
    log "Installing starship to $BIN_DIR ..."
    curl -fsSL https://starship.rs/install.sh | bash -s -- -y -b "$BIN_DIR"
    log "starship installed."
  else
    warn "curl not found; skipping starship."
  fi
}

# --- fzf ---
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
  if ! have git; then warn "git not found; cannot install fzf."; return; fi
  log "Installing fzf to $FZF_DIR ..."
  git clone --depth 1 https://github.com/junegunn/fzf "$FZF_DIR" || true
  "$FZF_DIR/install" --bin --no-update-rc || true
  log "fzf installed."
}

# --- Antidote ---
install_antidote() {
  if [[ -d "$ANTIDOTE_DIR/.git" ]]; then
    if have git; then
      log "Updating Antidote ..."
      git -C "$ANTIDOTE_DIR" pull --ff-only || warn "Antidote update skipped."
      log "Antidote updated."
    fi
    return
  fi
  if ! have git; then warn "git not found; cannot install Antidote."; return; fi
  log "Installing Antidote to $ANTIDOTE_DIR ..."
  git clone --depth=1 https://github.com/mattmc3/antidote "$ANTIDOTE_DIR"
  log "Antidote installed."
}

# --- TPM (Tmux Plugin Manager) ---
install_tpm() {
  if ! have git; then
    warn "git not found; cannot install TPM."
    return
  fi
  mkdir -p "$TMUX_PLUGINS_DIR"
  if [[ -d "$TPM_DIR/.git" ]]; then
    log "Updating TPM in $TPM_DIR ..."
    git -C "$TPM_DIR" pull --ff-only || warn "TPM update skipped."
  else
    log "Installing TPM to $TPM_DIR ..."
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  fi
  log "TPM ready."

  # Gentle reminder if tmux.conf exists but lacks the init line
  local TMUX_CONF="${TMUX_XDG_DIR}/tmux.conf"
  if [[ -f "$TMUX_CONF" ]] && ! grep -q "plugins/tpm/tpm" "$TMUX_CONF"; then
    warn "Add this to the END of $TMUX_CONF:"
    printf "    run '%s/tpm'\n" "$TPM_DIR"
  fi
}

# --- Neovim (build latest stable from source) ---
maybe_load_modules() {
  # Load if available; ignore if not (HPC-friendly)
  module load cmake >/dev/null 2>&1 || true
  module load gcc   >/dev/null 2>&1 || true
  module load ninja >/dev/null 2>&1 || true
}
check_build_tools() {
  command -v git   >/dev/null || { echo "git not found."; exit 1; }
  command -v curl  >/dev/null || true # not strictly required for build
  command -v cmake >/dev/null || { echo "cmake not found (try: module load cmake)"; exit 1; }
  command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 || { echo "C compiler not found (try: module load gcc)"; exit 1; }
}
resolve_latest_tag() {
  curl -fsSI https://github.com/neovim/neovim/releases/latest \
    | tr -d '\r' | awk -F'/tag/' '/^location: /{print $2}'
}
build_nvim() {
  maybe_load_modules
  check_build_tools
  local TAG SRC PREFIX_NVIM
  TAG=$(resolve_latest_tag); : "${TAG:?Failed to resolve latest tag}"
  log "Latest Neovim tag: $TAG"
  SRC="$HOME/.local/src/neovim"
  PREFIX_NVIM="$PREFIX/neovim"
  rm -rf "$SRC"
  git clone --depth=1 --branch "$TAG" https://github.com/neovim/neovim.git "$SRC"
  cd "$SRC"
  make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$PREFIX_NVIM" -j"$(nproc_compat)"
  make install
  mkdir -p "$BIN_DIR"
  ln -sf "$PREFIX_NVIM/bin/nvim" "$BIN_DIR/nvim"
  log "Neovim $TAG installed → $PREFIX_NVIM (linked at $BIN_DIR/nvim)"
}

# --- Run ---
log "Prefix: $PREFIX"
install_starship
install_fzf
install_antidote
install_tpm
build_nvim

cat <<'DONE'

✅ Done.

Next steps for tmux plugins:
1) Put your config in: ~/.config/tmux/tmux.conf
   Make sure the LAST line is:
     run '~/.config/tmux/plugins/tpm/tpm'

2) Start tmux, then press:  Ctrl+b  Shift+I  (to install plugins)

Tips:
- For Catppuccin Mocha, add to your tmux.conf:
    set -g @plugin 'catppuccin/tmux'
    set -g @catppuccin_flavour 'mocha'
- For remote→local clipboard, include:
    set -g set-clipboard on
    set -as terminal-overrides ',*:Ms=\E]52;c;%p1%s\007'

Re-run this script anytime; it updates installed tools without touching your shell rc files.
DONE
