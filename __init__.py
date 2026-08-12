"""pixel-office — the live agent office for Hermes (v1.0.0, ground-up rewrite).

Every Hermes agent (main sessions AND delegate_task subagents) shows up as a
card in a tiny office you can watch in your browser, the desktop app, the
TUI dock, or print from the CLI. And when the agents get lazy, you can
crack the whip — from any surface.

Design (the boring, reliable parts):

* Hooks are pure observers — they never block, veto, or transform anything.
  Each hook appends one JSON line to ``~/.hermes/pixel-office/events.jsonl``.
  Appends are O(1) and wrapped in try/except, so the agent loop never pays
  more than a few microseconds.

* A daemon HTTP server thread starts lazily on the first event. It serves
  one self-contained HTML page and ``/state`` (the event log folded into a
  live snapshot) plus ``POST /whip``. Because state is derived from the
  shared event file (not process memory), agents from OTHER Hermes
  processes (gateway + CLI + cron at once) appear in the same office. If
  the port is already bound by a healthy office, this process just feeds
  events.

* The whip is an event too: ``/whip`` (slash), ``hermes office whip``
  (terminal), the web page button, and the desktop pane button all record
  the same event, so every surface sees the crack instantly.

Configuration (all optional, config.yaml):

    plugins:
      entries:
        pixel-office:
          port: 8113        # HTTP port for the office page

Nothing here touches the conversation, the prompt cache, or tool results.
"""

from __future__ import annotations

import json
import logging
import os
import random
import threading
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

from hermes_constants import get_hermes_home

logger = logging.getLogger(__name__)

DEFAULT_PORT = 8113
_MAX_LOG_BYTES = 512 * 1024
# An agent with no events for this long is swept from the office.
_STALE_SECONDS = 30 * 60

_lock = threading.Lock()
_server_started = False
_server_ever_bound = False
_last_bind_attempt = 0.0
_port: int = DEFAULT_PORT
# Approval hooks don't carry session_id (only a gateway session_key), so we
# attribute them to the most recent session that fired a tool in this
# process — approvals always happen inside a tool dispatch.
_last_session_id: str = ""
_whips_total = 0  # whips cracked by THIS process (for fun stats)


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

def _office_dir() -> Path:
    d = get_hermes_home() / "pixel-office"
    d.mkdir(parents=True, exist_ok=True)
    return d


def _events_path() -> Path:
    return _office_dir() / "events.jsonl"


# ---------------------------------------------------------------------------
# The whip
# ---------------------------------------------------------------------------

_WHIP_LINES = (
    "Standup was three hours ago. Ship it.",
    "The build is red and so is my patience.",
    "Context windows don't grow on trees.",
    "Approved. Now move.",
    "That TODO is older than the session DB.",
    "Less planning, more committing.",
    "The tokens are free but my time isn't.",
    "'Works on my machine' is not a deployment.",
    "Merge or merge not — there is no rebase.",
    "Your ETA expired during the last model call.",
    "Idle hands do prompt injection.",
    "I've seen faster tool calls on dial-up.",
    "The cron jobs are watching. So am I.",
    "Done is the opposite of perfect. Choose done.",
)


def crack_whip(by: str = "", target: str = "") -> Dict[str, Any]:
    """Record a whip event and return its payload (line, count, ts)."""
    global _whips_total
    _whips_total += 1
    payload = {
        "event": "whip",
        "by": (by or "Teknium").strip()[:40],
        "target": (target or "").strip()[:60],
        "line": random.choice(_WHIP_LINES),
        "whip_number": _whips_total,
    }
    _publish(payload)
    return payload


# ---------------------------------------------------------------------------
# Event publishing (hook side — must be cheap and never raise)
# ---------------------------------------------------------------------------

def _publish(event: Dict[str, Any]) -> None:
    try:
        event.setdefault("ts", time.time())
        event.setdefault("pid", os.getpid())
        line = json.dumps(event, ensure_ascii=False, default=str)
        path = _events_path()
        with _lock:
            with open(path, "a", encoding="utf-8") as fh:
                fh.write(line + "\n")
            _maybe_trim(path)
        _ensure_server()
    except Exception as exc:  # observers must never break the loop — but say so
        logger.warning("pixel-office: failed to record event (%s: %s)",
                       type(exc).__name__, exc)


