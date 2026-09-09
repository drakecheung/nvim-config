#!/usr/bin/env bash
#
# tmux-panes.sh — single source of truth for reading & manipulating panes.
#
# Every toggle script (nvim / db / applogs / opencode / focus / sidebars)
# sources this library instead of hand-rolling its own `tmux list-panes`
# guessing. The goal: no script invents its own idea of "what's in this
# window" or "which side a pane lives on".
#
# ── Canonical pane model ──────────────────────────────────────────
# Each pane has a *type*, derived from its spawned command, and a *side*
# (left / right / center), read from tmux's actual geometry, NOT guessed.
#
# type → default spawn side (a preference for NEW panes; can be overridden):
#   nvim     → left
#   applogs  → left
#   db       → left
#   opencode → right
#   sidebars → dynamic (center-relative)
#   unknown  → left (fallback)
#
# void naming is unified:  void_win_<#{window_id}>_<type>
#   (replaces the historical opencode_void / ${type}_void / focus_void /
#    sidebar_void / unknown_void zoo). Keyed on window_id — NOT window name
#    (#W is manual) and NOT window index (#I reorders) — so a void survives
#    rename + window reorder and is always found → no duplicate spawns.
#
# ── Public functions ──────────────────────────────────────────────
#   pane_lib::detect_type <command>        → echoes type string
#   pane_lib::spawn_side <type>            → echoes "left"|"right"
#   pane_lib::get_window_state             → fills global WIN_STATE_* vars
#   pane_lib::toggle_pane <type> <cmd> [size] [workdir]
#   pane_lib::void_name <type>             → echoes "${win}_void_${type}"
#   pane_lib::stash <type> <pane_id>
#   pane_lib::restore <type>
#
# ── Focus-mode awareness ──────────────────────────────────────────
# If focus spacers exist (@focus_left/@focus_right), any side-pane toggle
# must first exit focus mode so the spacer panes don't get orphaned.

# ══ detect_type: classify a pane by its TOGGLE marker, not by what it runs ═
# Rule: NO marker → "main" (the protected work pane). Only a pane spawned by a
# toggle (echo left-<type> marker) is a companion and thus togglable.
# opencode is the ONE exception: it is always a companion, so a marker-less
# pane that is RUNNING opencode is still recognised as the opencode companion.
pane_lib::detect_type() {
  local cmd="${1:-}" cur="${2:-}"
  case "$cmd" in
    *left-nvim*|*nvim*)         echo "nvim" ;;
    *left-applogs*|*applogs*)   echo "applogs" ;;
    *left-db*|*db*)             echo "db" ;;
    *left-opencode*|*opencode*) echo "opencode" ;;
    *)
      # marker-less → recognize by the RUNNING command
      case "$cur" in
        nvim*)         echo "nvim" ;;
        opencode*)     echo "opencode" ;;
        docker*|psql*) echo "db" ;;
        *)             echo "main" ;;
      esac ;;
  esac
}

# ══ spawn_side: default side for a NEW pane of this type ═══════════
pane_lib::spawn_side() {
  case "${1:-}" in
    opencode) echo "right" ;;
    *)        echo "left" ;;
  esac
}

# ══ void_name: unified void session name for a type ═══════════════
pane_lib::void_name() {
  local type="${1:-unknown}" wid="${2:-}"
  if [[ -z "$wid" ]]; then
    wid=$(tmux display-message -p '#{window_id}')
  fi
  echo "void_win_${wid}_${type}"
}

# ══ focus_mode: exit focus spacers before touching side panes ═══════
pane_lib::exit_focus() {
  local target="${1:-}"
  local t_flag=""
  [[ -n "$target" ]] && t_flag="-t $target"

  local focus_left focus_right
  focus_left=$(tmux show-option $t_flag -wqv @focus_left 2>/dev/null)
  focus_right=$(tmux show-option $t_flag -wqv @focus_right 2>/dev/null)
  if [[ -n "$focus_left" && -n "$focus_right" ]]; then
    # kill spacer panes
    [[ -n "$focus_left" ]]  && tmux kill-pane -t "$focus_left"  2>/dev/null
    [[ -n "$focus_right" ]] && tmux kill-pane -t "$focus_right" 2>/dev/null
    tmux set-option $t_flag -wu @focus_left  2>/dev/null
    tmux set-option $t_flag -wu @focus_right 2>/dev/null
    # restore any panes stashed in the unified focus void
    local vw vname
    vname=$(pane_lib::void_name "focus" "$target")
    if tmux has-session -t "$vname" 2>/dev/null; then
      while vw=$(tmux list-windows -t "$vname" -F '#I' 2>/dev/null | head -n1); [[ -n "$vw" ]]; do
        tmux join-pane -d -h -s "${vname}:${vw}" $t_flag 2>/dev/null || break
      done
      tmux kill-session -t "$vname" 2>/dev/null
    fi
  fi
}

