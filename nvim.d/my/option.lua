local o = vim.opt

-- Backups settings
o.backup = false
o.writebackup = false
o.swapfile = false
o.directory = "/home/drake/.config/nvim/tmp"
o.undofile = true
o.undodir = "/home/drake/.config/nvim/tmp"
o.confirm = true

o.ruler = true
o.linebreak = true
o.list = false
o.wrap = false
o.laststatus = 3      -- global statusline supported in nvim 7.0
o.winaltkeys = "no"
o.relativenumber = true
o.number = true
o.numberwidth = 3
o.scrolloff = 5 -- 8
o.virtualedit = "block"
o.switchbuf = "uselast,useopen"

o.clipboard = "unnamedplus"               -- allows neovim to access the system clipboard
o.cmdheight = 2                           -- more space in the neovim command line for displaying messages
o.completeopt = { "menu", "preview", "menuone" } -- mostly just for cmp
-- o.completeopt = { "menuone", "noselect" } -- mostly just for cmp

-- "change the autocomplete style
o.wildmenu = true
-- o.wildmode = list:longest,full
o.lazyredraw = true                  -- for complex macro playback
o.iskeyword:append "-"

o.autoread = true
o.history = 10000
o.undolevels = 1000
o.timeoutlen = 300
o.updatetime = 300
o.formatoptions = "lj"          -- join 2 comment lines with leader (#, //, --, etc...)

o.tabstop = 2
o.shiftwidth = 2
o.cindent = true
o.autoindent = true
o.smarttab = true
o.expandtab = true
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = true
o.conceallevel = 0
o.fileencoding = "utf-8"
o.pumheight = 20                    -- popup menu, 0 = max space
o.showmode = true                   -- INSERT, VISUAL
o.smartindent = true
o.splitbelow = true
o.splitright = true
o.cursorline = true
o.termguicolors = true
o.signcolumn = "yes:2"
vim.cmd "set wildignore+=*.o,*.obj,*.exe,*.so,*.dll,*.pyc,.svn,.hg,.bzr,.git,.sass-cache,*.class,*.jpg,*.JPG,*.gif,*.png,*.log,*rake-pipeline*,node_modules"

-- set showmatch
-- set matchtime=2
-- hi MatchParen cterm=none ctermbg=green ctermfg=blue

o.errorbells = false
o.visualbell = false
o.mouse = "a"
o.shortmess = "atTF"

-- Better complete options to speed it up
-- k is dictionary, use ./tags when coding
vim.cmd "set complete=.,w,b,u,U,k"
