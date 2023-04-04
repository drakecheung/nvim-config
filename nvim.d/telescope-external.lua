local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local themes = require "telescope.themes"
local conf = require("telescope.config").values
local actions = require "telescope.actions"      -- :help telescope.actions
local action_state = require "telescope.actions.state"
local json = require "cjson"

local M = {}

M.init = function(cmd, opts)
  opts = opts or {}

  local handle = io.popen(cmd)
  local json_string = handle:read("*a")
  handle:close()
  local parsed = json.decode(json_string)

  pickers.new(opts, {
    prompt_title = parsed.title,
    finder = finders.new_table {
      results = parsed.entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.ordinal,
          path = entry.path,
          lnum = entry.lnum,
        }
      end
    },
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
    attach_mappings = function(prompt_bufnr)
      local edit = function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel.lnum then
          vim.cmd(":e " .. "+" .. sel.lnum .. " " .. sel.path)
        else
          vim.cmd(":e " .. sel.path)
        end
      end
      actions.select_default:replace(edit)
      actions.select_tab:replace(edit)
      return true
    end,
  }):find()
end

M.open = function(script)
  return function()
    M.init(script, themes.get_dropdown{
      layout_strategy = 'vertical',
      layout_config = {
        height = 0.95,
        --[[ width = 0.95 ]]
      },
      borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
    })
  end
end

-- :lua require("telescope-fromcmd").fromcmd(require("telescope.themes").get_dropdown{})
return M
