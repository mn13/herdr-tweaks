#!/usr/bin/env bash
# Only a default-numbered first tab is renamed, so a name given at creation stays.
[ "$(jq -r .tab_label <<<"$HERDR_PLUGIN_CONTEXT_JSON")" = 1 ] || exit 0
"$HERDR_BIN_PATH" tab rename "$HERDR_TAB_ID" mgr >/dev/null
# The UI and the API both report invocation_source=api; only a space opened in focus asks for a name.
[ "$(jq -r .data.workspace.focused <<<"$HERDR_PLUGIN_EVENT_JSON")" = true ] || exit 0
exec "$HERDR_BIN_PATH" plugin pane open --plugin "$HERDR_PLUGIN_ID" --entrypoint name-tab \
  --env "FIRST_TAB_ID=$HERDR_TAB_ID" --env "HERDR=$HERDR_BIN_PATH"