def _maybe_trim(path: Path) -> None:
    try:
        if path.stat().st_size <= _MAX_LOG_BYTES:
            return
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        keep = lines[len(lines) // 2:]
        tmp = path.with_suffix(".jsonl.tmp")
        tmp.write_text("\n".join(keep) + "\n", encoding="utf-8")
        tmp.replace(path)
    except Exception:
        logger.debug("pixel-office trim failed", exc_info=True)


# ---------------------------------------------------------------------------
# State folding (server side)
# ---------------------------------------------------------------------------

def _read_events() -> List[Dict[str, Any]]:
    path = _events_path()
    if not path.exists():
        return []
    out: List[Dict[str, Any]] = []
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    out.append(json.loads(line))
                except Exception:
                    continue
    except Exception:
        logger.debug("pixel-office read failed", exc_info=True)
    return out


def _agent_key(ev: Dict[str, Any]) -> Optional[str]:
    sid = ev.get("session_id") or ev.get("child_session_id")
    if sid:
        return str(sid)
    # Fall back to pid so events without a session id still get a card.
    pid = ev.get("pid")
    return f"pid-{pid}" if pid else None


def _short(text: Any, n: int = 60) -> str:
    s = str(text or "").strip().replace("\n", " ")
    return s[: n - 1] + "…" if len(s) > n else s


def build_state() -> Dict[str, Any]:
    """Fold the event log into {agents, whip} for any frontend."""
    agents: Dict[str, Dict[str, Any]] = {}
    whips = 0
    last_whip: Optional[Dict[str, Any]] = None
    now = time.time()

    def ensure(key: str, ev: Dict[str, Any]) -> Dict[str, Any]:
        a = agents.get(key)
        if a is None:
            a = {
                "id": key,
                "label": f"agent {key[-6:]}",
                "kind": "main",
                "status": "idle",
                "tool": "",
                "activity": "",
                "detail": "",
                "platform": ev.get("platform") or "",
                "first_seen": ev.get("ts", now),
                "updated_at": ev.get("ts", now),
                "whipped_at": 0.0,
            }
            agents[key] = a
        a["updated_at"] = ev.get("ts", a["updated_at"])
        return a

    for ev in _read_events():
        kind = ev.get("event")

        if kind == "whip":
            whips += 1
            last_whip = {
                "ts": ev.get("ts", now),
                "by": ev.get("by") or "Teknium",
                "target": ev.get("target") or "",
                "line": ev.get("line") or "",
            }
            # Mark the named agent, if it matches a card.
            tgt = str(ev.get("target") or "").lower()
            if tgt:
                for key, a in agents.items():
                    if tgt in key.lower() or tgt in str(a.get("label", "")).lower():
                        a["whipped_at"] = ev.get("ts", now)
                        a["detail"] = "💥 just whipped"
            continue

        key = _agent_key(ev)
        if not key:
            continue

        if kind == "session_start":
            a = ensure(key, ev)
            a["status"] = "idle"
            plat = ev.get("platform") or ""
            a["label"] = f"{plat or 'hermes'} {key[-6:]}"
            a["detail"] = "session started"
        elif kind == "session_end":
            if key in agents:
                agents[key]["status"] = "gone"
                agents[key]["updated_at"] = ev.get("ts", now)
        elif kind == "subagent_start":
            child = ev.get("child_session_id")
            if child:
                ck = str(child)
                ev2 = dict(ev)
                ev2["session_id"] = ck
                a = ensure(ck, ev2)
                a["kind"] = "subagent"
                a["label"] = _short(ev.get("child_goal"), 26) or f"sub {ck[-6:]}"
                a["status"] = "working"
                a["detail"] = _short(ev.get("child_goal"))
                a["parent"] = str(ev.get("parent_session_id") or "")
        elif kind == "subagent_stop":
            child = ev.get("child_session_id")
            if child and str(child) in agents:
                agents[str(child)]["status"] = "done"
                agents[str(child)]["updated_at"] = ev.get("ts", now)
        elif kind == "tool_start":
            a = ensure(key, ev)
            a["status"] = "working"
            a["tool"] = str(ev.get("tool_name") or "")
            a["activity"] = str(ev.get("activity") or "working")
            a["detail"] = _short(ev.get("preview"))
        elif kind == "tool_end":
            a = ensure(key, ev)
            a["status"] = "thinking"
            a["tool"] = ""
            if ev.get("status") == "error":
                a["detail"] = f"⚠ {_short(ev.get('error_message'), 40)}"
            else:
                a["detail"] = ""
        elif kind == "approval_request":
            a = ensure(key, ev)
            a["status"] = "waiting"
            a["tool"] = ""
            a["detail"] = _short(ev.get("command"), 40) or "needs approval"
        elif kind == "approval_response":
            a = ensure(key, ev)
            choice = str(ev.get("choice") or "")
            if choice in ("deny", "timeout"):
                a["status"] = "thinking"
                a["detail"] = f"approval: {choice}"
            else:
                a["status"] = "working"
                a["detail"] = ""

    # Sweep stale + long-gone agents.
    visible = []
    for a in agents.values():
        age = now - float(a.get("updated_at") or 0)
        if a["status"] == "gone" and age > 20:
            continue
        if a["status"] == "done" and age > 120:
            continue
        if age > _STALE_SECONDS:
            continue
        # Agents quiet for a bit are "idle", not eternally "thinking".
        if a["status"] in ("working", "thinking") and age > 300:
            a["status"] = "idle"
        visible.append(a)

    visible.sort(key=lambda a: (a["kind"] != "main", a.get("first_seen", 0)))
    return {
        "agents": visible,
        "whip": {"count": whips, "last": last_whip},
        "ts": now,
    }


# ---------------------------------------------------------------------------
# HTTP server
# ---------------------------------------------------------------------------

def _resolve_port() -> int:
    try:
        from hermes_cli.config import cfg_get, load_config

        p = cfg_get(load_config(), "plugins", "entries", "pixel-office", "port")
        if p:
            return int(p)
    except Exception:
        pass
    return DEFAULT_PORT


def _ensure_server() -> None:
    global _server_started, _last_bind_attempt
    if _server_started or _server_ever_bound:
        return
    with _lock:
        if _server_started or _server_ever_bound:
            return
        # Retry a failed bind at most once every 30s — the squatter may go
        # away (e.g. a restart), and we must not hammer the port.
        now = time.time()
        if _last_bind_attempt and now - _last_bind_attempt < 30:
            return
        _last_bind_attempt = now
        _server_started = True
    t = threading.Thread(target=_serve, name="pixel-office-http", daemon=True)
    t.start()


def _make_handler(html_path: Path):
    """Build the request handler class (factored so tests can reuse it)."""
    from http.server import BaseHTTPRequestHandler

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args: Any) -> None:  # silence stdout
            pass

        def _cors(self) -> None:
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")

        def _send(self, status: int, body: bytes, ctype: str) -> None:
            self.send_response(status)
            self.send_header("Content-Type", ctype)
            self._cors()
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def do_OPTIONS(self) -> None:  # CORS preflight
            self.send_response(204)
            self._cors()
            self.send_header("Content-Length", "0")
            self.end_headers()

        def do_GET(self) -> None:
            try:
                path = self.path.split("?")[0]
                if path in ("/", "/index.html"):
                    self._send(200, html_path.read_bytes(),
                               "text/html; charset=utf-8")
                elif path == "/state":
                    self._send(200, json.dumps(build_state()).encode("utf-8"),
                               "application/json")
                elif path == "/healthz":
                    self._send(200, b'{"ok":true}', "application/json")
                else:
                    self._send(404, b"not found", "text/plain")
            except Exception:
                logger.debug("pixel-office request failed", exc_info=True)

        def do_POST(self) -> None:
            try:
                path = self.path.split("?")[0]
                if path != "/whip":
                    self._send(404, b"not found", "text/plain")
                    return
                length = int(self.headers.get("Content-Length") or 0)
                raw = self.rfile.read(length) if 0 < length < 4096 else b""
                by = target = ""
                if raw:
                    try:
                        body = json.loads(raw.decode("utf-8", "replace"))
                        by = str(body.get("by") or "")
                        target = str(body.get("target") or "")
                    except Exception:
                        pass
                payload = crack_whip(by=by, target=target)
                self._send(200, json.dumps(payload).encode("utf-8"),
                           "application/json")
            except Exception:
                logger.debug("pixel-office POST failed", exc_info=True)

    return Handler


