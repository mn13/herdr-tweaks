#!/bin/sh
# Tags this herdr pane as a fleet manager or worker; [ui.sidebar.agents] in
# ~/.config/herdr/config.toml colours the $fleet_mgr / $fleet_wkr tokens.

[ "${HERDR_ENV:-}" = 1 ] && [ -n "${HERDR_PANE_ID:-}" ] || exit 0
input=$(cat)

tag() {
  "${HERDR_BIN_PATH:-herdr}" pane report-metadata "$HERDR_PANE_ID" --source fleet-role "$@" >/dev/null 2>&1 || true
}
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

case "${1:-}" in
  start)
    tag --clear-token fleet_mgr --clear-token fleet_wkr
    ;;
  prompt)
    [ -f "$cwd/.fleet-brief.md" ] && tag --token 'fleet_wkr=↳ wkr' --clear-token fleet_mgr
    ;;
  bash)
    case "$input" in *"herdr agent "*) ;; *) exit 0 ;; esac
    [ -f "$cwd/.fleet-brief.md" ] && exit 0
    printf '%s' "$input" | jq -e '.tool_input.command | test("herdr agent (prompt|rename|start) ")' >/dev/null &&
      tag --token 'fleet_mgr=★ mgr' --clear-token fleet_wkr
    ;;
esac
exit 0
