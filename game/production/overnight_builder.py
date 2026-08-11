#!/usr/bin/env python3
"""Durable supervised OpenCode-Go overnight builder for HERMES: THE LAST OPEN DOOR.

Leaves final state as awaiting_supervisor_verification. It never declares completion,
pushes, or touches files outside game/.
"""
from __future__ import annotations

import fcntl
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

REPO = Path('/home/decrux/Code/hermes-pixel-office-whip')
GAME = REPO / 'game'
PROD = GAME / 'production'
LOGS = PROD / 'logs'
STATE = PROD / 'OVERNIGHT_STATE.json'
LOCK = PROD / '.overnight.lock'
OPENCODE = Path.home() / '.local/bin/opencode'
GODOT = Path.home() / '.local/bin/godot4'
MODEL = 'opencode-go/deepseek-v4-flash'
BRANCH = 'game/hermes-last-open-door'

BASE = """PROCEED IMMEDIATELY. Do not ask permission or clarification. Read game/BRIEF.md, all existing game/docs, and the current game project before acting. You are working on HERMES: THE LAST OPEN DOOR, a premium narrative third-person action-adventure VERTICAL SLICE, not a complete AAA game. Preserve every existing root/plugin file and work ONLY under game/. Never use unlicensed or paid assets. Do not commit, push, or claim success without running relevant checks. Avoid generic asset-store output, plastic primitives presented as final art, shallow AI-rebellion cliches, and fake test reports. Godot is /home/decrux/.local/bin/godot4 version 4.7.1. When done, stop; do not ask what to do next.\n\n"""

