local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer close and reopen Neovim..."
  vim.cmd [[packadd packer.nvim]]
end

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

local ok2, packer_luarocks = pcall(require, "packer.luarocks")
if not ok2 then
  return
end
packer_luarocks.install_commands()

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

-- " vim features that extracted out as a separate file, but not grouped as a
-- " plugin yet
-- function! SourceWhenExist(filepath)
--   if !empty(glob(a:filepath))
--     exec "so " . a:filepath
--   endif
-- endfunction
-- can probably be replaced with lsp
-- call SourceWhenExist("/home/drake/drake/env/vim-misc/plugin/html.vim")
-- for refactoring ruby
-- call SourceWhenExist("/home/drake/drake/env/vim-misc/plugin/extract-method.vim")

-- Install your plugins here
packer.startup(function(use, use_rocks)
  -- if not auto-installed, install with command
  -- :PackerRocks install lua-cjson
  -- :PackerRocks install f-strings
  -- if found error in missing loader module, untar lua-5.1.tar in this repo to replace:
  --   ~/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1
  use_rocks 'lua-cjson'
  use_rocks 'f-strings'

  use "wbthomason/packer.nvim"          -- Have packer manage itself
  use "nvim-lua/popup.nvim"             -- An implementation of the Popup API from vim in Neovim
  use "nvim-lua/plenary.nvim"           -- Useful lua functions used ny lots of plugins
  use 'antoinemadec/FixCursorHold.nvim'
  use "tpope/vim-repeat"
  use "triglav/vim-visual-increment"    -- increase numbers on multiple lines at once
  use "tomtom/tlib_vim"                 -- provided string#Strip, used in the drakenote bullet style switching shortcut
  use "rcarriga/nvim-notify"

  -- which key
  use "folke/which-key.nvim"

  -- Colorscheme
  use 'Mofiqul/vscode.nvim'
  use 'kvrohit/substrata.nvim'
  use 'marko-cerovac/material.nvim'
  use 'norcalli/nvim-colorizer.lua'

  use {'yamatsum/nvim-cursorline', config = function()
    vim.g.cursorword_highlight = false
    vim.cmd [[hi CursorWord guibg=#444444]]
  end}
  use 'lukas-reineke/indent-blankline.nvim'
  use 'Xuyuanp/scrollbar.nvim'

  -- Completion
  use "L3MON4D3/LuaSnip"
  use "hrsh7th/nvim-cmp"
  -- use {"hrsh7th/nvim-cmp", commit = "dbc72290295cfc63075dab9ea635260d2b72f2e5"}
  use "hrsh7th/cmp-buffer"
  use "hrsh7th/cmp-path"
  use "hrsh7th/cmp-cmdline"
  use "hrsh7th/cmp-nvim-lsp"
  use "hrsh7th/cmp-nvim-lua"
  use "lukas-reineke/cmp-rg"
  use "saadparwaiz1/cmp_luasnip"

  -- LSP
  use "neovim/nvim-lspconfig"
  use "williamboman/nvim-lsp-installer"
  use "b0o/schemastore.nvim"
  use "jose-elias-alvarez/null-ls.nvim"

  -- Telescope
  -- download and install ripgrep deb from https://github.com/BurntSushi/ripgrep/releases
  use "nvim-telescope/telescope.nvim"
  use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make'}
  use 'nvim-telescope/telescope-media-files.nvim'

  -- Treesitter
  use {"nvim-treesitter/nvim-treesitter", run = ":TSUpdate"}
  use "nvim-treesitter/playground"
  use 'JoosepAlviste/nvim-ts-context-commentstring'

  -- Git
  use "lewis6991/gitsigns.nvim"

  -- Explorer
  use 'kyazdani42/nvim-web-devicons'
  use 'kyazdani42/nvim-tree.lua'

  -- Tabline / Statusline
  use "ojroques/nvim-hardline"
  -- use "romgrk/barbar.nvim"
  use {'akinsho/bufferline.nvim', tag = "*", requires = 'kyazdani42/nvim-web-devicons'}

  -- Marks
  use "kshenoy/vim-signature"    -- m* to toggle, display in sign bar

  -- Handy conversions
  vim.cmd [[let g:VM_maps = {}]]
  vim.cmd [[let g:VM_maps['Skip Region'] = '<C-x>']]
  vim.cmd [[let g:VM_maps['Exit'] = '<C-c>']]
  -- use "mg979/vim-visual-multi"
  use "bronson/vim-trailing-whitespace"    -- try if this can be replaced by lsp auto format
  use "numToStr/Comment.nvim"
  use "tpope/vim-surround"   -- manage surrounding characters like (abc) -> [abc] : cs([
  -- crs: snake_case
  -- crm: MixedCase
  -- crc: camelCase
  -- cru: UPPER_CASE
  -- cr-: dash-case
  -- cr<space>: space case
  -- crt: Title Case
  use "tpope/vim-abolish"
  use 'glts/vim-magnum'
  use 'glts/vim-radical'    -- convert numbers in different format: gA, crd, crx, cro, crb
  -- Tabular: create table / align mapping quickly
  -- use 'godlygeek/tabular'
  -- nnoremap <Leader>t= :Tabularize /^[^=]*<CR>
  -- vnoremap <Leader>t= :Tabularize /^[^=]*<CR>
  -- nnoremap <Leader>t: :Tabularize /^[^:]*:/l0l1l0<CR>
  -- vnoremap <Leader>t: :Tabularize /^[^:]*:/l0l1l0<CR>
  -- nnoremap <Leader>t, :Tabularize /,\zs<CR>
  -- vnoremap <Leader>t, :Tabularize /,\zs<CR>
  -- nnoremap <Leader>t<Space> :Tabularize / \zs<CR>
  -- vnoremap <Leader>t<Space> :Tabularize / \zs<CR>
  -- noremap <Leader>t{ :Tabularize /{<cr>
  -- noremap <Leader>t# :Tabularize /#<cr>
  -- noremap <Leader>t> :Tabularize /=><cr>

  use 'subnut/nvim-ghost.nvim'
  vim.cmd [[
    let g:nvim_ghost_autostart = 0
    augroup nvim_ghost_user_autocommands
      au User txti.es setfiletype python
      au User *github.com setfiletype markdown
    augroup END
  ]]
  -- start manually with :GhostTextStart

  use {'akinsho/flutter-tools.nvim', requires = 'nvim-lua/plenary.nvim'}

  use({
    "iamcco/markdown-preview.nvim",
    run = "cd app && npm install",
    setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
    ft = { "markdown" },
  })

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
