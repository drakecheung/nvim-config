local opts = { noremap = true, silent = true }
-- local term_opts = { silent = true }
local map = vim.keymap.set
local cancel = function(tbl, keys)
  for _, k in pairs(keys) do
    map(tbl, k, "<nop>", opts)
  end
end

cancel("", {"<space>"})
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local send = require("my.send")

-- Normal
map("n", "q1", ":qa<cr>", opts)
map("n", "qd", ":qa<cr>", opts)
map("n", "qw", ":w<cr>", opts)
map("n", "<c-c>", ":nohlsearch<cr>:redraw!<cr>", opts)
map("n", "<m-n>", ":set nu! rnu!<cr>", opts)
map("n", "<c-j>", "<<", opts)
map("n", "<c-k>", ">>", opts)
map("n", "j", "gj", opts)
map("n", "k", "gk", opts)
map("n", "hu", ":")
map("n", "hj", "/")
map("n", "HJ", "?")
map("n", "hk", "<cmd>Telescope resume<cr>", opts)
map("n", "x", '"_x', opts)
map("n", "<m-a>", "ggVG", opts)
map("n", "<m-h>", ":BufferLineCyclePrev<cr>", opts)
map("n", "<m-l>", ":BufferLineCycleNext<cr>", opts)
map("n", "<leader><m-h>", ":BufferLineMovePrev<cr>", opts)
map("n", "<leader><m-l>", ":BufferLineMoveNext<cr>", opts)
map("n", "<m-b>", "<cmd>Telescope buffers theme=dropdown<cr>", opts)
map("n", "qf", "<cmd>bwipeout<cr>", opts)
map("n", "<leader>cl", ":let @+ = expand('%:p')<cr>", opts)     -- copy current file path to clipboard
map("n", "ss", send.send_current_line, opts)
map("n", "sb", send.send_last_line, opts)
map("n", "sc", send.send_current_cell, opts)
map("n", "gV", '`[v`]', opts)
map("n", "<leader>ps", ':PackerSync<cr>', opts)
map("n", "hl", "<cmd>Telescope find_files<cr>", opts)
map("n", "<leader>ca", "<cmd>Telescope live_grep<cr>", opts)
map("n", "<c-f>", "<cmd>Telescope grep_string<cr>", opts)
map("n", "<c-t>", "<cmd>NvimTreeToggle<cr>", opts)
map("n", "<leader>t", "<cmd>TSPlaygroundToggle<cr>", opts)
map("n", "<leader>hg", '<cmd>echo synIDattr(synID(line("."),col("."),1),"name")<cr>', opts)
map("n", "<leader>tl", '<cmd>lua toggle_lsp()<cr>', opts)
map("n", "c*", '*Ncgn', opts)        -- c* to edit word under cursor, repeatable by the dot key
map("n", "d*", '*Ndgn', opts)
map("n", "c.", '<cmd>let @/=@"<cr>/<cr>cgn<c-r>.<esc>', opts)       -- c. to make the last edit repeatable by dot
map("n", "d.", '<cmd>let @/=@"<cr>/<cr>dgn<c-r>.<esc>', opts)
map("n", "<leader>u", function()
  require("luasnip.loaders.from_snipmate").edit_snippet_files()
end, opts)
cancel("n", {">>", "<<", ":", "/", "?", "Q", "qq", "<bs>", "<del>", "<cr>", "<up>", "<down>", "<left>", "<right>"})

-- Insert
map("i", "jk", "<esc>", opts)
map("i", "qw", "<esc>:w<cr>", opts)
map("i", "<c-l>", "<c-x><c-l>", opts)
map("i", "<c-n>", "<Cmd>lua require('cmp').complete()<CR>", opts)
cancel("i", {"<esc>", "<del>", "<cr>", "<up>", "<down>", "<left>", "<right>"})

-- Visual
map("x", "<c-j>", "<gv", opts)
map("x", "<c-k>", ">gv", opts)
map("x", "hu", ":")
map("x", "p", '"_dP', opts)
map("x", "s", send.send_highlighted_lines, opts)
map("x", "sf", "<Plug>(comment_toggle_linewise_visual)", opts)
map("x", "SF", "<Plug>(comment_toggle_blockwise_visual)", opts)
map("x", "<c-f>", "<cmd>Telescope grep_string<cr>", opts)
cancel("x", {">", "<", "<esc>", ":"})

-- Command
map("c", "jk", "<c-c>", opts)
map("c", "%%", "<c-r>=expand('%:h').'/'<cr>", opts) -- expand current path
map("c", "%$", "<c-r>=expand('%').'/'<cr>", opts) -- expand current path
cancel("c", {"<esc>", "<del>"})

vim.cmd "source ~/.config/nvim/lua/keymap.vim"
