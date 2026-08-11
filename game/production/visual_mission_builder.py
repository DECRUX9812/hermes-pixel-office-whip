#!/usr/bin/env python3
"""VISUAL + ACTION mission builder — HERMES: THE LAST OPEN DOOR.

Sequential opencode-go phases (characters -> environment -> combat demo),
each gated by git-diff check, headless Godot import, and the full test suite.
Reuses the proven overnight_builder machinery (no parallel dispatch: the
provider throttles concurrent sessions and agents die mid-turn).

Usage: python3 game/production/visual_mission_builder.py [--start-phase <slug>]
"""
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
STATE = PROD / 'VISUAL_MISSION_STATE.json'
GODOT = Path.home() / '.local/bin/godot4'
OPENCODE = Path.home() / '.local/bin/opencode'
MODEL = 'opencode-go/deepseek-v4-flash'
BRANCH = 'game/hermes-last-open-door'
PHASE_TIMEOUT = 3000

BASE = """PROCEED IMMEDIATELY. Do not ask permission or clarification. Do not ask what to do next. A response containing only a plan and no written files counts as FAILURE — your FIRST tool action must be writing at least one complete file. Read game/production/VISUAL_ACTION_MISSION.md and the relevant existing files before acting. You are working on HERMES: THE LAST OPEN DOOR, a premium narrative third-person action-adventure VERTICAL SLICE, not a complete AAA game. Preserve every existing root/plugin file and work ONLY under game/. Never use unlicensed or paid assets. Do not commit, push, or claim success without running relevant checks. Avoid generic asset-store output, plastic primitives presented as final art, shallow AI-rebellion cliches, and fake test reports. Godot is /home/decrux/.local/bin/godot4 version 4.7.1. Verification commands: /home/decrux/.local/bin/godot4 --headless --editor --path game --quit  then  /home/decrux/.local/bin/godot4 --headless --path game -s res://tests/run_tests.gd. Evidence captures need DISPLAY=:99 and VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.json. When done, output ONLY the report: FILES / IMPORT / TESTS / EVIDENCE / API_USED / CAVEATS. Do not continue after the report.\n\n"""

