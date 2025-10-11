# 🐚 Shell Configuration

This repository contains my personal shell configuration for **Zsh**, designed to be portable across local development and HPC environments.  
It uses modern tools like **Antidote**, **Starship**, **fzf**, and **Neovim** to provide a fast, reproducible developer environment.

---

## 📦 Contents

- **`install_cli_tools.sh`**  
  Bootstrap script to install all core CLI tools into user space:

  - [Starship](https://starship.rs) → `~/.local/bin`
  - [fzf](https://github.com/junegunn/fzf) → `~/.fzf` with binaries in `~/.fzf/bin`
  - [Antidote](https://getantidote.github.io) → `${ZDOTDIR:-$HOME}/.antidote`
  - [Neovim (built from source)](https://github.com/neovim/neovim) → `~/.local/bin/nvim`
  - [TPM (tmux Plugin Manager)](https://github.com/tmux-plugins/tpm) → `~/.config/tmux/plugins/tpm`

  Features:

  - Installs everything under `~/.local` and `~/.config` (no sudo required)
  - Builds Neovim from source (resolves GLIBC/FUSE issues on HPC clusters)
  - Installs TPM (tmux plugin manager)
  - HPC-safe, headless, and idempotent — safe to re-run anytime

  Optional flag:

  ```bash
  ./install_cli_tools.sh --write-zshrc
  ```

  Appends helpful snippets to your `~/.zshrc`.

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
  Configuration files for related tools: Ghostty, **tmux**, **Starship**, and **Neovim**.

---

## 📝 Neovim Setup

The Neovim configuration lives under `~/.config/nvim`, designed for **HPC-safe**, **user-space**, and **portable** environments (no sudo).

### 🧩 Installation

Neovim is installed via the `install_cli_tools.sh` script:

```bash
./install_cli_tools.sh
```

This:

- Builds the latest stable Neovim from source if binaries are incompatible.
- Installs to `~/.local/` (binary at `~/.local/bin/nvim`).
- Adds Neovim to your PATH via `.zshenv`.

Verify installation:

```bash
nvim --version
```

### ⚙️ Configuration

Create a simple config at:

```bash
mkdir -p ~/.config/nvim
nvim ~/.config/nvim/init.lua
```

Example minimal config:

```lua
-- ~/.config/nvim/init.lua
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.termguicolors = true
vim.opt.mouse = "a"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins
require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, config = function()
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin")
    end
  },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "williamboman/mason.nvim" },
  { "WhoIsSethDaniel/mason-tool-installer.nvim" },
  { "stevearc/conform.nvim" },
})
```

### 🧠 Language Support

The setup supports modern LSP and linting tools that run fully in user space:

- **Python:**
  - **BasedPyright** — type checking and completions (no Node/npm required)
  - **Ruff (built-in LSP)** — linting and quick fixes (`ruff server`)
  - **Black + isort** — formatting
  - **Mypy** — type-checking (optional, via `nvim-lint`)
- **C/C++:**
  - **Clangd** (LSP)
  - **Clang-Format** (formatter)

All tools are installed automatically via Mason or manually with:

```bash
pip install --user basedpyright ruff black isort mypy
conda install -c conda-forge clang clang-tools
```

Example LSP configuration snippet:

```lua
-- Python LSPs
vim.lsp.config("basedpyright", { cmd = { "basedpyright-langserver", "--stdio" } })
vim.lsp.enable("basedpyright")

vim.lsp.config("ruff", { cmd = { "ruff", "server" } })
vim.lsp.enable("ruff")

-- C/C++ LSP
vim.lsp.config("clangd", { cmd = { "clangd" } })
vim.lsp.enable("clangd")
```

### 🎨 Theme

Neovim uses the [Catppuccin Mocha](https://github.com/catppuccin/nvim) colorscheme by default for a soft, modern aesthetic with full terminal color support.

---

## 🖥️ tmux Setup

**tmux** provides a terminal multiplexer with modern features and full integration with Neovim.

- Configuration path: `~/.config/tmux/tmux.conf`
- Plugins managed by TPM: `~/.config/tmux/plugins/tpm`
- Recommended theme: [Catppuccin Mocha](https://github.com/catppuccin/tmux)
- Clipboard integration via OSC52 (works over SSH)
- Smart pane splitting opens in the current working directory

Install plugins inside tmux with:

```
Ctrl+b Shift+I
```

---

## 🚀 Quick Start

1. Clone this repository:

   ```bash
   git clone https://github.com/erarsomani/shell-config.git
   cd shell-config
   ```

2. Run the installer:

   ```bash
   ./install_cli_tools.sh --write-zshrc
   ```

3. Restart your shell (or `source ~/.zshrc`).

---

## 🛠 Updating

- Re-run `install_cli_tools.sh` anytime to update Starship, fzf, Antidote, Neovim, or TPM.
- Update Neovim plugins:
  ```
  :Lazy sync
  ```
- Update Zsh plugins:
  ```bash
  antidote update
  ```

---

## 🧑‍💻 Notes

- **Portability:** Works across macOS, Linux, and HPC clusters.
- **Safety:** No `sudo` required; installs to `~/.local`.
- **Extensibility:** Add Neovim plugins in `~/.config/nvim/init.lua` or Zsh plugins in `.zsh_plugins.txt`.
- **Consistency:** Unified toolchain between local and HPC environments.

---

## 📸 Demo

Starship prompt + autosuggestions + syntax highlighting + fzf + Neovim + tmux (Catppuccin Mocha) =  
a cohesive, modern, and portable developer environment ✨
