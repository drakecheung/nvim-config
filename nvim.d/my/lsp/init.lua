local ok1, _ = pcall(require, "lspconfig")
if not ok1 then return end

-- local ok2, lsp_installer = pcall(require, "nvim-lsp-installer")
-- if not ok2 then return end

local ok2, mason = pcall(require, "mason")
if not ok2 then return end

local ok3, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not ok3 then return end

local ok4, null_ls = pcall(require, "null-ls")
if not ok4 then return end

local ok5, masonlsp = pcall(require, "mason-lspconfig")
if not ok5 then return end

--[[ tail -f  ~/.local/state/nvim/lsp.log ]]

mason.setup()
masonlsp.setup {
  ensure_installed = { "eslint", "bashls", "pyright" },
}

require("lspconfig").eslint.setup {}
-- require("lspconfig").tsserver.setup {}
require("lspconfig").bashls.setup {}
-- require("lspconfig").pyright.setup {}

-- pip install ruff_lsp
-- https://github.com/astral-sh/ruff-lsp
require("lspconfig").ruff_lsp.setup {
  on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format()
				end,
			})
		end
	end,
}

-- local on_attach = function(client, bufnr)
--   local opts = { noremap = true, silent = true }
--   local map = vim.api.nvim_buf_set_keymap
--   map(bufnr, "n", "<c-h>", '<cmd>lua vim.diagnostic.goto_prev({ float = false })<cr>', opts)
--   map(bufnr, "n", "<c-l>", '<cmd>lua vim.diagnostic.goto_next({ float = false })<cr>', opts)
--   map(bufnr, "n", "<c-m-]>", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
--   map(bufnr, "n", "<c-]>", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
--   map(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
-- end

-- lsp_installer.on_server_ready(function(server)
--   local opts = {
--     on_attach = on_attach,
--     capabilities = cmp_nvim_lsp.default_capabilities(),
--   }
--
--   -- refs for all LSP servers
--   -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--   if (server.name == "grammarly") then
--     opts.filetypes = { "markdown", "rst", "html", "lokinote" }
--   end
--
--   -- if (server.name == "sqls") then
--   --   opts.settings = {
--   --     sqls = {
--   --       lowercaseKeywords = false,
--   --       connections = {
--   --         {
--   --           driver = 'postgresql',
--   --           dataSourceName = 'host=127.0.0.1 port=15432 user=farmweb password=farmweb321 dbname=farmweb',
--   --         }
--   --       }
--   --     }
--   --   }
--   -- end
--
--   if server.name == "ltex" then
--     opts.filetypes = { "lokinote", "bib", "gitcommit", "markdown", "org", "plaintex", "rst", "rnoweb", "tex" }
--   end
--
--   if server.name == "tsserver" then
--     local tsserver_opts = require("my.lsp.tsserver")
--     opts = vim.tbl_deep_extend("keep", tsserver_opts, opts)
--   end
--
--   if server.name == "jsonls" then
--     local jsonls_opts = require("my.lsp.jsonls")
--     opts = vim.tbl_deep_extend("force", jsonls_opts, opts)
--   end
--
--   if server.name == "sumneko_lua" then
--     local sumneko_opts = require("my.lsp.sumneko_lua")
--     opts = vim.tbl_deep_extend("force", sumneko_opts, opts)
--   end
--
--   if server.name == "pyright" then
--     local pyright_opts = require("my.lsp.pyright")
--     opts = vim.tbl_deep_extend("force", pyright_opts, opts)
--   end
--
--   -- This setup() function is exactly the same as lspconfig's setup function.
--   -- Refer to https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--   server:setup(opts)
-- end)

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
  if lsp_is_on == true then
    _G.turn_off_lsp()
  else
    _G.turn_on_lsp()
  end
end

_G.turn_on_lsp()

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "rounded",
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = "rounded",
})

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

null_ls.setup {
  debug = false,
  sources = {
    formatting.prettier.with { extra_args = { } },
    -- formatting.black.with { extra_args = { "--fast" } },
    -- formatting.yapf,
    formatting.stylua,
    -- diagnostics.flake8,
  },
}

require("flutter-tools").setup{} -- use defaults