# ══ stash: hide a pane into its type void ═══════════════════════════
pane_lib::stash() {
  local type="$1" pane_id="$2" wid="${3:-}"
  local vname
  vname=$(pane_lib::void_name "$type" "$wid")
  tmux kill-session -t "$vname" 2>/dev/null || true
  tmux new-session -d -s "$vname"
  tmux break-pane -s "$pane_id" -d -t "$vname"
  tmux kill-window -t "${vname}:0" 2>/dev/null || true
}

# ══ restore: bring a type's void back into the window ═══════════════
# Returns 0 if something was restored, 1 if void was empty/absent.
pane_lib::restore() {
  local type="$1" size="${2:-35%}" wid="${3:-}"
  local vname vw side flag
  vname=$(pane_lib::void_name "$type" "$wid")
  tmux has-session -t "$vname" 2>/dev/null || return 1
  vw=$(tmux list-windows -t "$vname" -F '#I' | head -n1)
  [[ -z "$vw" ]] && { tmux kill-session -t "$vname" 2>/dev/null || true; return 1; }

  if [[ -z "$wid" ]]; then
    wid=$(tmux display-message -p '#{window_id}')
  fi

  side=$(pane_lib::spawn_side "$type")
  if [[ "$side" == "left" ]]; then
    flag="-hb"
  else
    flag="-h"
  fi

  # NOTE: join-pane does NOT accept -P/-F (unlike split-window).
  # Use -l size flag to restore proper geometry.
  if tmux join-pane -l "$size" $flag -s "${vname}:${vw}" -t "${wid}" 2>/dev/null; then
    tmux kill-session -t "$vname" 2>/dev/null || true
    return 0
  fi
  tmux kill-session -t "$vname" 2>/dev/null || true
  return 1
}

# ══ spawn: split a new pane on the type's side, then lock its size ═══
pane_lib::spawn() {
  local type="$1" cmd="$2" size="${3:-35%}" workdir="${4:-}" wid="${5:-}"
  local side flag
  side=$(pane_lib::spawn_side "$type")
  if [[ "$side" == "left" ]]; then
    flag="-hb"   # horizontal + behind → left
  else
    flag="-h"    # horizontal → right
  fi

  local t_flag=""
  [[ -n "$wid" ]] && t_flag="-t $wid"

  local pane_id
  if [[ -n "$workdir" && -d "$workdir" ]]; then
    pane_id=$(tmux split-window $flag $t_flag -l "$size" -c "$workdir" -PF '#D' \
      "echo left-${type} > /dev/null; ${cmd}")
  else
    pane_id=$(tmux split-window $flag $t_flag -l "$size" -PF '#D' \
      "echo left-${type} > /dev/null; ${cmd}")
  fi

  # Lock size (tmux may reflow after split).
  sleep 0.1
  [[ -n "$pane_id" ]] && tmux resize-pane -t "$pane_id" -x "$size" 2>/dev/null
  echo "$pane_id"
}

# ══ helper: spawn a fresh shell pane (ALWAYS horizontal, never vertical) ══
pane_lib::spawn_shell() {
  local workdir="${1:-}" target="${2:-}"
  local t_flag=""
  [[ -n "$target" ]] && t_flag="-t $target"

  if [[ -z "$workdir" || ! -d "$workdir" ]]; then
    workdir=$(tmux display-message $t_flag -p '#{pane_current_path}' 2>/dev/null)
  fi
  [[ -z "$workdir" || ! -d "$workdir" ]] && workdir="$HOME"
  # Always -h so it NEVER splits vertically (top/bottom)
  tmux split-window -h -d $t_flag -c "$workdir" "${SHELL:-/bin/zsh}" 2>/dev/null
}

# ══ helper: replace a pane's content with a tool (fullscreen, no split) ══
pane_lib::respawn_tool() {
  local pane_id="$1" type="$2" cmd="$3" workdir="${4:-}"
  if [[ -z "$workdir" || ! -d "$workdir" ]]; then
    workdir=$(tmux display-message -p -t "$pane_id" '#{pane_current_path}' 2>/dev/null)
  fi
  [[ -z "$workdir" || ! -d "$workdir" ]] && workdir="$HOME"
  local full_cmd="echo left-${type} > /dev/null; ${cmd}"
  tmux respawn-pane -k -c "$workdir" -t "$pane_id" "$full_cmd" 2>/dev/null
}

