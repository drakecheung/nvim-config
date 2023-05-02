local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  return
end

local lib = require("nvim-tree.lib")
local view = require("nvim-tree.view")
local open_file = require('nvim-tree.actions.node.open-file')

-- https://github.com/nvim-tree/nvim-tree.lua/wiki/Migrating-To-on_attach
local function on_attach(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end
  -- vim.keymap.set('n', '>',     api.node.navigate.sibling.next,        opts('Next Sibling'))

  -- R: reload, a: add, d: del, r: rename, o/x: open/close folder
  -- t: open in tab, q: close
  vim.keymap.set('n', '<c-t>', api.tree.close, opts('Close'))
  vim.keymap.set('n', 'x', api.node.navigate.parent_close, opts('Close Directory'))
  local open = function()
    local node = lib.get_node_at_cursor()
    if node.nodes ~= nil then
      lib.expand_or_collapse(node)
    else
      open_file.fn("edit", node.absolute_path)
      view.close()
    end
  end
  vim.keymap.set('n', '<c-j>', open, opts('Toggle directory or edit file'))
  vim.keymap.set('n', 'o', open, opts('Toggle directory or edit file'))
end

nvim_tree.setup {
  on_attach = on_attach,
  auto_reload_on_write = true,
  disable_netrw = true,
  hijack_cursor = false,
  hijack_netrw = true,
  hijack_unnamed_buffer_when_opening = false,
  sort_by = "name",
  update_cwd = false,
  view = {
    width = 35,
    --[[ height = 30, ]]
    side = "left",
    number = false,
    relativenumber = false,
    mappings = {
      custom_only = false,
    },
  },
  filters = {
    dotfiles = false,
    custom = {},
    exclude = {},
  },
  diagnostics = {
    enable = true,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },
  update_focused_file = {
    enable = true,
    update_cwd = true,
    ignore_list = {},
  },
  git = {
    enable = true,
    ignore = true,
    timeout = 500,
  },
}
