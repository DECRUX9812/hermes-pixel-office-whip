# Pixel Office — the live agent office for Hermes

Watch every Hermes agent work — main sessions, delegate_task subagents,
cron sessions, all of them — as live cards in one tiny office. And when
they get lazy, **crack the whip**. From anywhere.

```
┌ PIXEL OFFICE ──────────────────────────────────────────┐
│ ● telegram a3f9c2   working   terminal      12s ago    │
│ ● cli 88d01e        thinking                 3s ago    │
│ ○ sub build-tests   done                  2m ago  [sub]│
│                                                        │
│ 2 agents · 7 whips   💥 "Less planning, more committing."
└────────────────────────────────────────────────────────┘
```

## Why it exists

Hermes runs agents everywhere — CLI, Telegram/Discord gateway, cron,
delegated subagents — and you normally can't see them at once. Pixel
Office folds every process's activity into **one shared view**, because
state lives in a plain event file (`~/.hermes/pixel-office/events.jsonl`),
not in any single process's memory.

## Install (drop-in, no core edits)

```bash
git clone https://github.com/DECRUX9812/hermes-pixel-office-whip.git
cd hermes-pixel-office-whip
./install.sh          # copies to ~/.hermes/plugins + desktop + TUI dirs
systemctl --user restart hermes-gateway   # or restart hermes
```

Requires: Python 3.10+, Hermes Agent. Zero extra dependencies.

Optional config (`~/.hermes/config.yaml`):

```yaml
plugins:
  enabled:
    - pixel-office
  entries:
    pixel-office:
      port: 8113      # office web page port
```

## Surfaces — the whip works everywhere

| Surface | How |
|---|---|
| **Web page** | open `http://127.0.0.1:8113` — live cards + big CRACK button |
| **Slash command** | `/whip [target]` in any CLI/gateway/messaging session |
| **Terminal** | `hermes office` · `hermes office whip` · `hermes office url` |
| **Desktop app** | "Pixel Office" pane (bottom dock) with a CRACK THE WHIP button |
| **TUI** | `/office` docks a live card above the status bar |

Every surface reads the same state and every whip lands in the same event
log, so a crack from Discord shows up on the web page instantly.

## Architecture (deliberately boring)

1. **Hooks are observers.** Eight hooks (`session_start/end`, `tool
   start/end`, `subagent start/stop`, `approval request/response`) append
   one JSON line to the event file. O(1), wrapped in try/except, never
   blocks or transforms the agent loop.
2. **One HTTP thread.** Starts lazily on first event, serves the page +
   `GET /state` + `POST /whip` + `GET /healthz`. If the port is already
   bound by a healthy office (another Hermes process), this process just
   feeds events. Multi-process safe by construction.
3. **State is folded from the log.** `/state` re-reads the JSONL and folds
   it into a snapshot — no long-lived in-memory state to drift. Log is
   trimmed at ~512 KB.

Nothing touches the conversation, the prompt cache, or tool results.

## Layout

```
plugin.yaml            # manifest + hooks
__init__.py            # hooks, event log, state folding, HTTP, whip, commands
web/index.html         # the entire frontend (self-contained, no deps)
dashboard/             # FastAPI routes for the desktop pane (/api/plugins/…)
desktop/plugin.js      # desktop-app pane (plugin-sdk, jsx calls)
tui-widgets/office.mjs # TUI dock widget
tests/                 # pytest — stdlib + pytest only
install.sh             # copies everything into ~/.hermes/
```

## Uninstall

```bash
rm -rf ~/.hermes/plugins/pixel-office \
       ~/.hermes/desktop-plugins/pixel-office \
       ~/.hermes/tui-widgets/office.mjs \
       ~/.hermes/pixel-office
```

Then remove `pixel-office` from `plugins.enabled` in config.yaml.

## License

MIT.