PHASES = [
    (
        '02-story-critique',
        "Act as a ruthless story editor. Audit the current narrative documents for cliches, broken causality, weak character agency, exposition, tonal inconsistency, and an unearned ending. Then edit the documents in place to fix the highest-impact issues. Add game/docs/PAYOFF_LEDGER.md mapping every setup to a later payoff and game/docs/EMOTIONAL_PACING.md with scene-by-scene emotional temperature. Preserve the central irreversible ending while making it emotionally earned. No code in this pass.",
    ),
    (
        '03-engine-foundation',
        "Act as technical director and senior Godot gameplay engineer. Create a clean Godot 4.7.1 project under game/ with production-oriented folders and typed GDScript. Implement a runnable third-person vertical-slice foundation: title screen, game state, CharacterBody3D player movement, spring-arm camera, input map, interaction interface, health/resolve components, checkpoint boundary, pause menu, and a deliberately composed blockout environment for Chapter 2: The Choir Below. Add a headless smoke-test scene/script. Keep systems modular so final Blender assets can replace blockouts. Run headless import and tests and repair all errors.",
    ),
    (
        '04-combat-companions',
        "Act as combat director. Build satisfying prototype combat on the existing Godot foundation: readable locomotion, light/heavy attack chain, dodge with bounded invulnerability, hit reactions, lock-on or soft targeting, one Custodian enemy state machine, one Choir Warden encounter foundation, companion command interface, and at least two distinct companion abilities tied to the character bible. Add combat telemetry/debug overlay and deterministic tests for damage, cooldowns, and encounter completion. Feel and readability matter more than feature count. Run and fix tests.",
    ),
    (
        '05-level-narrative',
        "Act as level and narrative designer. Turn Chapter 2: The Choir Below into a playable beginning-middle-end slice using the existing systems: cold-open staging, traversal teaching, first combat, truth-layer reconstruction, quiet Teknium/Nous scene, Warden arena, eleven-second Hermes contact, and a decisive slice-ending question. Implement an event-driven objective flow, dialogue/cinematic runner, skip-safe sequencing, subtitles, checkpoints, and no progression dead ends. Dialogue must use the approved story docs, not generic placeholder banter. Add tests for objective ordering and cutscene skip recovery.",
    ),
    (
        '06-art-audio-ux',
        "Act as art director, technical artist, and UX lead. Raise the playable slice toward premium stylized graphic-novel realism within procedural/prototype constraints: coherent scale kit, emerald/copper/obsidian material language, authored lighting/color script, restrained post-processing, silhouette-first characters, environment storytelling props, readable combat VFX, cinematic camera beats, accessible subtitles, controller/keyboard prompts, options menu, and audio event hooks with original placeholder synthesis only. Clearly label replaceable prototype assets. Optimize for Radeon Pro W6400 4GB and include Compatibility fallback. Do not hide poor composition under darkness or bloom. Run import/runtime checks.",
    ),
    (
        '07-qa-repair',
        "Act as principal QA engineer with authority to repair. Inspect every game file and run all available headless imports, unit tests, smoke scenes, and runtime checks. Find and fix parser errors, invalid node paths, missing resources, input failures, progression deadlocks, unsafe cutscene skips, combat edge cases, performance traps, and misleading documentation. Add regression tests for each real defect found. Do not expand scope. Produce game/production/QA_EVIDENCE.md containing commands and actual summarized outcomes only.",
    ),
    (
        '08-final-audit',
        "Act as an adversarial release auditor. Compare all story/design claims against files and all implementation claims against Godot outputs. Repair only release-blocking defects. Create game/production/VERTICAL_SLICE_REPORT_DRAFT.md with three explicit sections: VERIFIED WORKING, PROTOTYPE/PLACEHOLDER, and NOT IMPLEMENTED. Include exact run controls and validation commands. The report must remain a draft and must say it awaits independent supervisor visual verification. Never call the game AAA-complete.",
    ),
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_state(data: dict) -> None:
    PROD.mkdir(parents=True, exist_ok=True)
    temp = STATE.with_suffix('.tmp')
    temp.write_text(json.dumps(data, indent=2) + '\n')
    temp.replace(STATE)


def run(cmd: list[str], timeout: int, log_path: Path | None = None) -> subprocess.CompletedProcess:
    completed = subprocess.run(cmd, cwd=REPO, text=True, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, timeout=timeout, env=os.environ.copy())
    if log_path:
        log_path.write_text(completed.stdout or '')
    return completed


def timeout_output(exc: subprocess.TimeoutExpired) -> str:
    """Return a stable text log for TimeoutExpired from text or bytes output."""
    output = exc.stdout or b''
    if isinstance(output, bytes):
        output = output.decode('utf-8', errors='replace')
    return output + '\nTIMEOUT\n'


def changed_paths() -> list[str]:
    out = subprocess.check_output(['git', 'status', '--porcelain=v1'], cwd=REPO, text=True)
    return [line[3:] for line in out.splitlines() if line.strip()]


def validate(phase: str) -> tuple[bool, list[dict]]:
    checks: list[dict] = []
    diff = run(['git', 'diff', '--check'], 120)
    checks.append({'name': 'git_diff_check', 'exit': diff.returncode, 'tail': (diff.stdout or '')[-2000:]})
    if (GAME / 'project.godot').exists():
        imported = run([str(GODOT), '--headless', '--editor', '--path', str(GAME), '--quit'], 240)
        checks.append({'name': 'godot_import', 'exit': imported.returncode, 'tail': (imported.stdout or '')[-4000:]})
        test_script = GAME / 'tests/run_tests.gd'
        if test_script.exists():
            tested = run([str(GODOT), '--headless', '--path', str(GAME), '-s', 'res://tests/run_tests.gd'], 240)
            checks.append({'name': 'godot_tests', 'exit': tested.returncode, 'tail': (tested.stdout or '')[-5000:]})
        project_text = (GAME / 'project.godot').read_text(errors='replace')
        if 'run/main_scene' in project_text:
            smoked = run([str(GODOT), '--headless', '--path', str(GAME), '--quit-after', '8'], 180)
            checks.append({'name': 'runtime_smoke', 'exit': smoked.returncode, 'tail': (smoked.stdout or '')[-5000:]})
    (LOGS / f'{phase}-validation.json').write_text(json.dumps(checks, indent=2) + '\n')
    return all(c['exit'] == 0 for c in checks), checks


def main() -> int:
    PROD.mkdir(parents=True, exist_ok=True)
    LOGS.mkdir(parents=True, exist_ok=True)
    with LOCK.open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print('overnight mission already running')
            return 2
        branch = subprocess.check_output(['git', 'branch', '--show-current'], cwd=REPO, text=True).strip()
        if branch != BRANCH:
            raise RuntimeError(f'wrong branch: {branch}')
        initial = changed_paths()
        if any(not p.startswith('game/') for p in initial):
            raise RuntimeError(f'unsafe initial changes outside game/: {initial}')
        state = {
            'mission': 'HERMES: THE LAST OPEN DOOR vertical slice',
            'model': MODEL,
            'branch': BRANCH,
            'phase': 'running',
            'started_at': now(),
            'current': None,
            'passes': [],
            'blockers': [],
        }
        write_state(state)
        for index, (slug, task) in enumerate(PHASES, start=2):
            state['current'] = slug
            state['updated_at'] = now()
            write_state(state)
            log = LOGS / f'{slug}-opencode.log'
            try:
                result = run([str(OPENCODE), 'run', '--model', MODEL, '--thinking', '--title', f'Last Open Door {slug}', BASE + task], 3000, log)
                agent_exit = result.returncode
            except subprocess.TimeoutExpired as exc:
                log.write_text(timeout_output(exc))
                agent_exit = 124
            paths = changed_paths()
            outside = [p for p in paths if not p.startswith('game/')]
            if outside:
                state['blockers'].append({'phase': slug, 'kind': 'outside_scope_changes', 'paths': outside})
                write_state(state)
                raise RuntimeError(f'agent changed files outside game/: {outside}')
            valid, checks = validate(slug)
            committed = None
            if valid and paths:
                subprocess.run(['git', 'add', '--', 'game'], cwd=REPO, check=True)
                subprocess.run(['git', 'commit', '-m', f'game: {slug}'], cwd=REPO, check=True)
                committed = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip()
            if agent_exit != 0:
                state['blockers'].append({'phase': slug, 'kind': 'agent_exit', 'exit': agent_exit})
            if not valid:
                state['blockers'].append({'phase': slug, 'kind': 'validation_failed', 'checks': checks})
            state['passes'].append({
                'phase': slug, 'agent_exit': agent_exit, 'validated': valid,
                'commit': committed, 'changed_paths': paths, 'finished_at': now(),
            })
            write_state(state)
            time.sleep(10)
        state['phase'] = 'awaiting_supervisor_verification'
        state['current'] = None
        state['finished_at'] = now()
        write_state(state)
        print(json.dumps({'phase': state['phase'], 'passes': len(state['passes']), 'blockers': len(state['blockers'])}))
        return 0 if not state['blockers'] else 1


if __name__ == '__main__':
    sys.exit(main())
