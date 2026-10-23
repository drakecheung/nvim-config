-- nvim-treesitter (main branch, required by nvim 0.12) no longer ships
-- `nvim-treesitter.configs`; it is now only a parser installer/updater.
-- Highlighting and indentation have to be wired up by hand.
local ok, ts = pcall(require, "nvim-treesitter")
if not ok then
  return
end

-- The main branch keeps its bundled queries in <plugin>/runtime, which is NOT
-- added to 'runtimepath' when the plugin lives under pack/*/start. Without this
-- line queries/{highlights,indents}.scm resolve to nil and both features stay
-- silent no-ops (measured: highlight attached=false on a .js buffer).
local plugin_dir = vim.fn.stdpath("data") .. "/site/pack/packer/start/nvim-treesitter"
if vim.uv.fs_stat(plugin_dir .. "/runtime") then
  vim.opt.rtp:append(plugin_dir .. "/runtime")
end

ts.setup {}

local ensure_installed = { "lua", "vim", "javascript", "python" }

-- Only reach the network for parsers that are genuinely missing.
local missing = vim.tbl_filter(function(lang)
  return vim.treesitter.language.add(lang) == nil
end, ensure_installed)
if #missing > 0 then
  ts.install(missing)
end

-- javascript opts out of treesitter indent: its indents.scm walks adjacent
-- nodes and mis-indents embedded SQL. Keep Vim's GetJavascriptIndent instead.
local indent_disabled = { javascript = true }

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("my_treesitter", { clear = true }),
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype
    local lang = vim.treesitter.language.get_lang(ft) or ft
    if vim.treesitter.language.add(lang) == nil then
      return
    end

    pcall(vim.treesitter.start, ev.buf)

    if not indent_disabled[lang] and vim.treesitter.query.get(lang, "indents") then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
