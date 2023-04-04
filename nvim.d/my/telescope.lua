local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

local actions = require "telescope.actions"

local style = {
  theme = "dropdown",
  hidden = true,
  layout_strategy = 'vertical',
  layout_config = {
    height = 0.99,
    width = 0.8,
  },
  borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
}

telescope.setup {
  defaults = {
    file_ignore_patterns = {
      'node_modules/',
      '.yarn/',
      'target/',
      'dist/',
      '.DS_Store/',
      'deps/',
      '_build/',
      '.git/',
      '.pyc$',
      '.svg$',
      '.otf$', '.ttf$',
    },

    -- shorten, smart, absolute
    path_display = { "absolute" },

    mappings = {
      i = {
        ["<C-n>"] = actions.cycle_history_next,
        ["<C-p>"] = actions.cycle_history_prev,

        ["<m-j>"] = actions.move_selection_next,
        ["<m-k>"] = actions.move_selection_previous,

        ["<C-c>"] = actions.close,
        ["jk"] = actions.close,
        ["<esc>"] = actions.close,

        ["<c-j>"] = actions.select_default,

        ["<up>"] = actions.preview_scrolling_up,
        ["<down>"] = actions.preview_scrolling_down,
        ["<c-/>"] = actions.which_key,

        ["<C-u>"] = false,
        ["<C-d>"] = false,
        ["<C-l>"] = false,
      },
    },
  },
  pickers = {
    find_files = style,
    grep_string = style,
    live_grep = style,
    git_status = {
      theme = "dropdown",
      layout_strategy = 'vertical',
      layout_config = { height = 0.99, width = 0.8 },
      borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
      mappings = {
        i = {
          ["<m-r>"] = function(prompt_bufnr)
            local action_state = require("telescope.actions.state")
            local selection = action_state.get_selected_entry()
            if selection == nil then
              return
            end
            run_cmd("git co '" .. selection.value .. "' > /dev/null")
            actions.close(prompt_bufnr)
            vim.cmd("Telescope git_status")
          end,
        },
      },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case" the default case_mode is "smart_case"
    },
    media_files = {
      -- filetypes whitelist
      -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
      filetypes = {"png", "webp", "jpg", "jpeg", "svg", "ttf", "otf"},
      find_cmd = "rg" -- find command (defaults to `fd`)
    }
  },
}

telescope.load_extension('fzf')
telescope.load_extension('media_files')
