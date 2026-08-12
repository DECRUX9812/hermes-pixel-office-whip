"""Tests for the pixel-office v1.0.0 plugin (stdlib + pytest only)."""

from __future__ import annotations

import importlib.util
import json
import sys
import time
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parent.parent


@pytest.fixture()
def office(tmp_path, monkeypatch):
    """Load the plugin fresh against an isolated HERMES_HOME."""
    monkeypatch.setenv("HERMES_HOME", str(tmp_path))
    sys.modules.pop("pixel_office_under_test", None)
    spec = importlib.util.spec_from_file_location(
        "pixel_office_under_test", REPO / "__init__.py"
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# ---------------------------------------------------------------------------
# Hooks → events.jsonl (the core contract)
# ---------------------------------------------------------------------------

def test_hooks_append_jsonl(office, tmp_path):
    office._on_session_start(session_id="s1", platform="cli")
    office._pre_tool_call(session_id="s1", tool_name="terminal",
                          args={"command": "ls"})
    office._post_tool_call(session_id="s1", tool_name="terminal", status="ok")
    office._on_session_end(session_id="s1")

    path = tmp_path / "pixel-office" / "events.jsonl"
    assert path.exists()
    lines = [json.loads(l) for l in path.read_text().splitlines() if l.strip()]
    kinds = [l["event"] for l in lines]
    assert kinds == ["session_start", "tool_start", "tool_end", "session_end"]
    # tool_start carries an activity classification
    assert lines[1]["activity"] == "running"


def test_hooks_never_raise_on_bad_input(office):
    # None session ids, weird args — observers must swallow everything.
    office._on_session_start()
    office._pre_tool_call(args="not-a-dict")
    office._post_tool_call(status=None)
    office._subagent_start(child_session_id=None)


def test_event_log_trimmed(office, tmp_path, monkeypatch):
    monkeypatch.setattr(office, "_MAX_LOG_BYTES", 2048)
    for i in range(200):
        office._publish({"event": "tool_start", "session_id": f"s{i}",
                         "payload": "x" * 100})
    path = tmp_path / "pixel-office" / "events.jsonl"
    assert path.stat().st_size <= 4096  # trimmed to ~half


# ---------------------------------------------------------------------------
# State folding
# ---------------------------------------------------------------------------

def test_build_state_agent_lifecycle(office):
    office._on_session_start(session_id="main1", platform="discord")
    office._pre_tool_call(session_id="main1", tool_name="read_file",
                          args={"path": "/x"})
    office._subagent_start(parent_session_id="main1", child_session_id="sub1",
                           child_goal="do the thing")
    office._subagent_stop(child_session_id="sub1")

    state = office.build_state()
    by_id = {a["id"]: a for a in state["agents"]}
    assert "main1" in by_id and "sub1" in by_id
    assert by_id["main1"]["status"] == "working"
    assert by_id["main1"]["tool"] == "read_file"
    assert by_id["sub1"]["kind"] == "subagent"
    assert by_id["sub1"]["status"] == "done"
    assert by_id["main1"]["label"].startswith("discord")


def test_build_state_approval_flow(office):
    office._on_session_start(session_id="main2", platform="cli")
    office._pre_tool_call(session_id="main2", tool_name="terminal", args={})
    office._pre_approval_request(command="rm -rf /")
    state = office.build_state()
    me = [a for a in state["agents"] if a["id"] == "main2"][0]
    assert me["status"] == "waiting"
    office._post_approval_response(choice="approve")
    state = office.build_state()
    me = [a for a in state["agents"] if a["id"] == "main2"][0]
    assert me["status"] == "working"


def test_stale_agents_swept(office):
    old = time.time() - office._STALE_SECONDS - 10
    office._publish({"event": "session_start", "session_id": "ancient", "ts": old})
    office._publish({"event": "tool_start", "session_id": "ancient", "ts": old})
    state = office.build_state()
    assert all(a["id"] != "ancient" for a in state["agents"])


# ---------------------------------------------------------------------------
# The whip
# ---------------------------------------------------------------------------

def test_crack_whip_records_event_and_counts(office):
    p1 = office.crack_whip(by="Ritesh")
    p2 = office.crack_whip(target="deadbeef")
    assert p1["whip_number"] == 1 and p2["whip_number"] == 2
    assert p1["line"] and p2["line"]
    state = office.build_state()
    assert state["whip"]["count"] == 2
    assert state["whip"]["last"]["target"] == "deadbeef"


def test_whip_marks_matching_agent(office):
    office._on_session_start(session_id="sess-abc123", platform="telegram")
    office.crack_whip(target="abc123")
    state = office.build_state()
    me = [a for a in state["agents"] if a["id"] == "sess-abc123"][0]
    assert me["whipped_at"] > 0


def test_slash_whip_returns_markdown(office):
    out = office._slash_whip("some-agent")
    assert "CRACK" in out and "some-agent" in out


# ---------------------------------------------------------------------------
# HTTP layer (handler against the real handler class, no sockets bound)
# ---------------------------------------------------------------------------

class _Buf:
    def __init__(self):
        self.buf = b""

    def write(self, b):
        self.buf += b


def _call(handler_cls, method: str, path: str):
    """Invoke a handler method with a fully faked request context."""
    h = handler_cls.__new__(handler_cls)
    h.path = path
    h.request_version = "HTTP/1.1"
    h.requestline = f"{method} {path} HTTP/1.1"
    h.command = method
    h.headers = {}
    h._headers_buffer = []
    h.wfile = _Buf()
    h.send_response_only = lambda code, msg=None: None
    h.send_header = lambda k, v: None
    h.end_headers = lambda: None
    h.log_request = lambda code=0: None
    getattr(h, f"do_{method}")()
    return h.wfile.buf


def test_http_state_endpoint(office):
    office._on_session_start(session_id="web1", platform="desktop")
    Handler = office._make_handler(REPO / "web" / "index.html")
    body = json.loads(_call(Handler, "GET", "/state").decode("utf-8"))
    assert body["agents"][0]["id"] == "web1"
    assert body["whip"]["count"] == 0


def test_http_whip_endpoint(office):
    Handler = office._make_handler(REPO / "web" / "index.html")

    # Build a handler with a readable body.
    h = Handler.__new__(Handler)
    h.path = "/whip"
    h.request_version = "HTTP/1.1"
    h.requestline = "POST /whip HTTP/1.1"
    h.command = "POST"
    payload = json.dumps({"by": "test", "target": ""}).encode()
    h.headers = {"Content-Length": str(len(payload))}

    import io
    h.rfile = io.BytesIO(payload)
    h._headers_buffer = []
    h.wfile = _Buf()
    h.send_response_only = lambda code, msg=None: None
    h.send_header = lambda k, v: None
    h.end_headers = lambda: None
    h.log_request = lambda code=0: None
    h.do_POST()
    body = json.loads(h.wfile.buf.decode("utf-8"))
    assert body["event"] == "whip" and body["line"]
    assert office.build_state()["whip"]["count"] == 1


def test_healthz_and_index_exist(office):
    Handler = office._make_handler(REPO / "web" / "index.html")
    assert b'"ok":true' in _call(Handler, "GET", "/healthz")
    html = _call(Handler, "GET", "/").decode("utf-8")
    assert "Pixel Office" in html and "state" in html
    assert _call(Handler, "GET", "/nope") == b"not found"


def test_web_page_is_self_contained():
    html = (REPO / "web" / "index.html").read_text()
    assert "<script" in html
    assert "CRACK THE WHIP" in html
    # No external assets — the whole product is one file + /state + /whip.
    assert 'src="http' not in html and 'href="http' not in html


def test_register_wires_everything(office):
    calls = []

    class Ctx:
        def register_hook(self, name, fn):
            calls.append(("hook", name))

        def register_command(self, name, fn, **kw):
            calls.append(("command", name))

        def register_cli_command(self, name, **kw):
            calls.append(("cli", name))

    office.register(Ctx())
    hooks = {c[1] for c in calls if c[0] == "hook"}
    assert {"pre_tool_call", "post_tool_call", "on_session_start"} <= hooks
    assert ("command", "whip") in calls
    assert ("cli", "office") in calls
