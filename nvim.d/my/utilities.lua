local status_ok, notify = pcall(require, "notify")
if status_ok then
  notify.setup({
    timeout = 1000,
    -- render = "minimal",
  })
  vim.notify = notify
end

_G.run_cmd = function(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  local output = handle:read("*a")
  handle:close()
  return output
end

_G.console_pane_flag = "-b"
_G.console_pane_flag_toggle = function()
  if _G.console_pane_flag == "-b" then
    _G.console_pane_flag = ""
    print "console is on right"
  else
    _G.console_pane_flag = "-b"
    print "console is on left"
  end
end

_G.console_ctl = function(cmd, size)
  return function()
    local left_pane = run_cmd([[tmux list-panes -F '#{pane_id} #{pane_start_command}' | grep leftpane]])
    local paneId = left_pane:match("([^ ]+)") or ""

    local kill_pane = function()
      local keys = {'c-d', 'c-c', 'c-c', 'c-c'}
      for i=1,4 do
        run_cmd("tmux send-keys -t " .. paneId .. " " .. keys[i] .. " 2>/dev/null")
      end
    end
    local actual_cmd = "zsh -c 'echo leftpane > /dev/null && " .. cmd .. "'"
    local subed = string.gsub(cmd, '"', '\\"')
    local percentage = size and "-l" .. size .. "%" or "-l32%"

    if string.find(left_pane, subed, 0, true) then
      kill_pane()
    elseif paneId == "" then
      run_cmd('tmux splitw -dh ' .. _G.console_pane_flag .. ' ' .. percentage .. ' -- ' .. actual_cmd)
    else
      run_cmd('tmux splitw -dv ' .. _G.console_pane_flag .. ' -t "' .. paneId .. '" -- ' .. actual_cmd)
      kill_pane()
    end
  end
end

_G.exec_in_split = function(cmd, tmux_arg)
  local cmd3 = "tmux splitw " .. (tmux_arg or "") .. " \"zsh -c '[ -f .envrc ] && source .envrc;" .. cmd .. "'\""
  run_cmd(cmd3)
end

_G.exec_in_tab = function(cmd, tmux_arg)
  local cmd3 = "tmux new-window " .. (tmux_arg or "") .. " \"zsh -c '[ -f .envrc ] && source .envrc;" .. cmd .. "'\""
  run_cmd(cmd3)
end

_G.exec_in_popup = function(cmd, tmux_arg)
  local c = string.gsub(cmd, '"', '\\"')
  local cmd2 = "tmux popup -E " .. (tmux_arg or "") ..
    " \"zsh -c 'cd `pwd`; pwd; [ -f .envrc ] && source .envrc;" .. c .. "'\""
  run_cmd(cmd2)
end

_G.ReloadConfig = function()
  for name,_ in pairs(package.loaded) do
    if name:match('^my') then
      package.loaded[name] = nil
    end
  end
  dofile("/home/drake/.config/nvim/init.lua")
end
vim.cmd [[command! ReloadConfig lua ReloadConfig()]]

_G.deprecate = function(alt)
  return function()
    vim.notify("Use " .. alt .. " instead", "error", {
      title = "Shortcut deprecated",
    })
  end
end

_G.deprecate_keymap = function(map, key, alt)
  vim.keymap.set(map, key, deprecate(alt))
end

-- project specific key mappings with which-key
_G.which_key_map = function(prefix, mappings)
  local wkok, which_key = pcall(require, "which-key")
  if not wkok then
    print "which-key.nvim is required but not found"
    return
  end
  which_key.register(mappings, {
    mode = "n",
    prefix = prefix,
    buffer = nil,
    silent = true,
    noremap = true,
    nowait = true,
  })
end

