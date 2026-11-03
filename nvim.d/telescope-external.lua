-- Feed the line-oriented output of an external command into a Telescope picker.
--
-- Contract: the command prints ONE ENTRY PER LINE. The first caller is
-- `bin/list-projects`, whose header documents `type|relative_path` (path is
-- relative to $HOME). No JSON is involved, so no JSON library is required.
--
-- Why the finder is `new_oneshot_job`: it runs the command asynchronously and
-- streams lines into the picker, so the UI stays responsive while a slow script
-- is still producing output. The previous version (io.popen + cjson + new_table)
-- blocked until the whole output was read, and needed a JSON producer that never
-- existed. History: the module was copied from lokikl/nvim-config in 2022 and was
-- never wired to a caller there either.
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local themes = require "telescope.themes"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local M = {}

-- Resolve the repo root from this file, so the script path survives a symlinked
-- config dir (~/.config/nvim/lua -> <repo>/nvim.d) and any clone location.
local source = vim.fn.resolve(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p"))
M.repo = vim.fn.fnamemodify(source, ":h:h")
M.script = M.repo .. "/bin/list-projects"

-- "type|relative_path" -> Telescope entry (nil drops the line).
M.entry_maker = function(line)
  local kind, rel = line:match("^([^|]+)|(.+)$")
  if not rel then
    return nil
  end
  return {
    value = line,
    display = kind .. "  " .. rel,
    ordinal = rel,
    path = vim.fn.expand("~") .. "/" .. rel,
  }
end

M.init = function(command_list, opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = opts.prompt_title or "External list",
    finder = finders.new_oneshot_job(command_list, { entry_maker = M.entry_maker }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr)
      local open = function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel and sel.path then
          vim.cmd(":e " .. vim.fn.fnameescape(sel.path))
        end
      end
      actions.select_default:replace(open)
      actions.select_tab:replace(open)
      return true
    end,
  }):find()
end

-- Dropdown wrapper; kept from the original module so a keymap can be a one-liner.
M.open = function(command_list, title)
  return function()
    M.init(command_list, themes.get_dropdown {
      prompt_title = title,
      layout_strategy = "vertical",
      layout_config = { height = 0.95 },
      borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
    })
  end
end

M.projects = function()
  M.init({ M.script }, themes.get_dropdown {
    prompt_title = "Projects",
    layout_strategy = "vertical",
    layout_config = { height = 0.95 },
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
  })
end

return M
