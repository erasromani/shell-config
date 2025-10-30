-- ~/.config/nvim/init.lua
-- =====================================================================
--  Neovim best‑practice config (HPC‑friendly, no Node required)
--  • Dynamic Python venv detection (VIRTUAL_ENV, Conda, .venv/venv)
--  • LSP: BasedPyright (typing), Ruff LSP (lint/fix), clangd
--  • Format: black/isort, clang-format via conform.nvim (uses venv)
--  • Type check: mypy via nvim-lint (runs `python -m mypy` in venv)
--  • UI/UX: Catppuccin, Telescope, Treesitter, sane defaults
--  • Works on nvim 0.11+ (new LSP API) and falls back to lspconfig
-- =====================================================================

-----------------------------------------------------------
-- Bootstrap lazy.nvim (plugin manager)
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-----------------------------------------------------------
-- Plugins (minimal, HPC‑friendly; no Node needed)
-----------------------------------------------------------
require("lazy").setup({
  -- Theme
  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },

  -- LSP + tooling
  { "williamboman/mason.nvim" },
  { "WhoIsSethDaniel/mason-tool-installer.nvim" },
  { "neovim/nvim-lspconfig" }, -- fallback on nvim < 0.11

  -- Completion
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  -- Treesitter (syntax/AST)
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- Formatting & Linting
  { "stevearc/conform.nvim" },  -- black/isort/clang-format
  { "mfussenegger/nvim-lint" }, -- mypy (types)

  -- Fuzzy finding / utils
  { "nvim-lua/plenary.nvim" },
  { "nvim-telescope/telescope.nvim", branch = "0.1.x" },

  -- OPTIONAL: modern file tree (used only if installed)
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
})

-----------------------------------------------------------
-- Basic Options (UX defaults)
-----------------------------------------------------------
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.mouse = "a"
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Global indentation defaults (applies to most files)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Theme: Catppuccin Mocha
require("catppuccin").setup({ flavour = "mocha" })
vim.cmd.colorscheme("catppuccin")

-----------------------------------------------------------
-- Treesitter
-----------------------------------------------------------
require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "python", "c", "cpp", "bash", "json", "markdown" },
  highlight = { enable = true },
  indent = { enable = true },
})

-----------------------------------------------------------
-- Mason + auto-install external tools
-----------------------------------------------------------
require("mason").setup()
require("mason-tool-installer").setup({
  ensure_installed = {
    -- LSP servers (no Node required)
    "basedpyright",
    "ruff",     -- Ruff LSP (ruff server)
    "clangd",
    -- Formatters
    "black",
    "isort",
    "clang-format",
    -- Linters / type-checkers
    "mypy",
  },
  run_on_start = true,
  auto_update = false,
})

-----------------------------------------------------------
-- Python venv auto-detect (VIRTUAL_ENV, Conda, .venv, venv)
-----------------------------------------------------------
local function detect_python()
  local uv = vim.loop
  local env = vim.env
  local candidates = {}

  -- 1) Activated venv (virtualenv/uv/poetry) via $VIRTUAL_ENV
  if env.VIRTUAL_ENV and env.VIRTUAL_ENV ~= "" then
    table.insert(candidates, env.VIRTUAL_ENV)
  end

  -- 2) Activated Conda env (not base)
  if env.CONDA_PREFIX and env.CONDA_PREFIX ~= "" then
    table.insert(candidates, env.CONDA_PREFIX)
  end

  -- 3) Project-local .venv/ or venv/ near root
  local root_markers = { ".git", "pyproject.toml", "setup.cfg", "setup.py", "requirements.txt" }
  local root = vim.fs.root(0, root_markers) or uv.cwd()
  for _, name in ipairs({ ".venv", "venv", ".conda" }) do
    local p = root .. "/" .. name
    local st = uv.fs_stat(p)
    if st and st.type == "directory" then
      table.insert(candidates, p)
    end
  end

  for _, venv in ipairs(candidates) do
    local py = venv .. "/bin/python"
    if uv.fs_stat(py) then
      return venv, py
    end
  end

  -- Fallback to whatever "python3" or "python" resolves to
  local exepath = vim.fn.exepath("python3")
  if exepath == "" then exepath = vim.fn.exepath("python") end
  return nil, exepath
end

