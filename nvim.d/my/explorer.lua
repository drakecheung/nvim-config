local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  return
end

local lib = require("nvim-tree.lib")
local view = require("nvim-tree.view")
local open_file = require('nvim-tree.actions.node.open-file')

nvim_tree.setup {
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
      list = {
        -- R: reload, a: add, d: del, r: rename, o/x: open/close folder
        -- t: open in tab, q: close
        { key = "<c-t>", action = "close" },
        { key = "t", action = "" },
        { key = "x", action = "close_node" },
        { key = "qf", action = "close" },
        -- { key = "<c-j>", action = "edit" },
        { key = "<c-j>", action = "xxx", action_cb = function()
          local node = lib.get_node_at_cursor()
          if node.nodes ~= nil then
            lib.expand_or_collapse(node)
          else
            open_file.fn("edit", node.absolute_path)
            view.close()
          end
        end },
      },
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
