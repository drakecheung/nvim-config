#!/usr/bin/env bash

# NOTE: node is required by package.json (puppeteer, svg-term-cli)
# Version is not strictly checked — any recent node (18+) works.
if ! which node > /dev/null 2>&1; then
  echo "node not found, aborting..."
  exit 1
fi

if nvim --version | head -n1 | grep -qE 'v0\.(1[1-9]|[2-9])'; then
  :  # nvim >= 0.11 (required for vim.lsp.config API)
else
  echo "expected nvim >= 0.11, aborting..."
  exit 1
fi

if pip3 list 2>/dev/null | grep -q pynvim; then
  :  # pynvim found
else
  echo "expected pynvim, aborting..."
  exit 1
fi

if tmux -V | grep -qE '[3-9]\.[5-9]'; then
  :  # tmux >= 3.5
else
  echo "expected tmux >= 3.5, aborting..."
  exit 1
fi

if ! which rg > /dev/null; then
  echo "rg not found, aborting..."
  exit 1
fi

if ! which fdfind > /dev/null; then
  echo "fdfind not found, aborting..."
  exit 1
fi

if ! which fzf > /dev/null; then
  echo "fzf not found, aborting..."
  exit 1
fi

mkdir -p ~/.config/nvim

rm -rf \
  ~/.config/nvim/init.lua \
  ~/.config/nvim/lua \
  ~/.config/nvim/snippets \
  ~/.tmux.conf \
  ~/.config/kitty/kitty.conf \
  ~/.config/wezterm/wezterm.lua \
  ~/.config/nvim/ftdetect \
  ~/.config/nvim/ftplugin \
  ~/.config/nvim/syntax

ln -s `pwd`/vimrc.lua ~/.config/nvim/init.lua
ln -s `pwd`/nvim.d ~/.config/nvim/lua
ln -s `pwd`/ftdetect ~/.config/nvim/ftdetect
ln -s `pwd`/ftplugin ~/.config/nvim/ftplugin
ln -s `pwd`/syntax ~/.config/nvim/syntax
ln -s `pwd`/snippets ~/.config/nvim/snippets
ln -s `pwd`/tmux.conf ~/.tmux.conf
[ -d ~/.config/kitty ] && ln -s `pwd`/kitty.conf ~/.config/kitty/kitty.conf
[ -d ~/.config/wezterm ] && ln -s `pwd`/wezterm.lua ~/.config/wezterm/wezterm.lua

echo "Symlinks done"

if ! which open-project 1>/dev/null 2>&1; then
  sourceLine="export PATH=\"\$PATH:`pwd`/bin\""
  [ -f ~/.bashrc ] && echo $sourceLine >> ~/.bashrc
  [ -f ~/.zshrc ] && echo $sourceLine >> ~/.zshrc
  echo "RC files Done"
fi

tmux source-file ~/.tmux.conf
echo "Reload tmux done"
