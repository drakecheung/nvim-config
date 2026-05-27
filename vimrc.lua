-- Suppress deprecation warnings for renamed API (nvim 0.10+)
vim.tbl_islist = vim.islist
vim.tbl_flatten = function(t) return vim.iter(t):flatten():totable() end

-- https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/
-- https://github.com/nanotee/nvim-lua-guide
-- https://www.youtube.com/watch?v=OhnLevLpGB4&list=PLhoH5vyxr6Qq41NFL4GvhFp-WLd5xzIzZ
-- https://github.com/LunarVim/Neovim-from-scratch

require "my.option"
require "my.utilities"
require "my.colorscheme"
require "my.keymap"
require "my.plugin"
require "my.completion"
require "my.telescope"
require "my.lsp"
require "my.treesitter"
require "my.comment"
require "my.git"
require "my.explorer"
require "my.statusline"
require "my.tabline"
vim.cmd "source ~/.config/nvim/lua/autocmd.vim"
vim.cmd "source ~/.config/nvim/lua/tmux.vim"
require "my.whichkey"
