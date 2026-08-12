"""Pixel Office — backend API routes for the desktop pane.

Mounted at /api/plugins/pixel-office/ by the dashboard plugin system.
A thin read/whip layer over the main plugin module's shared state functions,
so the desktop pane, the web page, the TUI, and the CLI can never drift.
"""

from __future__ import annotations

import importlib.util
import logging
import sys
from pathlib import Path
from typing import Optional

from fastapi import APIRouter
from pydantic import BaseModel

log = logging.getLogger(__name__)

router = APIRouter()

# Import the main plugin module (same package) by file path — the plugin
# loader doesn't put it on sys.path under a stable dotted name, so resolve
# it relative to this file instead of relying on an import path.
_PLUGIN_INIT = Path(__file__).resolve().parent.parent / "__init__.py"


def _office():
    # Reuse the module the plugin loader already imported, if present.
    mod = sys.modules.get("hermes_plugins.pixel_office")
    if mod is not None:
        return mod
    spec = importlib.util.spec_from_file_location(
        "hermes_plugins.pixel_office", _PLUGIN_INIT
    )
    mod = importlib.util.module_from_spec(spec)
    sys.modules["hermes_plugins.pixel_office"] = mod
    spec.loader.exec_module(mod)
    return mod


class WhipBody(BaseModel):
    by: Optional[str] = ""
    target: Optional[str] = ""


@router.get("/state")
def get_state():
    try:
        return _office().build_state()
    except Exception as exc:  # noqa: BLE001
        log.warning("pixel-office state failed: %s", exc)
        return {"agents": [], "whip": {"count": 0, "last": None}, "ts": 0,
                "error": str(exc)}


@router.get("/url")
def get_url():
    try:
        return {"url": _office().office_url()}
    except Exception as exc:  # noqa: BLE001
        return {"url": "", "error": str(exc)}


@router.post("/whip")
def post_whip(body: WhipBody):
    try:
        return _office().crack_whip(by=body.by or "", target=body.target or "")
    except Exception as exc:  # noqa: BLE001
        log.warning("pixel-office whip failed: %s", exc)
        return {"ok": False, "error": str(exc)}
