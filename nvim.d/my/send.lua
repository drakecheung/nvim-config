local M = {}

local last_line = ""

M.run_shell = function(cmd)
  local handle = io.popen(cmd)
  local output = handle:read("*a")
  handle:close()
  return output
end

M.send_line_to_pane = function(text, pane)
  if pane == "" then
    vim.notify("Target pane not found", "error")
    return
  end
  local cb = io.popen("tmux load-buffer -", "w")
  cb:write(text)
  cb:close()
  M.run_shell("tmux paste-buffer -t " .. pane)
end

M.send_line_to_prev_pane = function(line)
  local pane = M.run_shell("tmux list-panes | grep active -B1 | head -n1"):gsub(": .*", "")
  M.send_line_to_pane(line, pane)
end

M.send_line_to_next_pane = function(line)
  local pane = M.run_shell("tmux list-panes | grep active -A1 | sed -n 2p"):gsub(": .*", "")
  M.send_line_to_pane(line, pane)
end

M.send_line_to_next_or_prev_pane = function(line)
  if _G.console_pane_flag == "-b" then
    M.send_line_to_prev_pane(line)
  else
    local pane = M.run_shell("tmux list-panes | grep active -A1 | sed -n 2p"):gsub(": .*", "")
    if pane == "" then
      M.send_line_to_prev_pane(line)
    else
      M.send_line_to_pane(line, pane)
    end
  end
end

M.send_current_line = function(dir)
  local line = vim.api.nvim_get_current_line() .. "\n"
  if (dir or "--") == "--" then
    M.send_line_to_next_or_prev_pane(line)
  elseif dir == "next" then
    M.send_line_to_next_pane(line)
  else
    M.send_line_to_prev_pane(line)
  end
end

M.send_last_line = function()
  if last_line == "" then
    vim.notify("Last line not found", "error")
    return
  end
  M.send_line_to_next_pane(last_line)
end

M.send_highlighted_lines = function(dir)
  vim.cmd([[normal "ay]])
  local cmd = vim.fn.getreg("a")
  if (dir or "--") == "--" then
    M.send_line_to_next_or_prev_pane(cmd)
  elseif dir == "next" then
    M.send_line_to_next_pane(cmd)
  else
    M.send_line_to_prev_pane(cmd)
  end
end

M.yank_highlighted_lines = function()
  vim.cmd([[normal "ay]])
  local lines = vim.fn.getreg("a")
  local cb = io.popen("xclip -selection clipboard", "w")
  cb:write(lines)
  cb:close()
end

M.search_cell_edge = function(flag)
  local l = vim.fn.search("^$", flag .. "W")
  local ind = vim.fn.indent(l + 1)
  if ind > 0 and l > 0 then
    return M.search_cell_edge(flag)
  else
    return l
  end
end

M.get_current_cell = function()
  local v = vim.fn.winsaveview()
  local sl = M.search_cell_edge("b")
  local el = M.search_cell_edge("")
  vim.fn.winrestview(v)
  if el == 0 then
    el = vim.fn.line("$")
  end
  local lines_tbl = vim.fn.getline(sl, el)
  local lines = table.concat(lines_tbl, "\n") .. "\n"
  return lines:gsub("^\n", ""):gsub("\n\n$", "\n")
end

M.yank_current_cell = function()
  local lines = M.get_current_cell()
  local cb = io.popen("xclip -selection clipboard", "w")
  cb:write(lines)
  cb:close()
end

-- send a cell like jupyter, cell is separated by empty lines
M.send_current_cell = function(dir)
  local cmd = M.get_current_cell()
  if (dir or "next") == "next" then
    M.send_line_to_next_pane(cmd)
  else
    M.send_line_to_prev_pane(cmd)
  end
end

M.run_popup = function(cmd)
  local cwd = vim.fn.getcwd()
  local fullcmd = "cd " .. cwd .. "; [ -f .envrc ] && source .envrc; " .. cmd
  M.run_shell("tmux popup -E bash -ic '" .. fullcmd .. "'")
end

return M