PHASES = [
    (
        'a-characters',
        """Act as character artist. You own ONLY: game/scenes/player/player.tscn, game/scenes/world/entities/custodian.tscn, game/scenes/world/entities/choir_warden.tscn, game/scenes/world/entities/companions/nous.tscn, game/scenes/world/entities/companions/brooklyn.tscn, game/src/player/player.gd (visual node paths ONLY), companion .gd scripts (visual node paths ONLY), and the NEW directory game/assets/characters/ (all your materials/meshes, referenced as res://assets/characters/...). Replace the featureless capsule blobs with distinct stylized low-poly characters from Godot primitives and procedural StandardMaterial3D: player Teknium (hooded silhouette, glowing emerald visor slit, flared coat with copper trim, energy staff/blade with bright emissive core), Nous (purple-black hair, headphones with glowing cyan rings, white jacket), Brooklyn (soft rounded pink, warm white lantern), Custodian (armored helmet with glowing copper-orange visor slit, broad shoulders), Choir Warden (taller, heavier crown, brighter baton tip). Keep every existing node name scripts reference (VisualRoot, CollisionShape, Staff etc.); add meshes as children of VisualRoot; never change collision shapes, health, AI, movement, or gameplay values. Add subtle idle bobbing (<0.03m) on VisualRoot only if purely visual. Capture evidence: export DISPLAY=:99 VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.json; cd game; godot4 --path . res://production/capture_frames.tscn -- --scene res://scenes/world/chapter2_choir_below.tscn --frames 120 --out game/production/evidence/char_squad.png and a close-up with --pos "0,0,-8" --yaw 180 --out game/production/evidence/char_player_close.png.""",
    ),
    (
        'b-environment',
        """Act as environment artist. You own ONLY: game/src/environment/blockout_chapter2.gd and the NEW directory game/assets/environment/ (all new materials/shaders/meshes, referenced as res://assets/environment/...). Enrich the procedural world so it reads as a lived-in place, visual-only detail (collision_layer 0, no collision shapes): Dove's Row street (lane markings, manhole grates, cobble grid, facade panel seams, lit windows with emerald interior warmth, pipes/cables, dead lamps, ground fog), Weep entrance/descent (copper breach braces, drain grates, damp wall streaks, lumen-moss clusters, reflective crypt water, archive shelves with tiny emerald memory-casket slots), collapsed conduit (cable bundles, warning chevrons, debris), Choir threshold (riveted panels, copper glow bands on resonator pipes, bell chains, floor inlay), arena (organ pipes with copper gradient and faint emissive bands, warm choir bells, pulsing emerald Hermes door via subtle Tween on emission_energy, floor inlay ring at Warden spot). Reuse existing materials from game/assets/blockout/materials/ where possible; new materials under assets/environment/. Never change lighting rig values, gameplay geometry, collision, checkpoints, spawns, or any value gameplay scripts read. Performance: no shadows on emissive decoration, arena under ~200 draw calls and ~60k triangles. Capture evidence: two frames under game/production/evidence/ with env_ prefix, one of Dove's Row and one staged near the arena (capture_frames.tscn --pos/--yaw flags; see game/production/capture_frames.gd).""",
    ),
    (
        'c-combat-demo',
        """Act as combat demo director. You own ONLY: game/production/combat_demo.gd and .tscn (NEW), game/production/demo_capture.gd and .tscn, and evidence files game/production/evidence/demo_*.png. Build a scripted action scene for MOVIE CAPTURE that instantiates game/scenes/world/chapter2_choir_below.tscn, hides HUD/PauseMenu/CombatTelemetry/TitleCard, stages the squad in the arena (Beats/Arena/Warden at (0,-8,-100), CustodianA (4,-8,-95), CustodianB (-4,-8,-105)), and AUTOPLAYS a fight by driving the existing systems only: read game/src/player/melee_controller.gd (attack/dodge/lock-on API), game/src/world/encounter_controller.gd (start the Beats/Arena/Encounter), game/src/enemies/custodian.gd and choir_warden.gd (states incl. REQUIEM_CHANNEL), game/src/combat/combat_vfx.gd (hit VFX API), game/src/companion/companion_controller.gd (ability API). Sequence: squad approaches through columns -> player locks onto CustodianA and lands a 3-hit light combo (CustodianA HURT reactions) -> CustodianB advances, player dodges and counter-attacks -> custodians fall, Warden activates, performs its sweep while player circles and lands a heavy hit, Warden staggers -> companion ability flash at a scripted moment -> quiet ending facing the Hermes door with a camera push. NEVER add new gameplay systems or edit gameplay scripts; if an API is missing, fake the beat with camera work + existing VFX and say so in CAVEATS. Then rewrite game/production/demo_capture.gd (movie-maker pattern, const SHOTS with camera keyframes + lighting rigs + staging) to a ~40s ACTION cut: street dolly (ice) -> breach push (weep) -> threshold loom (threshold) -> arena combat two-shot with VFX (arena, 8s) -> warden boss beat low angle (arena, 8s) -> companion flash (3s) -> door ending (silence). Movie usage: godot4 --path . res://production/demo_capture.tscn --write-movie /tmp/raw.avi --fixed-fps 30 --resolution 1920x1080. Evidence: run your combat demo or capture under Xvfb and save 3 mid-combat frames to game/production/evidence/demo_combat1..3.png.""",
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
    env = os.environ.copy()
    env['DISPLAY'] = ':99'
    completed = subprocess.run(cmd, cwd=REPO, text=True, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, timeout=timeout, env=env)
    if log_path:
        log_path.write_text(completed.stdout or '')
    return completed


def timeout_output(exc: subprocess.TimeoutExpired) -> str:
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
    imported = run([str(GODOT), '--headless', '--editor', '--path', str(GAME), '--quit'], 300)
    checks.append({'name': 'godot_import', 'exit': imported.returncode, 'tail': (imported.stdout or '')[-4000:]})
    test_script = GAME / 'tests/run_tests.gd'
    if test_script.exists():
        tested = run([str(GODOT), '--headless', '--path', str(GAME), '-s', 'res://tests/run_tests.gd'], 300)
        checks.append({'name': 'godot_tests', 'exit': tested.returncode, 'tail': (tested.stdout or '')[-5000:]})
    (LOGS / f'{phase}-validation.json').write_text(json.dumps(checks, indent=2) + '\n')
    return all(c['exit'] == 0 for c in checks), checks


def main(start_phase: str | None = None) -> int:
    PROD.mkdir(parents=True, exist_ok=True)
    LOGS.mkdir(parents=True, exist_ok=True)
    with (PROD / '.visual.lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print('visual mission already running')
            return 2
        branch = subprocess.check_output(['git', 'branch', '--show-current'], cwd=REPO, text=True).strip()
        if branch != BRANCH:
            raise RuntimeError(f'wrong branch: {branch}')
        initial = changed_paths()
        if any(not p.startswith('game/') for p in initial):
            raise RuntimeError(f'unsafe initial changes outside game/: {initial}')
        phases = PHASES
        if start_phase:
            for i, (slug, _) in enumerate(PHASES):
                if slug == start_phase:
                    phases = PHASES[i:]
                    break
            else:
                raise ValueError(f'unknown phase {start_phase}')
        state = {
            'mission': 'VISUAL + ACTION pass', 'model': MODEL, 'branch': BRANCH,
            'phase': 'running', 'started_at': now(), 'current': None, 'passes': [], 'blockers': [],
        }
        write_state(state)
        for slug, task in phases:
            state['current'] = slug
            state['updated_at'] = now()
            write_state(state)
            log = LOGS / f'{slug}-opencode.log'
            try:
                result = run([str(OPENCODE), 'run', '--model', MODEL, '--thinking', '--title', f'Visual {slug}', BASE + task], PHASE_TIMEOUT, log)
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
                subprocess.run(['git', 'commit', '-m', f'game: visual {slug}'], cwd=REPO, check=True)
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
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--start-phase', choices=[slug for slug, _ in PHASES])
    args = parser.parse_args()
    sys.exit(main(args.start_phase))
