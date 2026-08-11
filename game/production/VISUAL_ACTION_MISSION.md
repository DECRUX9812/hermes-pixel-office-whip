# VISUAL + ACTION MISSION — HERMES: THE LAST OPEN DOOR (Chapter 2 slice)

**Goal:** the vertical slice looks and plays like a real game, not a blockout. Three
parallel agents (A: characters, B: environment, C: combat demo + trailer capture)
work on disjoint files. This README is the shared contract — read it fully first.

**Engine:** Godot 4.7.1 at `/home/decrux/.local/bin/godot4`. Repo root: `/home/decrux/Code/hermes-pixel-office-whip`.
Work ONLY under `game/`. Never use paid/unlicensed/external assets — procedural
materials and primitives only. Do not commit or push (the supervisor does that).

## Style guide (non-negotiable)

- **Stylized low-poly neon-noir.** Dark stone/obsidian architecture, deep shadows,
  heavy fog, with three accent families: **emerald** (Hermes, memory, the street),
  **copper/orange** (the Choir, the Warden, captivity), **magenta/white** (Nous,
  Brooklyn, player blade). Keep the existing color script in
  `game/src/world/lighting_director.gd` — do not change rig values.
- Characters must have **distinct silhouettes readable at 10 m in low light**, each
  with one or two **glowing signature parts** (visor, collar, blade core, crown,
  headphones). No featureless capsules anywhere in the final cut.
- Materials: flat albedo + strong emissive (emission_energy_multiplier 1.5–3.0 for
  accent parts), low specular. Prefer shared materials (few unique resources).
- Performance budget: the arena scene must stay under ~60k triangles and ~200 draw
  calls. Emissive decoration: no shadows. Reuse materials aggressively.
- Everything must look intentional at 1920×1080 with bloom/SSAO on.

## Ownership map — STRICT. You own ONLY your files.

| Agent | Owns (and ONLY these) |
|---|---|
| **A — Characters** | `game/scenes/player/player.tscn`, `game/scenes/world/entities/custodian.tscn`, `game/scenes/world/entities/choir_warden.tscn`, `game/scenes/world/entities/companions/nous.tscn`, `game/scenes/world/entities/companions/brooklyn.tscn`, `game/assets/characters/` (NEW dir for all character materials/meshes) |
| **B — Environment** | `game/src/environment/blockout_chapter2.gd`, `game/assets/environment/` (NEW dir for env materials/meshes) |
| **C — Combat demo + capture** | `game/production/combat_demo.gd` + `.tscn` (NEW), `game/production/demo_capture.gd` + `.tscn`, `game/production/evidence/demo_*.png` |

Evidence prefixes: A writes `game/production/evidence/char_*.png`, B writes
`env_*.png`, C writes `demo_*.png`. Do not overwrite other agents' evidence.

**Forbidden for everyone:** `game/tests/`, `game/project.godot`, `.godot/`,
`game/scenes/ui/`, `game/scenes/world/chapter2_choir_below.tscn`,
`game/scenes/world/chapter2.gd`, `game/src/combat/`, `game/src/enemies/`
(AI scripts), `game/src/narrative/`, `game/src/audio/`, `game/src/autoload/`,
`game/docs/`, `game/production/OVERNIGHT_STATE.json`. Agent A may touch
`game/src/player/player.gd` and companion `.gd` scripts ONLY to fix visual node
paths — and must keep every class_name, signal, method, exported var, and node
name the rest of the code references. If you can't do it without breaking a
reference, don't do it.

## Hard constraints

1. **Gameplay untouched.** Never change collision shape sizes, checkpoint/trigger
   positions, enemy spawn positions, damage/health values, input maps, camera
   behavior, or any value a gameplay script reads. Decoration added by B must be
   `collision_layer 0` (visual-only) or added as children of existing visual
   nodes. A adds meshes under each scene's `VisualRoot` (or equivalent) so
   physics/collision stay exactly as-is.
2. Keep node names intact — scripts reference them by path.
3. No external downloads. Procedural meshes/materials only.
4. Tests must keep passing (baseline 96).

## Verification (run these yourself before reporting done)

```bash
# import gate
/home/decrux/.local/bin/godot4 --headless --editor --path /home/decrux/Code/hermes-pixel-office-whip/game --quit
# test gate
/home/decrux/.local/bin/godot4 --headless --path /home/decrux/Code/hermes-pixel-office-whip/game -s res://tests/run_tests.gd
# evidence capture (per agent)
export DISPLAY=:99
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.json
cd /home/decrux/Code/hermes-pixel-office-whip/game
godot4 --path . res://production/capture_frames.tscn -- --scene <your-scene> --frames 90 --out game/production/evidence/<prefix>_<name>.png
```

If import or tests fail, repair your own files until they pass. Capture at least 2
evidence frames showing your work (characters: one group shot + one close-up;
environment: two different beats; demo: mid-combat frames).

## Report format (final output ONLY this, no follow-up questions)

```
FILES: <changed/new files>
IMPORT: exit <n>
TESTS: <pass>/<fail> (count)
EVIDENCE: <paths>
API_USED: <for C: exact functions you drove the player/enemies with>
CAVEATS: <honest notes>
```
