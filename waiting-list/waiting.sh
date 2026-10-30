#!/usr/bin/env bash
# The "★ waiting" space lists non-worker agents (no $fleet_wkr) that are done or blocked as $w1..$w5 sidebar tokens.
# Its own pane runs `watch`: the same list with numbers, a digit focuses that agent, and every tick refreshes the tokens.
set -uo pipefail
h=${HERDR_BIN_PATH:-$HOME/.local/bin/herdr}
label="★ waiting"
max=5

widget() { "$h" workspace list | jq -r --arg l "$label" '[.result.workspaces[] | select(.label == $l)][0].workspace_id // empty'; }

waiting() {
  "$h" api snapshot | jq -r '
    (.result.snapshot // .result) as $s
    | ($s.workspaces | map({(.workspace_id): .label}) | add) as $ws
    | ($s.tabs | map({(.tab_id): .label}) | add) as $tabs
    | $s.agents[]
    | select(.tokens.fleet_wkr == null and (.agent_status == "done" or .agent_status == "blocked"))
    | [.pane_id, ((if .agent_status == "blocked" then "?" else "✓" end)
        + (if .tokens.fleet_mgr then " ★ " else " " end) + $ws[.workspace_id] + " · " + $tabs[.tab_id])]
    | join("\u001f")'
}

update() {
  local ws=${1:-$(widget)} args=() i=0 pane text
  [ -n "$ws" ] || return 0
  while IFS=$'\x1f' read -r pane text; do
    [ -n "$pane" ] || continue
    i=$((i + 1))
    [ "$i" -le "$max" ] && args+=(--token "w$i=$text")
  done <<<"$(waiting)"
  [ "$i" -gt "$max" ] && args[2 * max - 1]="w$max=+$((i - max + 1)) more"
  for ((j = i + 1; j <= max; j++)); do args+=(--clear-token "w$j"); done
  "$h" workspace report-metadata "$ws" --source waiting-list \
    --seq "$(perl -MTime::HiRes=time -e 'printf "%d", time * 1000')" "${args[@]}" >/dev/null
}

watch() {
  local ws i panes key pane text
  while :; do
    ws=$(widget); update "$ws"
    printf '\033[H\033[2J%s  (%s)  press a number to jump\n' "$label" "$(date +%H:%M:%S)"
    i=0; panes=()
    while IFS=$'\x1f' read -r pane text; do
      [ -n "$pane" ] || continue
      i=$((i + 1)); panes[i]=$pane
      printf '%d  %s\n' "$i" "$text"
    done <<<"$(waiting)"
    [ "$i" -gt 0 ] || echo "   nobody"
    if read -r -s -n 1 -t 2 key && [[ $key =~ ^[1-9]$ ]] && [ -n "${panes[key]:-}" ]; then
      "$h" agent focus "${panes[key]}" >/dev/null
    fi
  done
}

ensure() {
  local ws pane sock=${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}
  ws=$(widget)
  [ -n "$ws" ] || ws=$("$h" workspace create --cwd "$HOME" --label "$label" --no-focus | jq -r .result.workspace.workspace_id)
  printf '{"id":"waiting","method":"workspace.move","params":{"workspace_id":"%s","insert_index":0}}\n' "$ws" \
    | perl -e 'alarm 3; exec @ARGV' nc -U "$sock" >/dev/null
  pane=$("$h" pane list --workspace "$ws" | jq -r '.result.panes[0].pane_id')
  "$h" pane process-info --pane "$pane" | grep -q 'waiting.sh' || "$h" pane run "$pane" "bash $(cd "$(dirname "$0")" && pwd)/waiting.sh watch" >/dev/null
  update "$ws"
}

"${1:-update}"
