-- ~/.config/nvim/init.lua
-----------------------------------------------------------
-- Bootstrap lazy.nvim (plugin manager)
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git","clone","--filter=blob:none",
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

  -- LSP + tooling installer
  { "williamboman/mason.nvim" },
  { "WhoIsSethDaniel/mason-tool-installer.nvim" },

  -- Autocompletion
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  -- Treesitter (syntax/AST)
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- Formatting & Linting
  { "stevearc/conform.nvim" },       -- formatting: black/isort/clang-format
  { "mfussenegger/nvim-lint" },      -- linting: mypy

  -- Optional QoL
  { "nvim-lua/plenary.nvim" },
  { "nvim-telescope/telescope.nvim", branch="0.1.x" },
})

-----------------------------------------------------------
-- Basic Options
-----------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.mouse = "a"
vim.opt.termguicolors = true
vim.opt.updatetime = 250

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
-- (Runs once on startup; if offline, open :Mason later or install manually)
-----------------------------------------------------------
require("mason").setup()
require("mason-tool-installer").setup({
  ensure_installed = {
    -- LSPs
    "pyright",
    "clangd",
    -- Formatters
    "black",
    "isort",
    "clang-format",
    -- Linters / type-checkers
    "mypy",
    "flake8",
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
  }),
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip"  },
  },
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

-----------------------------------------------------------
-- LSP (Neovim 0.11+ API)
-- Python: pyright
-- C/C++ : clangd
-----------------------------------------------------------
-- Python (pyright)
vim.lsp.config("pyright", {
  capabilities = capabilities,
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml","setup.py","setup.cfg","requirements.txt",".git" },
})
vim.lsp.enable("pyright")

-- C/C++ (clangd)
vim.lsp.config("clangd", {
  capabilities = capabilities,
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
})
vim.lsp.enable("clangd")

-----------------------------------------------------------
-- Formatting (Conform)
-- <leader>f to format; on-save for common filetypes
-----------------------------------------------------------
require("conform").setup({
  notify_on_error = false,
  format_on_save = function(bufnr)
    local ft = vim.bo[bufnr].filetype
    -- enable on-save formatting for these filetypes
    if ft == "python" or ft == "c" or ft == "cpp" then
      return { timeout_ms = 3000, lsp_fallback = true }
    end
    return nil
  end,
  formatters_by_ft = {
    -- Python: run isort first, then black
    python = { "isort", "black" },
    -- C/C++: clang-format
    c  = { "clang-format" },
    cpp = { "clang-format" },
  },
})
-- Keymap: format
vim.keymap.set({ "n", "v" }, "<leader>f", function() require("conform").format({ async = true }) end,
  { desc = "Format buffer/range" })

-----------------------------------------------------------
-- Linting / Type-check (nvim-lint) — mypy for Python
-----------------------------------------------------------
local lint = require("lint")
lint.linters_by_ft = {
  python = { "flake8", "mypy" },
}
-- If mypy is in a non-standard path, you can set:
-- lint.linters.mypy.cmd = "/path/to/mypy"
-- Run lint on save/enter
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
  callback = function() require("lint").try_lint() end,
})

-----------------------------------------------------------
-- Optional: set Python provider to a specific interpreter (conda/venv)
-- vim.g.python3_host_prog = "/path/to/your/env/bin/python"
-----------------------------------------------------------