# ══ helper: is a type safe to FULLSCREEN over a shell? ═══════════════
pane_lib::fullscreen_eligible() {
  case "${1:-}" in
    nvim|opencode) return 0 ;;
    *) return 1 ;;
  esac
}

# ══ toggle_pane: single source of truth for toggling side/fullscreen tools ══
# Architecture:
#   Left tools (35%):  nvim, db, applogs (one at a time on left)
#   Right tools (60%): opencode (independent of left tools)
#   Base/main:         user's shell or fullscreen editor
#
# Guarantees:
#   1. Zero destroyed windows: break-pane is never called on the only pane.
#   2. Zero vertical splits: all splits are horizontal (-h).
#   3. Zero stdout leak: no -PF output in run-shell context.
#   4. Complete isolation: toggling left tools never touches right opencode.
pane_lib::toggle_pane() {
  local type="$1" spawn_cmd="$2" size="${3:-35%}" workdir="${4:-}" target="${5:-}"

  local t_flag=""
  [[ -n "$target" ]] && t_flag="-t $target"

  local cur_win
  cur_win=$(tmux display-message $t_flag -p '#{window_id}')

  pane_lib::exit_focus "$cur_win"

  # ── 1. Scan window panes ─────────────────────────────────────────
  local total_panes=0
  local my_pane=""
  local left_pane=""
  local left_type=""
  local right_pane=""
  local right_type=""
  local single_pane_id=""
  local single_pane_type=""

  local id pleft cmd cur ptype
  while IFS='|' read -r id pleft cmd cur; do
    [[ -z "$id" ]] && continue
    total_panes=$((total_panes + 1))
    single_pane_id="$id"
    ptype=$(pane_lib::detect_type "$cmd" "$cur")
    single_pane_type="$ptype"

    if [[ "$ptype" == "$type" ]]; then
      my_pane="$id"
    fi

    if [[ "$pleft" -eq 0 ]]; then
      left_pane="$id"
      left_type="$ptype"
    else
      right_pane="$id"
      right_type="$ptype"
    fi
  done < <(tmux list-panes -t "$cur_win" -F '#{pane_id}|#{pane_left}|#{pane_start_command}|#{pane_current_command}')

  # ── 2. CASE 1: My tool IS visible → TOGGLE OFF ──────────────────
  if [[ -n "$my_pane" ]]; then
    if [[ $total_panes -le 1 ]]; then
      # Only pane in window: must spawn a shell before stashing so window never dies
      local shell_cwd
      shell_cwd=$(tmux display-message -p -t "$my_pane" '#{pane_current_path}')
      pane_lib::spawn_shell "$shell_cwd" "$cur_win" >/dev/null
      pane_lib::stash "$type" "$my_pane" "$cur_win"
    else
      # Multiple panes on screen: simply stash, other pane(s) automatically expand
      pane_lib::stash "$type" "$my_pane" "$cur_win"
    fi
    return
  fi

  # ── 3. CASE 2: My tool NOT visible → TOGGLE ON ──────────────────
  local side
  side=$(pane_lib::spawn_side "$type")

  # If multi-pane, swap competing companion on the target side
  if [[ $total_panes -ge 2 ]]; then
    if [[ "$side" == "left" && -n "$left_pane" ]]; then
      pane_lib::stash "$left_type" "$left_pane" "$cur_win"
    elif [[ "$side" == "right" && -n "$right_pane" ]]; then
      pane_lib::stash "$right_type" "$right_pane" "$cur_win"
    fi
  fi

  # Single plain shell → Fullscreen eligible?
  if [[ $total_panes -le 1 && "$single_pane_type" == "main" ]]; then
    if pane_lib::fullscreen_eligible "$type"; then
      local vname
      vname=$(pane_lib::void_name "$type" "$cur_win")
      if tmux has-session -t "$vname" 2>/dev/null; then
        if pane_lib::restore "$type" "$size" "$cur_win"; then
          tmux kill-pane -t "$single_pane_id" 2>/dev/null
          return
        fi
      else
        pane_lib::respawn_tool "$single_pane_id" "$type" "$spawn_cmd" "$workdir"
        return
      fi
    fi
  fi

  # Companion spawn/restore alongside existing pane(s)
  local vname
  vname=$(pane_lib::void_name "$type" "$cur_win")
  if tmux has-session -t "$vname" 2>/dev/null; then
    pane_lib::restore "$type" "$size" "$cur_win"
    return
  fi

  pane_lib::spawn "$type" "$spawn_cmd" "$size" "$workdir" "$cur_win" >/dev/null
}