-- Resolve once on startup
local VENV_PATH, PYTHON_BIN = detect_python()

-- Make Neovim's own Python host use the same interpreter (for pynvim plugins)
if PYTHON_BIN and PYTHON_BIN ~= "" then
  vim.g.python3_host_prog = PYTHON_BIN
end

-----------------------------------------------------------
-- Completion (nvim-cmp)
-----------------------------------------------------------
local cmp = require("cmp")
local luasnip = require("luasnip")
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
    ["<C-n>"]     = cmp.mapping.select_next_item(cmp_select),
    ["<C-p>"]     = cmp.mapping.select_prev_item(cmp_select),
    ["<C-e>"]     = cmp.mapping.abort(),
  }),
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip"  },
  },
})
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-----------------------------------------------------------
-- Diagnostics UX
-----------------------------------------------------------
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  float = { border = "rounded", source = "if_many" },
  severity_sort = true,
})

-----------------------------------------------------------
-- LSP setup (dynamic Python/venv)
-----------------------------------------------------------
local is_nvim_011 = vim.fn.has("nvim-0.11") == 1

-- Helper to produce Pyright/BasedPyright settings from detected venv
local function py_settings_from_venv(venv_path)
  if not venv_path or venv_path == "" then
    return {} -- let server try its own detection
  end
  local venv_dir  = vim.fn.fnamemodify(venv_path, ":h") -- parent folder
  local venv_name = vim.fn.fnamemodify(venv_path, ":t") -- leaf name (.venv)
  return { python = { venvPath = venv_dir, venv = venv_name } }
end

local bp_settings = py_settings_from_venv(VENV_PATH)

if is_nvim_011 and vim.lsp and vim.lsp.config then
  -- Neovim 0.11+ API
  vim.lsp.config("basedpyright", {
    capabilities = capabilities,
    cmd = { "basedpyright-langserver", "--stdio" },
    settings = bp_settings,
    on_init = function(client)
      client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, {
        python = { pythonPath = PYTHON_BIN },
      })
    end,
  })
  vim.lsp.enable("basedpyright")

  vim.lsp.config("ruff", {
    capabilities = capabilities,
    cmd = { "ruff", "server" },
    init_options = {
      settings = {
        interpreter = PYTHON_BIN,
        hover = { enable = false },
        signatureHelp = { enable = false },
        codeAction = {
          disableRuleComment = { enable = true },
          fix = { enable = true },
        },
      },
    },
  })
  vim.lsp.enable("ruff")

  vim.lsp.config("clangd", {
    capabilities = capabilities,
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
  })
  vim.lsp.enable("clangd")
else
  -- Fallback for Neovim < 0.11
  local lspconfig = require("lspconfig")
  lspconfig.basedpyright.setup({
    capabilities = capabilities,
    cmd = { "basedpyright-langserver", "--stdio" },
    settings = bp_settings,
    on_init = function(client)
      client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, {
        python = { pythonPath = PYTHON_BIN },
      })
    end,
  })

  lspconfig.ruff.setup({
    capabilities = capabilities,
    cmd = { "ruff", "server" },
    init_options = {
      settings = {
        interpreter = PYTHON_BIN,
        hover = { enable = false },
        signatureHelp = { enable = false },
        codeAction = {
          disableRuleComment = { enable = true },
          fix = { enable = true },
        },
      },
    },
  })

  lspconfig.clangd.setup({ capabilities = capabilities })
end

