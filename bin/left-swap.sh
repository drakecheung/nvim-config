# left-swap.sh — swap left pane content using type-specific void stash/restore
#
# Three basic tmux operations, no hacks:
#   SPAWN:   split-window -hb + resize-pane
#   STASH:   break-pane → type void
#   RESTORE: join-pane + resize-pane

left_swap() {
  local type="$1" spawn_cmd="$2" size="${3:-35%}" workdir="${4:-}"
  local window pane_count
  window=$(tmux display-message -p '#W')
  pane_count=$(tmux list-panes -F '#D' | wc -l)
  local my_void="${window}_${type}_void"

  # ── detect leftmost pane type ──────────────────────────────────
  left_info() {
    tmux list-panes -F '#{pane_id} #{pane_left} #{pane_start_command}' \
      | sort -nk2 | head -n1 \
      | awk '{
        id=$1; $1=$2=""; sub(/^ +/,""); cmd=$0
        if      (cmd~/left-nvim/) print id,"nvim"
        else if (cmd~/left-logs/) print id,"logs"
        else if (cmd~/left-db/)   print id,"db"
        else if (cmd~/ nvim/)     print id,"nvim"
        else                      print id,""
      }'
  }

  # ── spawn: split-window left + lock size ───────────────────────
  do_spawn() {
    if [[ -n "$workdir" ]]; then
      tmux split-window -hb -l "$size" -c "$workdir" \
        "echo left-${type} > /dev/null; ${spawn_cmd}"
    else
      tmux split-window -hb -l "$size" \
        "echo left-${type} > /dev/null; ${spawn_cmd}"
    fi
    sleep 0.1
    local lp
    lp=$(tmux list-panes -F '#{pane_id} #{pane_left}' | sort -nk2 | head -n1 | awk '{print $1}')
    [[ -n "$lp" ]] && tmux resize-pane -t "$lp" -x "$size"
  }

  # ── stash: break-pane → void ───────────────────────────────────
  do_stash()   {
    local pid="$1" vname="$2"
    tmux kill-session -t "$vname" 2>/dev/null
    tmux new-session -d -s "$vname"
    tmux break-pane -s "$pid" -d -t "$vname"
    tmux kill-window -t "${vname}:0" 2>/dev/null
  }

  # ── restore: kill-left, join-pane from void, resize ────────────
  do_restore() {
    local vname="$1" oldleft="$2"
    tmux has-session -t "$vname" 2>/dev/null || return 1
    local vw
    vw=$(tmux list-windows -t "$vname" -F '#I' | head -n1)
    [[ -z "$vw" ]] && { tmux kill-session -t "$vname" 2>/dev/null; return 1; }
    [[ -n "$oldleft" && $pane_count -ge 2 ]] && tmux kill-pane -t "$oldleft" 2>/dev/null
    local focus; focus=$(tmux display-message -p '#D')
    tmux join-pane -h -b -s "${vname}:${vw}"
    tmux resize-pane -x "$size"
    tmux select-pane -t "$focus"
    tmux kill-session -t "$vname" 2>/dev/null
  }

  # ═══════════════════════════════════════════════════════════════
  # State machine
  # ═══════════════════════════════════════════════════════════════

  if [[ $pane_count -eq 1 ]]; then
    do_restore "$my_void" "" || do_spawn
    return
  fi

  local leftmost left_type lp
  read -r leftmost left_type < <(left_info)

  if [[ "$left_type" == "$type" ]]; then
    do_stash "$leftmost" "$my_void"

  elif [[ -n "$left_type" ]]; then
    local ovoid="${window}_${left_type}_void"
    if ! do_restore "$my_void" "$leftmost"; then
      do_spawn
    fi
    do_stash "$leftmost" "$ovoid" 2>/dev/null
    # Re-lock size: tmux may reflow after break-pane
    sleep 0.1
    lp=$(tmux list-panes -F '#{pane_id} #{pane_left}' | sort -nk2 | head -n1 | awk '{print $1}')
    [[ -n "$lp" ]] && tmux resize-pane -t "$lp" -x "$size"

  else
    if ! do_restore "$my_void" "$leftmost"; then
      [[ -n "$leftmost" ]] && tmux respawn-pane -k -t "$leftmost" \
        "echo left-${type} > /dev/null; ${spawn_cmd}" 2>/dev/null || do_spawn
    fi
    [[ -n "$leftmost" ]] && do_stash "$leftmost" "${window}_unknown_void" 2>/dev/null
  fi
}
