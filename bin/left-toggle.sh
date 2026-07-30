# left-toggle.sh — simple left pane toggle (kill + replace, no void)
#
# Usage: left_toggle <type> <spawn_cmd> [size%] [workdir]
#
# Logic:
#   - My type on left?  → close (kill pane)
#   - Other type on left? → kill it, open mine
#   - Nothing on left?    → open mine

left_toggle() {
  local type="$1" spawn_cmd="$2" size="${3:-35%}" workdir="${4:-}"
  local pane_count

  # ── Focus-mode awareness: exit before toggling ────────────────────
  local focus_left was_focus
  focus_left=$(tmux show-option -wqv @focus_left 2>/dev/null)
  if [[ -n "$focus_left" ]]; then
    was_focus=true
    "$HOME/drake/nvim-config/bin/toggle-focus" exit
  fi

  pane_count=$(tmux list-panes -F '#D' | wc -l)

  # ── detect leftmost pane type ──────────────────────────────────
  local leftmost left_type
  if [[ $pane_count -ge 2 ]]; then
    read -r leftmost left_type < <(
      tmux list-panes -F '#{pane_id} #{pane_left} #{pane_start_command}' \
        | sort -nk2 | head -n1 \
        | awk '{
          id=$1; $1=$2=""; sub(/^ +/,""); cmd=$0
          if      (cmd~/left-nvim/) print id,"nvim"
          else if (cmd~/left-logs/) print id,"logs"
          else if (cmd~/left-db/)   print id,"db"
          else if (cmd~/ nvim|nvim /) print id,"nvim"
          else                      print id,""
        }'
    )
  fi

  # ── If my type is already visible → toggle off ─────────────────
  if [[ "$left_type" == "$type" ]]; then
    tmux kill-pane -t "$leftmost"
    # Re-enter focus mode if we exited it
    if [[ "$was_focus" == true ]]; then
      center=$(tmux show-option -wqv @focus_center 2>/dev/null)
      [[ -n "$center" ]] && tmux select-pane -t "$center" 2>/dev/null
      "$HOME/drake/nvim-config/bin/toggle-focus" enter
    fi
    return
  fi

  # ── If other type is visible → kill it first ────────────────────
  if [[ -n "$leftmost" ]]; then
    tmux kill-pane -t "$leftmost"
  fi

  # ── Open mine on the left ───────────────────────────────────────
  if [[ -n "$workdir" ]]; then
    tmux split-window -hb -l "$size" -c "$workdir" \
      "echo left-${type} > /dev/null; ${spawn_cmd}"
  else
    tmux split-window -hb -l "$size" \
      "echo left-${type} > /dev/null; ${spawn_cmd}"
  fi
  # Lock size
  sleep 0.1
  local lp
  lp=$(tmux list-panes -F '#{pane_id} #{pane_left}' | sort -nk2 | head -n1 | awk '{print $1}')
  [[ -n "$lp" ]] && tmux resize-pane -t "$lp" -x "$size"

  # Re-enter focus mode if we exited it
  if [[ "$was_focus" == true ]]; then
    center=$(tmux show-option -wqv @focus_center 2>/dev/null)
    [[ -n "$center" ]] && tmux select-pane -t "$center" 2>/dev/null
    "$HOME/drake/nvim-config/bin/toggle-focus" enter
  fi
}
