" disable auto indent for html-like files
" disable syntax highlight for kube.config (faster)
au BufNewFile,BufEnter kube.config syntax off

" auto resource after changing any .vim file
au! BufWritePost *.vim,vimrc,.vimrc :so %

" run current golang file, and append output under current line
au FileType go noremap <silent> <m-r>
  \ :w ! go-run<cr>
  \ :r /tmp/mytmp.go.out<cr>

" run current elixir file, and append output under current line
au FileType elixir noremap <silent> <m-r>
  \ :w ! elixir-run<cr>
  \ :r /tmp/mytmp.exs.out<cr>

au FileType elixir vnoremap <silent> <m-r> <esc>
  \ :'<,'>w ! elixir-run<cr>
  \ :r /tmp/mytmp.exs.out<cr>

au FileType zsh noremap <silent> <m-r>
  \ :'.,'.w ! zsh-run<cr>
  \ :r /tmp/mytmp.zsh.out<cr>

au FileType zsh vnoremap <silent> <m-r> <esc>
  \ :'<,'>w ! zsh-run<cr>
  \ :r /tmp/mytmp.zsh.out<cr>

au BufNewFile,BufRead *.uplugin set ft=json

au FileType python noremap <silent> <m-r> :w ! python<cr>
au FileType sh noremap <silent> <m-r> :w ! sh<cr>
au! BufNewFile,BufRead *.ln set filetype=lokinote
" lokinote ftplugin loaded automatically from rtp/ftplugin/lokinote.vim

au VimEnter * call LoadProjectVimRC()
function! LoadProjectVimRC()
  if filereadable("project.vim.lua")
    luafile project.vim.lua
  elseif filereadable(".devbase/project.vim.lua")
    luafile .devbase/project.vim.lua
  endif
  if filereadable(".devbase/project.vim")
    so .devbase/project.vim
  elseif filereadable("project.vim")
    so project.vim
  endif
endfunction
au! BufWritePost project.vim.lua luafile %


augroup _general_settings
  autocmd!
  autocmd FileType qf,help,man,lspinfo nnoremap <silent> <buffer> <c-c> :close<CR>
  autocmd TextYankPost * silent!lua require('vim.highlight').on_yank({higroup = 'Search', timeout = 200})
  autocmd FileType qf set nobuflisted
augroup end

augroup _markdown
  autocmd!
  autocmd FileType markdown setlocal wrap
  autocmd FileType markdown setlocal spell
augroup end

" auto trailing whitespaces removal
let noWhitespaceRemoval = ['vim', 'md', 'csv']
autocmd BufWritePre * if index(noWhitespaceRemoval, &ft) < 0 | FixWhitespace

" legacy function for reloading all buffers, used in various projects
function! TabdoChecktime()
  set noconfirm
  tabdo checktime
  set confirm
endfunction

" auto reload changed files (work well with gs > m-r)
au! FocusGained,BufEnter * checktime
