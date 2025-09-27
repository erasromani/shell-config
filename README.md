# 🐚 Shell Configuration

This repository contains my personal shell configuration for **Zsh**, designed to be portable across local development and HPC environments. It uses modern tools like **Antidote**, **Starship**, and **fzf** to provide a fast, reproducible setup.

---

## 📦 Contents

- **`install_cli_tools.sh`**  
  Bootstrap script to install core CLI tools into user space:

  - [Starship](https://starship.rs) → `~/.local/bin`
  - [fzf](https://github.com/junegunn/fzf) → `~/.fzf` with binaries in `~/.fzf/bin`
  - [Antidote](https://getantidote.github.io) → `${ZDOTDIR:-$HOME}/.antidote`

  Optional flag:

  ```bash
  ./install_cli_tools.sh --write-zshrc
  ```

  Appends helpful snippets to your `~/.zshrc`.

- **`setup_dev_min.sh`**  
  Combined installer for Starship, fzf, Antidote, and the latest stable Neovim build.

  - Installs tools under `~/.local`
  - Builds Neovim from source (resolves GLIBC/FUSE issues on HPC clusters)
  - Symlinks `nvim` into `~/.local/bin`
  - Does **not** modify `.zshrc`

- **`.zshrc`**  
  Interactive shell configuration.

  - Loads plugins via Antidote
  - Enables cached completions
  - Initializes Starship prompt
  - Sources `~/.zsh_aliases` and `~/.zsh_functions`
  - Adds **history substring search** with portable terminfo bindings
  - Safely integrates iTerm2 (if present)
  - Unsets `PYTHONSTARTUP` for consistent Python REPL behavior on HPC

- **`.zshenv`**  
  Minimal environment for both interactive and non-interactive shells.

  - Ensures `$HOME/.local/bin` and `$HOME/.fzf/bin` are on `PATH`
  - Adds optional manpath entries from `~/.local/share/man`
  - Defines `$VISUAL` / `$EDITOR` (commented out by default; supports SSH vs. local choice)
  - Fixes `$TERM` for Ghostty (`xterm-ghostty` → fallback to `xterm-256color` if terminfo missing)

- **`.zsh_plugins.txt`**  
  Plugin bundle managed by Antidote:

  1. `zsh-users/zsh-completions`
  2. `changyuheng/zsh-interactive-cd`
  3. `zsh-users/zsh-history-substring-search`
  4. `zsh-users/zsh-autosuggestions`
  5. `zsh-users/zsh-syntax-highlighting` (must load last)

- **`.zsh_functions`**  
  Custom interactive utilities, with inline docblocks (`## Name: …`).

  - `zfunc_ping`: confirm file is loaded
  - `zfunchelp`: view usage docs for any function
  - `refresh-completions`: rebuild zsh completion cache

- **`.zsh_aliases`**  
  Personal aliases (currently includes `lsa="ls -la"`).

- **`config/`**  
  Configuration files for related tools: Ghostty, tmux, Starship.

---

## 🚀 Quick Start

1. Clone this repository:

   ```bash
   git clone https://github.com/yourusername/your-repo.git
   cd your-repo
   ```

2. Run the installer:

   ```bash
   ./install_cli_tools.sh --write-zshrc
   # or, for full setup including Neovim:
   ./setup_dev_min.sh
   ```

3. Restart your shell (or `source ~/.zshrc`).

---

## 🛠 Updating

- Re-run `install_cli_tools.sh` anytime to update Starship, fzf, or Antidote.
- Re-run `setup_dev_min.sh` to rebuild/update Neovim along with the CLI tools.
- Plugins can be updated with:
  ```bash
  antidote update
  ```

---

## 🧑‍💻 Notes

- **Portability:** Works across macOS and HPC clusters (e.g., NYU Big Purple).
- **Safety:** No PATH duplication, guarded bindings, and clean Python REPL (`unset PYTHONSTARTUP`).
- **Extensibility:** Add aliases in `~/.zsh_aliases` and custom functions in `~/.zsh_functions`.

---

## 📸 Demo

Starship + autosuggestions + syntax highlighting + fzf completions make for a clean, modern shell experience ✨

---
