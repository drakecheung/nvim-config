local status_ok, gitsigns = pcall(require, "gitsigns")
if not status_ok then
  return
end

gitsigns.setup {
  sign_priority = 6,
  update_debounce = 100,
  max_file_length = 5000, -- Disable if file is longer than this (in lines)
  preview_config = {
    -- Options passed to nvim_open_win
    border = 'single',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end
    map('n', 'gj', gs.next_hunk)
    map('n', 'gk', gs.prev_hunk)
    map('n', 'gr', gs.reset_hunk)
    map('n', 'gh', gs.preview_hunk)
    --[[ map('n', 'gd', gs.diffthis) ]]
    map('n', 'gd', ":call system('git difftool -t diffuse -y -- ' . expand('%'))<cr>")
    map('n', 'gt', ":call system('gitk')<cr>")
    -- stage/unstage hunk with <leader>g + s/u
    map("n", "<leader>gk", ":call system('gitk ' . expand('%'))<cr>")    -- only the current file
    map("n", "<leader>gkk", ":call system('gitk')<cr>")                  -- the whole repo
  end
  --   watch_gitdir = {
  --     interval = 1000,
  --     follow_files = true,
  --   },
}

local opts = { noremap = true, silent = true }
local map = vim.api.nvim_set_keymap
map("n", "gs", "<cmd>Telescope git_status<cr>", opts)
map("n", "gc", "<cmd>Telescope git_commits<cr>", opts)
map("n", "gu", "<cmd>call TmuxPopup('echo git pull...; git pull; any-key')<cr>", opts)
map("n", "gi", "<cmd>call TmuxPopup('git-commit; any-key')<cr>", opts)
map("n", "gpp", "<cmd>call TmuxPopup('git-pull-and-push; any-key')<cr>", opts)