-----------------------------------------------------------
-- Formatting (Conform): on-save for common filetypes
-- Force using tools from the detected Python via `python -m`
-----------------------------------------------------------
require("conform").setup({
  notify_on_error = false,
  format_on_save = function(bufnr)
    local ft = vim.bo[bufnr].filetype
    if ft == "python" or ft == "c" or ft == "cpp" then
      return { timeout_ms = 3000, lsp_fallback = true }
    end
    return nil
  end,
  formatters_by_ft = {
    python = { "isort", "black" },
    c      = { "clang-format" },
    cpp    = { "clang-format" },
  },
  formatters = {
    black = {
      command = PYTHON_BIN,
      args = { "-m", "black", "--quiet", "-" },
      stdin = true,
    },
    isort = {
      command = PYTHON_BIN,
      args = { "-m", "isort", "--stdout", "-" },
      stdin = true,
    },
  },
})
vim.keymap.set({ "n", "v" }, "<leader>f", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer/range" })

-----------------------------------------------------------
-- Linting / Type-check (nvim-lint) — mypy with venv python
-----------------------------------------------------------
local lint = require("lint")
lint.linters_by_ft = { python = { "mypy" } }

-- Run mypy as a module inside the selected interpreter
lint.linters.mypy = vim.tbl_deep_extend("force", lint.linters.mypy or {}, {
  cmd = PYTHON_BIN,
  args = {
    "-m", "mypy",
    "--show-column-numbers",
    "--ignore-missing-imports",
    "--pretty",
    "--no-error-summary",
  },
  stdin = false,
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  callback = function() require("lint").try_lint() end,
})

-----------------------------------------------------------
-- Sidebar / File Navigation
-- <leader>e opens NetRW on the LEFT; if nvim-tree installed, toggle it
-----------------------------------------------------------
vim.g.netrw_banner = 0
vim.g.netrw_browse_split = 0
vim.g.netrw_winsize = 25

local function plugin_loaded(name)
  return package.loaded[name] ~= nil or pcall(require, name)
end

vim.keymap.set("n", "<leader>e", function()
  if plugin_loaded("nvim-tree") then
    require("nvim-tree") -- ensure loaded
    vim.cmd("NvimTreeToggle")
  else
    vim.cmd("Lexplore")
  end
end, { desc = "Toggle sidebar (nvim-tree or NetRW)", silent = true })

if plugin_loaded("nvim-tree") then
  require("nvim-tree").setup({
    view = { side = "left", width = 30 },
    sync_root_with_cwd = true,
    respect_buf_cwd = true,
    update_focused_file = { enable = true, update_root = false },
    renderer = { group_empty = true },
    actions = { open_file = { quit_on_open = false } },
    filters = { dotfiles = false },
  })
end

-----------------------------------------------------------
-- Terminal (bottom split)
-----------------------------------------------------------
vim.keymap.set("n", "<leader>t", ":belowright split | terminal<CR>", { desc = "Open terminal at bottom", silent = true })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true, desc = "Exit terminal mode" })

-----------------------------------------------------------
-- Telescope basics
-----------------------------------------------------------
local ok_telescope, telescope = pcall(require, "telescope")
if ok_telescope then
  telescope.setup({})
  vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
  vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>",  { desc = "Live grep" })
  vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>",    { desc = "Buffers" })
  vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>",  { desc = "Help" })
end

-----------------------------------------------------------
-- Utility: Manual venv re-detect & restart Python LSPs (no autocmd)
-----------------------------------------------------------
local function restart_python_lsps()
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  for _, c in ipairs(clients) do
    if c.name == "basedpyright" or c.name == "ruff" then
      c.stop(true)
    end
  end
  -- Delay slightly to avoid race with shutdown
  vim.defer_fn(function()
    if is_nvim_011 and vim.lsp and vim.lsp.enable then
      pcall(vim.lsp.enable, "basedpyright")
      pcall(vim.lsp.enable, "ruff")
    else
      local lspconfig = require("lspconfig")
      pcall(lspconfig.basedpyright.manager.try_add)
      pcall(lspconfig.ruff.manager.try_add)
    end
  end, 100)
end

-- Manual command: run this if you change projects mid-session
vim.api.nvim_create_user_command("PyVenvDetect", function()
  local old_venv, old_py = VENV_PATH, PYTHON_BIN
  VENV_PATH, PYTHON_BIN = detect_python()
  if PYTHON_BIN and PYTHON_BIN ~= "" then
    vim.g.python3_host_prog = PYTHON_BIN
  end
  vim.notify(("Detected python: %s\nvenv: %s"):format(PYTHON_BIN or "<none>", VENV_PATH or "<none>"), vim.log.levels.INFO)
  if PYTHON_BIN ~= old_py then
    restart_python_lsps()
  end
end, { desc = "Detect Python venv and restart Python LSPs" })

-----------------------------------------------------------
-- Filetype-specific indentation
-----------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "cuda" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "make" },
  callback = function()
    vim.opt_local.expandtab = false  -- use literal tabs
    vim.opt_local.tabstop = 8        -- display width of a tab
    vim.opt_local.shiftwidth = 8     -- match visual width
  end,
})
