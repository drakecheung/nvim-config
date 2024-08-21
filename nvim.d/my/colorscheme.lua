vim.g.vscode_style = "dark"
local colorscheme = "vscode"

-- vim.g.material_style = "darker"
-- local colorscheme = "material"

-- vim.g.substrata_variant = "brighter"
-- local colorscheme = "substrata"

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  vim.notify("colorscheme " .. colorscheme .. " not found!")
  return
end

vim.cmd "hi tablinesel gui=none guifg=#ffffff guibg=#666666"
-- vim.cmd "hi tablinefill cterm=reverse gui=reverse guifg=#eeeeee guibg=#eeeeee"
-- vim.cmd "hi tabline cterm=none ctermfg=15 ctermbg=242 gui=none guifg=#ffffff guibg=#666666"
-- vim.cmd "hi tablinesel gui=none guifg=#ffffff guibg=#1e1e1e"

vim.g.cursorline_timeout = 800

-- indent_blankline
local ok2, ibl = pcall(require, "ibl")
ibl.setup {
  indent = { char = "▏" },
  scope = { enabled = false },
}

-- vim.g.indent_blankline_buftype_exclude = { "terminal", "nofile" }
-- vim.g.indent_blankline_filetype_exclude = {
-- 	"help",
-- 	"startify",
-- 	"dashboard",
-- 	"packer",
-- 	"neogitstatus",
-- 	"NvimTree",
-- 	"Trouble",
-- }
-- vim.g.indentLine_enabled = 1
-- -- vim.g.indent_blankline_char = "│"
-- vim.g.indent_blankline_char = "▏"
-- -- vim.g.indent_blankline_char = "▎"
-- vim.g.indent_blankline_show_trailing_blankline_indent = false
-- vim.g.indent_blankline_show_first_indent_level = true
-- vim.g.indent_blankline_use_treesitter = true
-- vim.g.indent_blankline_show_current_context = true
-- vim.g.indent_blankline_context_patterns = {
-- 	"class",
-- 	"return",
-- 	"function",
-- 	"method",
-- 	"^if",
-- 	"^while",
-- 	"jsx_element",
-- 	"^for",
-- 	"^object",
-- 	"^table",
-- 	"block",
-- 	"arguments",
-- 	"if_statement",
-- 	"else_clause",
-- 	"jsx_element",
-- 	"jsx_self_closing_element",
-- 	"try_statement",
-- 	"catch_clause",
-- 	"import_statement",
-- 	"operation_type",
-- }

-- HACK: work-around for https://github.com/lukas-reineke/indent-blankline.nvim/issues/59
-- vim.wo.colorcolumn = "99999"

-- vim.cmd [[highlight IndentBlanklineIndent1 guifg=#E06C75 gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent2 guifg=#E5C07B gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent3 guifg=#98C379 gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent4 guifg=#56B6C2 gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent5 guifg=#61AFEF gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent6 guifg=#C678DD gui=nocombine]]
-- vim.opt.list = true
-- vim.opt.listchars:append "space:⋅"
-- vim.opt.listchars:append "space:"
-- vim.opt.listchars:append "eol:↴"

-- indent_blankline.setup({
-- 	-- show_end_of_line = true,
-- 	-- space_char_blankline = " ",
-- 	show_current_context = true,
-- 	-- show_current_context_start = true,
-- 	-- char_highlight_list = {
-- 	--   "IndentBlanklineIndent1",
-- 	--   "IndentBlanklineIndent2",
-- 	--   "IndentBlanklineIndent3",
-- 	-- },
-- })

vim.g.scrollbar_excluded_filetypes = {'NvimTree'}
vim.g.scrollbar_right_offset = 0
vim.g.scrollbar_shape = {
  head ='🮇',
  body ='🮇',
  tail ='🮇',
}
vim.cmd [[
  augroup ScrollbarInit
    autocmd!
    autocmd WinScrolled,VimResized,QuitPre * silent! lua require('scrollbar').show()
    autocmd WinEnter,FocusGained,TabEnter  * silent! lua require('scrollbar').show()
    autocmd WinLeave,BufLeave,BufWinLeave,FocusLost,QuitPre,TabLeave * silent! lua require('scrollbar').clear()
  augroup end
]]

local ok3, colorizer = pcall(require, "colorizer")
if ok3 then
  colorizer.setup {
    '*';
    scss = {
      css      = true;   -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
      css_fn   = true;   -- Enable all CSS *functions*: rgb_fn, hsl_fn
      mode     = 'background';
    };
  }
end
