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
map("n", "s0", function()
  vim.g.cursor_position = vim.fn.winsaveview()
  vim.cmd.normal('ggVG')
  send.send_highlighted_lines()
  vim.defer_fn(function() vim.fn.winrestview(vim.g.cursor_position) end, 0)
end, opts)
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
map("n", "rz", console_pane_flag_toggle, opts)
map("n", "<leader>u", function()
  require("luasnip.loaders.from_snipmate").edit_snippet_files()
end, opts)
cancel("n", {">>", "<<", ":", "/", "?", "Q", "qq", "<bs>", "<del>", "<cr>", "<up>", "<down>", "<left>", "<right>"})

map("n", "<c-h>", '<cmd>lua vim.diagnostic.jump({ count = -1, float = false })<cr>', opts)
map("n", "<c-l>", '<cmd>lua vim.diagnostic.jump({ count = 1, float = false })<cr>', opts)
map("n", "<c-m-]>", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
map("n", "<c-]>", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)

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
map("x", "sf", "gc", { remap = true, desc = "Toggle comment" })
map("x", "SF", "gc", { remap = true, desc = "Toggle comment" })
map("x", "<c-f>", "<cmd>Telescope grep_string<cr>", opts)
cancel("x", {">", "<", "<esc>", ":"})

-- Command
map("c", "jk", "<c-c>", opts)
map("c", "%%", "<c-r>=expand('%:h').'/'<cr>", opts) -- expand current path
map("c", "%$", "<c-r>=expand('%').'/'<cr>", opts) -- expand current path
cancel("c", {"<esc>", "<del>"})

vim.cmd "source ~/.config/nvim/lua/keymap.vim"

-- llm code rewrite
vim.keymap.set("x", "<c-r>", function()
  -- Get the current file path and type
  local file_path = vim.fn.expand("%:p")
  local file_type = vim.bo.filetype

  -- Determine the start and end lines of the visual selection
  local start_line = math.min(vim.fn.line("v"), vim.fn.line("."))
  local end_line = math.max(vim.fn.line("v"), vim.fn.line("."))

  -- Save the current scroll position and cursor line
  local scroll_pos = vim.fn.winsaveview()

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)

  -- Construct the CLI command for llm-rewrite
  local cli = "llm-rewrite '" .. file_path .. "' '" .. file_type .. "' " .. start_line .. " " .. end_line

  -- Run the CLI command in a popup
  send.run_popup(cli)

  -- Reload the current file to reflect any changes
  vim.cmd("edit")

  -- Restore the scroll position and cursor line
  vim.fn.winrestview(scroll_pos)
end, { noremap = true, silent = true })

-- llm code ask
vim.keymap.set("x", "<c-q>", function()
  -- Get the current file path and type
  local file_path = vim.fn.expand("%:p")
  local file_type = vim.bo.filetype

  -- Determine the start and end lines of the visual selection
  local start_line = math.min(vim.fn.line("v"), vim.fn.line("."))
  local end_line = math.max(vim.fn.line("v"), vim.fn.line("."))

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)

  -- Construct the CLI command for llm-rewrite
  local cli = "llm-ask '" .. file_path .. "' '" .. file_type .. "' " .. start_line .. " " .. end_line

  -- Run the CLI command in a popup
  -- send.run_popup(cli)
  exec_in_split(cli)
end, { noremap = true, silent = true })

