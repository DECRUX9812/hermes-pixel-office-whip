# Hermes Pixel Office — Whip Edition ☤🐴

A pixel-art virtual office for [Hermes Agent](https://github.com/NousResearch/hermes-agent) —
every agent session and every `delegate_task` subagent becomes an animated
pixel character at a desk. Watch tools fire, subagents spawn and finish, and
approval requests flag you visually, live in your browser or in VS Code.

Hermes' answer to "Pixel Agents" for Claude Code.

This Whip Edition is maintained by **Ritesh Patel** and adds a harmless,
viewer-only whip interaction to
[Teknium's original Hermes Pixel Office](https://github.com/teknium1/hermes-pixel-office).
The agent runtime and lifecycle integration remain unchanged.

![office](screenshot.png)

Companion VS Code extension: [hermes-pixel-office-vscode](https://github.com/teknium1/hermes-pixel-office-vscode)
(this plugin works standalone in any browser — the extension is optional).

## What you'll see

- One character per Hermes session (CLI, Telegram, Discord, cron, ...) —
  characters walk in through the door, sit at a desk, and walk out when the
  session ends
- Gold-collared characters are `delegate_task` subagents, labeled by goal
- Activity animations: typing (`write_file`/`patch`), reading a book
  (`read_file`/`search_files`), browsing (web tools), terminal work (green
  monitor flicker), delegating (pointing)
- Dangerous-command approvals: red "!" speech bubble + "needs input!" +
  header counter ("N waiting!")
- Optional sound: chime when an agent needs approval or a subagent finishes
  (♪ toggle in the header, off by default, persists)
- Harmless **whip mode**: click `🐴 whip`, then click any seated agent to make
  the pixel character react to a full wind-up → snap → recoil animation with a
  leather handle, shaking rope, motion streaks, impact burst, jump, and reaction
  bubble. The sharp crack is synthesized locally with Web Audio. This is
  strictly visual/audio state — it sends no event, prompt, or command to Hermes.
- Optional **dark sarcastic voice reactions**: toggle `🗣 voice` to hear lines
  such as “The backlog demands another sacrifice.” The neural MP3 clips ship
  with the plugin and play on the viewing laptop, so they work in Hermes
  Desktop and over Tailscale even when the operating system has no TTS voices.
  A browser speech engine is retained only as a fallback.
- **Teknium patrol NPC**: an original pixel adaptation of the user's green-hair,
  red-visor character periodically leaves the executive corner, walks to an
  employee, performs the harmless cinematic whip, and returns home.
- **Nous Girl lounge NPC**: an original pixel adaptation of the user's
  purple-haired, white-jacket character chills beside the sofa with coffee and
  occasional heart animations while Teknium conducts “management.”
- Sessions from ALL Hermes processes on the machine share one office

Visual only: the plugin observes lifecycle hooks — it never blocks, vetoes,
or transforms anything, adds zero model-tool footprint, and does not touch
the prompt cache.

## Install

```bash
git clone https://github.com/DECRUX9812/hermes-pixel-office-whip ~/.hermes/plugins/pixel-office
hermes plugins enable pixel-office
```

Start a **new** Hermes session (plugins load at process start — an
already-running session won't pick it up), make the agent do anything, and
open:

    http://127.0.0.1:8113

Windows: same commands; the clone path is `%USERPROFILE%\.hermes\plugins\pixel-office`.

## VS Code

Install the [companion extension](https://github.com/teknium1/hermes-pixel-office-vscode)
and run **Hermes: Open Pixel Office** from the command palette. Same office,
rendered in a panel, plus a "+ agent" button that opens a terminal running
`hermes`.

## Configuration (optional)

`~/.hermes/config.yaml`:

```yaml
plugins:
  enabled:
    - pixel-office
  entries:
    pixel-office:
      port: 8113        # change if something else owns 8113
```

If you change the port, point the extension setting
`hermesPixelOffice.stateUrl` at the same port.

## Try it without any agents

```bash
python3 demo_feed.py
```

Fires synthetic sessions/subagents/approvals through the real plugin code
and serves the office — no Hermes install required (stdlib only).

## How it works

```
agents ──lifecycle hooks──▶ events.jsonl ──fold──▶ /state ──poll──▶ canvas office
```

Hook callbacks (`pre/post_tool_call`, `subagent_start/stop`,
`on_session_start/end`, `pre_approval_request`/`post_approval_response`)
append one JSON line each to `~/.hermes/pixel-office/events.jsonl` — O(1),
fail-open, microseconds. A daemon thread serves `web/index.html` (single
canvas page, sprites drawn in code, plus bundled audio) and `/state`, which
folds the log into the current office snapshot. The log auto-trims at 512 KB.

## Troubleshooting

- **"office unreachable" in the browser/extension** — check
  `hermes logs --level warning`. The plugin logs loudly when it can't bind
  its port, including a probe verdict telling you whether the squatter is
  another (healthy) office, a foreign app, or a dead listener such as a
  stale VS Code port-forward.
- **`curl http://127.0.0.1:8113/state` hangs instead of refusing** — a
  system proxy or a ghost VS Code port-forward is intercepting localhost.
  Try `curl --noproxy "*" ...`; check VS Code's Ports view and stop stale
  forwards (they can outlive the remote server they pointed at).
- **Plugin enabled but nothing happens** — plugins load at process start.
  Exit and relaunch `hermes`; `/new` inside an old process is not enough.
  Verify with `hermes logs --level info | grep pixel-office` (Windows:
  `findstr /i pixel-office`) — you should see "registered" at session start.
- **No `events.jsonl` appearing** — the same log now carries a WARNING line
  naming the exact exception if event writes fail.

## License

MIT