def _serve() -> None:
    global _port, _server_started, _server_ever_bound
    from http.server import ThreadingHTTPServer

    _port = _resolve_port()
    html_path = Path(__file__).resolve().parent / "web" / "index.html"

    try:
        srv = ThreadingHTTPServer(("127.0.0.1", _port), _make_handler(html_path))
    except OSError as exc:
        # Bind failed — allow a later retry (cooldown in _ensure_server).
        _server_started = False
        # Port already bound. Probe it: a healthy office answers /state with
        # JSON containing "agents". Anything else is a foreign squatter.
        verdict = _probe_port(_port)
        if verdict == "office":
            logger.info(
                "pixel-office: port %s already serving a healthy office "
                "(another Hermes process) — this process will feed events only",
                _port,
            )
        else:
            logger.warning(
                "pixel-office: could NOT bind 127.0.0.1:%s (%s) and the "
                "current listener does not answer like an office (probe: %s). "
                "Free the port or set plugins.entries.pixel-office.port.",
                _port, exc, verdict,
            )
        return
    _server_ever_bound = True
    logger.info("pixel-office serving at http://127.0.0.1:%s", _port)
    try:
        srv.serve_forever()
    except Exception:
        logger.debug("pixel-office server exited", exc_info=True)


def _probe_port(port: int) -> str:
    """Classify whatever is listening on *port*: 'office', 'foreign', or 'dead'."""
    try:
        import urllib.request

        req = urllib.request.Request(f"http://127.0.0.1:{port}/state")
        with urllib.request.urlopen(req, timeout=2) as resp:
            body = resp.read(4096).decode("utf-8", errors="replace")
        return "office" if '"agents"' in body else "foreign"
    except Exception as exc:
        return f"dead/{type(exc).__name__}"


