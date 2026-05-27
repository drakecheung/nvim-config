local ok1, _ = pcall(require, "lspconfig")
if not ok1 then return end

local ok2, mason = pcall(require, "mason")
if not ok2 then return end

local ok3, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not ok3 then return end

local ok4, null_ls = pcall(require, "null-ls")
if not ok4 then return end

local ok5, masonlsp = pcall(require, "mason-lspconfig")
if not ok5 then return end

-- =============================================================================
--  MASON: install LSP binaries (not configure them — that's vim.lsp.config's job)
-- =============================================================================
mason.setup()
masonlsp.setup {
  ensure_installed = { "eslint", "bashls", "pyright", "ruff" },
  -- NOTE: we do NOT use the `handlers` pattern here.
  -- Server configuration is done via vim.lsp.config() + vim.lsp.enable() below.
  -- Mason only manages binary installation.
}

-- =============================================================================
--  LSP CONFIGURATION (Neovim 0.11+ native API)
-- =============================================================================
-- Why vim.lsp.config instead of lspconfig.setup?
--   - Declarative: config and enable are separate concerns
--   - No need for mason-lspconfig handlers to bridge the gap
--   - LspAttach autocmd replaces per-server on_attach callbacks

-- 1. Capabilities (required for nvim-cmp autocompletion)
local capabilities = cmp_nvim_lsp.default_capabilities()

-- 2. Global LspAttach: runs once per buffer when ANY LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local bufnr = ev.buf
    local opts = { buffer = bufnr, silent = true }

    -- Shared keymaps (work for all LSP servers)
    vim.keymap.set("n", "<c-h>", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "<c-l>", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<c-m-]>", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<c-]>", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

    -- Per-server adjustments (replaces per-server on_attach)
    if client and client.name == "ruff" then
      -- Disable ruff's built-in formatting (we use null-ls for that)
      client.server_capabilities.documentFormattingProvider = false
    end
  end,
})

-- 3. Configure & Enable Standard Servers
local servers = { "eslint", "bashls", "pyright" }

for _, server in ipairs(servers) do
  vim.lsp.config(server, {
    capabilities = capabilities,
  })
  vim.lsp.enable(server)
end

-- 4. Configure & Enable Ruff
vim.lsp.config("ruff", {
  capabilities = capabilities,
  -- NOTE: no on_attach here — use LspAttach autocmd above instead
})
vim.lsp.enable("ruff")

-- =============================================================================
--  DIAGNOSTICS & UI
-- =============================================================================

local signs = {
  { name = "DiagnosticSignError", text = "" },
  { name = "DiagnosticSignWarn", text = "" },
  { name = "DiagnosticSignHint", text = "" },
  { name = "DiagnosticSignInfo", text = "" },
}

for _, sign in ipairs(signs) do
  vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
end

vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- Toggle LSP Functions
local lsp_is_on = true

_G.turn_off_lsp = function()
  lsp_is_on = false
  vim.diagnostic.config {
    virtual_text = false,
    signs = false,
    underline = false,
  }
end

_G.turn_on_lsp = function()
  lsp_is_on = true
  vim.diagnostic.config({
    virtual_text = {
      source = "always",
      prefix = '▎',
    },
    signs = {
      active = signs,
    },
    underline = true,
  })
end

_G.toggle_lsp = function()
  if lsp_is_on then
    _G.turn_off_lsp()
  else
_G.LspListServers = function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    print("No active LSP servers for this buffer.")
    return
  end
  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  print("Active LSP servers: " .. table.concat(names, ", "))
end
vim.cmd [[command! LspListServers lua LspListServers()]]

_G.turn_on_lsp()
  end
end

_G.turn_on_lsp()

-- UI Borders
vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx)
  vim.lsp.handlers.hover(err, result, ctx, { border = "rounded" })
end

vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx)
  vim.lsp.handlers.signature_help(err, result, ctx, { border = "rounded" })
end


-- =============================================================================
--  NULL-LS (Formatting & Diagnostics via external tools)
-- =============================================================================
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

null_ls.setup {
  debug = false,
  sources = {
    -- formatting.eslint.with { extra_args = { "--fix" } },
    formatting.black.with { extra_args = { "--fast" } },
    formatting.stylua,
  },
}

-- =============================================================================
--  HIGHLIGHT ON YANK (Copy)
-- =============================================================================
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 200,
    })
  end,
})

-- FLUTTER
local ok_flutter, _ = pcall(require, "flutter-tools")
if ok_flutter then
  require("flutter-tools").setup {}
end
