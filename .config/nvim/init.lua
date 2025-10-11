-- ~/.config/nvim/init.lua
-- =====================================================================
--  Neovim best‑practice config for Python/C/C++ on HPC (no Node needed)
--  - Plugin manager: lazy.nvim
--  - LSP: BasedPyright (types), Ruff (lint/fixes), clangd
--  - Format: black/isort, clang-format via conform.nvim
--  - Type check: mypy via nvim-lint
--  - UI/UX: Catppuccin, Telescope, Treesitter, sane defaults
--  - Sidebar: <leader>e opens NetRW (built-in) or nvim-tree if installed
--  - Compatible with nvim 0.11+ (new LSP API) and gracefully falls back to lspconfig
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
-- Plugins
-----------------------------------------------------------
require("lazy").setup({
  -- Theme
  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },

  -- LSP + tooling
  { "williamboman/mason.nvim" },
  { "WhoIsSethDaniel/mason-tool-installer.nvim" },
  { "neovim/nvim-lspconfig" }, -- used as a fallback on nvim < 0.11

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
vim.g.mapleader = " "           -- Space as leader
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.mouse = "a"
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.completeopt = { "menu", "menuone", "noselect" }

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
-- nvim-cmp (completion)
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
-- LSP setup
--  - Uses new API on nvim >= 0.11
--  - Falls back to lspconfig on older versions
-----------------------------------------------------------
local is_nvim_011 = vim.fn.has("nvim-0.11") == 1

if is_nvim_011 and vim.lsp and vim.lsp.config then
  -- New Neovim 0.11+ API
  -- BasedPyright (Python typing)
  vim.lsp.config("basedpyright", {
    capabilities = capabilities,
    cmd = { "basedpyright-langserver", "--stdio" },
  })
  vim.lsp.enable("basedpyright")

  -- Ruff (Python lint/fixes) – avoid overlap with Pyright hovers/signatures
  vim.lsp.config("ruff", {
    capabilities = capabilities,
    cmd = { "ruff", "server" },
    init_options = {
      settings = {
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

  -- clangd (C/C++)
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
  })
  lspconfig.ruff.setup({
    capabilities = capabilities,
    cmd = { "ruff", "server" },
    init_options = {
      settings = {
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
-- Formatting (Conform): <leader>f and on-save for common filetypes
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
})
vim.keymap.set({ "n", "v" }, "<leader>f", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer/range" })

-----------------------------------------------------------
-- Linting / Type-check (nvim-lint) — mypy for Python
-----------------------------------------------------------
local lint = require("lint")
lint.linters_by_ft = { python = { "mypy" } }
-- If mypy is in a non-standard path, set: lint.linters.mypy.cmd = vim.fn.expand("~/.local/bin/mypy")
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  callback = function() require("lint").try_lint() end,
})

-----------------------------------------------------------
-- Sidebar / File Navigation
-- <leader>e opens NetRW on the LEFT (best practice); if nvim-tree is installed, toggle that
-----------------------------------------------------------
-- NetRW defaults (lightweight, built-in)
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

-- Optional: minimal nvim-tree setup (only if installed)
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
-- Open a terminal in a horizontal split at the bottom
vim.keymap.set("n", "<leader>t", ":belowright split | terminal<CR>", { desc = "Open terminal at bottom", silent = true })
-- Tip: in terminal, use <C-\\><C-n> to return to Normal mode

-- Allow Esc to exit terminal mode
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
-- Python provider (optional): point to a specific interpreter
-- vim.g.python3_host_prog = "/path/to/conda/envs/neovim/bin/python"
-----------------------------------------------------------