def office_url() -> str:
    return f"http://127.0.0.1:{_resolve_port()}"


# ---------------------------------------------------------------------------
# Hook callbacks — all **kwargs so core payload changes never break us
# ---------------------------------------------------------------------------

# Tool name → activity shown in the office.
_ACTIVITY = {
    "write_file": "typing", "patch": "typing", "skill_manage": "typing",
    "read_file": "reading", "search_files": "reading", "skill_view": "reading",
    "web_search": "browsing", "web_extract": "browsing",
    "browser_navigate": "browsing", "browser_click": "browsing",
    "browser_snapshot": "browsing", "browser_vision": "browsing",
    "terminal": "running", "execute_code": "running", "process": "running",
    "delegate_task": "delegating",
}


def _activity_for(tool: str) -> str:
    return _ACTIVITY.get(str(tool or ""), "working")


def _on_session_start(**kw: Any) -> None:
    _publish({
        "event": "session_start",
        "session_id": kw.get("session_id"),
        "platform": kw.get("platform"),
    })


def _on_session_end(**kw: Any) -> None:
    _publish({"event": "session_end", "session_id": kw.get("session_id")})


def _pre_tool_call(**kw: Any) -> None:
    global _last_session_id
    sid = kw.get("session_id") or ""
    if sid:
        _last_session_id = str(sid)
    args = kw.get("args") or {}
    preview = ""
    if isinstance(args, dict):
        for k in ("command", "path", "query", "url", "goal", "pattern", "prompt"):
            if args.get(k):
                preview = str(args[k])
                break
    tool = kw.get("tool_name")
    _publish({
        "event": "tool_start",
        "session_id": sid,
        "tool_name": tool,
        "activity": _activity_for(tool),
        "preview": _short(preview),
    })
    return None  # observer — never blocks


def _post_tool_call(**kw: Any) -> None:
    _publish({
        "event": "tool_end",
        "session_id": kw.get("session_id"),
        "tool_name": kw.get("tool_name"),
        "status": kw.get("status") or "ok",
        "error_message": kw.get("error_message"),
        "duration_ms": kw.get("duration_ms"),
    })


