# herdr-tweaks

Small [herdr](https://herdr.dev) add-ons for running a fleet of coding agents: managers that hand work to workers, each in its own space.

| Piece | What it does |
| --- | --- |
| [`first-tab-mgr`](first-tab-mgr) | A new space asks for its first tab's name, prefilled with `mgr`. Spaces created over the API without focus get `mgr` silently. |
| [`waiting-list`](waiting-list) | Keeps a `★ waiting` space at the top of the spaces sidebar that lists every non-worker agent that is done or blocked. |
| [`fleet-role`](fleet-role) | Agent hook that tags each pane as a manager (`★ mgr`) or a worker (`↳ wkr`) in the agents sidebar. `waiting-list` uses the worker tag. |

Requires herdr 0.9.4 or newer, `jq`, `bash`, `zsh` (the first-tab prompt), and `perl` + `nc` (moving the waiting space to the top).

## Install

```sh
herdr plugin install mn13/herdr-tweaks/first-tab-mgr
herdr plugin install mn13/herdr-tweaks/waiting-list
```

Merge [`config.example.toml`](config.example.toml) into `~/.config/herdr/config.toml` and run `herdr server reload-config`.

`waiting-list` creates its space from a startup hook, so it appears on the next herdr server start. To create it now, run its `ensure` step once:

```sh
cd "$(herdr plugin list | jq -r '.result.plugins[] | select(.plugin_id == "mn13.waiting-list") | .plugin_root')"
bash waiting.sh ensure
```

### fleet-role hook

The hook uses the Claude Code hooks format.

1. Copy [`fleet-role/herdr-fleet-role.sh`](fleet-role/herdr-fleet-role.sh) to `~/.claude/hooks/`.
2. Add the entries from [`fleet-role/settings.json`](fleet-role/settings.json) to `~/.claude/settings.json`.

A session is a **worker** when its working directory holds a `.fleet-brief.md`, and a **manager** when it runs `herdr agent prompt|rename|start` from anywhere else. A new or cleared session drops both tags.

## How `waiting-list` works

- The waiting agents are written as workspace metadata tokens `$w1`..`$w5` on the `★ waiting` space. The spaces sidebar renders them as rows, and a row with no value disappears, so other spaces look unchanged.
- Each row reads `✓` (done) or `?` (blocked), `★` for a manager, then the space and tab name. A sixth agent and beyond fold into `+N more`.
- The list refreshes on `pane.agent_status_changed` and `pane.closed`, and every 2 s from the space's own pane.
- Clicking the space opens the full numbered list; press a digit to jump to that agent.
- The space is a real space: closing it lasts until the next server start, when the startup hook brings it back. To remove it for good, uninstall the plugin, drop the `[ui.sidebar.spaces]` block, and close the space.

## License

MIT