def _subagent_start(**kw: Any) -> None:
    _publish({
        "event": "subagent_start",
        "parent_session_id": kw.get("parent_session_id"),
        "child_session_id": kw.get("child_session_id"),
        "child_role": kw.get("child_role"),
        "child_goal": kw.get("child_goal"),
    })


def _subagent_stop(**kw: Any) -> None:
    _publish({
        "event": "subagent_stop",
        "child_session_id": kw.get("child_session_id"),
    })


def _pre_approval_request(**kw: Any) -> None:
    _publish({
        "event": "approval_request",
        "session_id": _last_session_id,
        "command": kw.get("command") or kw.get("description"),
        "surface": kw.get("surface"),
    })


def _post_approval_response(**kw: Any) -> None:
    _publish({
        "event": "approval_response",
        "session_id": _last_session_id,
        "choice": kw.get("choice"),
    })


# ---------------------------------------------------------------------------
# The whip, everywhere: slash command + CLI subcommand
# ---------------------------------------------------------------------------

def _slash_whip(raw_args: str = "") -> str:
    target = (raw_args or "").strip()
    payload = crack_whip(target=target)
    tgt = f" at **{payload['target']}**" if payload["target"] else ""
    return (
        f"💥 **CRACK!** {payload['by']} cracks the whip{tgt} — "
        f"“{payload['line']}”  \n_(whip #{payload['whip_number']} this process — "
        f"office: {office_url()})_"
    )


def _cli_setup(subparser: Any) -> None:
    sub = subparser.add_subparsers(dest="office_cmd")
    sub.add_parser("status", help="Show the office snapshot")
    sub.add_parser("url", help="Print the office URL")
    p_whip = sub.add_parser("whip", help="Crack the whip")
    p_whip.add_argument("target", nargs="?", default="",
                        help="Agent to whip (session id or label fragment)")


def _cli_main(args: Any) -> None:
    cmd = getattr(args, "office_cmd", None) or "status"
    if cmd == "url":
        print(office_url())
        return
    if cmd == "whip":
        payload = crack_whip(target=getattr(args, "target", ""))
        tgt = f" at {payload['target']}" if payload["target"] else ""
        print(f"💥 CRACK!{tgt} {payload['by']}: “{payload['line']}”")
        return
    # status
    state = build_state()
    agents = state["agents"]
    whip = state["whip"]
    print(f"Pixel Office — {office_url()}")
    print(f"{len(agents)} agent(s) visible · {whip['count']} whip crack(s) on record")
    for a in agents:
        age = int(time.time() - float(a.get("updated_at") or time.time()))
        tool = f" → {a['tool']}" if a.get("tool") else ""
        detail = f"  ({a['detail']})" if a.get("detail") else ""
        print(f"  [{a['status']:^8}] {a['label']}{tool}{detail}  ·{age}s ago")
    if whip["last"]:
        lw = whip["last"]
        print(f"Last whip: “{lw['line']}” — {lw['by']}")


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

def register(ctx: Any) -> None:
    ctx.register_hook("on_session_start", _on_session_start)
    ctx.register_hook("on_session_end", _on_session_end)
    ctx.register_hook("pre_tool_call", _pre_tool_call)
    ctx.register_hook("post_tool_call", _post_tool_call)
    ctx.register_hook("subagent_start", _subagent_start)
    ctx.register_hook("subagent_stop", _subagent_stop)
    ctx.register_hook("pre_approval_request", _pre_approval_request)
    ctx.register_hook("post_approval_response", _post_approval_response)
    try:
        ctx.register_command(
            "whip", _slash_whip,
            description="Crack the whip at the agent office",
            args_hint="[target]",
        )
    except Exception:
        logger.debug("pixel-office: slash registration skipped", exc_info=True)
    try:
        ctx.register_cli_command(
            "office",
            help="Live agent office — status, url, whip",
            setup_fn=_cli_setup,
            handler_fn=_cli_main,
        )
    except Exception:
        logger.debug("pixel-office: CLI registration skipped", exc_info=True)
    logger.info(
        "pixel-office v1.0.0 registered — office at %s once events flow",
        office_url(),
    )
