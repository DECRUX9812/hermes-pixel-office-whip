# VERTICAL SLICE RELEASE AUDIT — DRAFT (v0.1)

**Title:** HERMES: THE LAST OPEN DOOR — Chapter 2: The Choir Below
**Project:** `game/` on branch `game/hermes-last-open-door`
**Engine:** Godot 4.7.1 stable (`/home/decrux/.local/bin/godot4`)
**Auditor:** adversarial release audit, run 2026-08-11
**Status:** **DRAFT — awaits independent supervisor visual verification.**

> This report is a draft. Every item in VERIFIED WORKING below is backed by a
> headless Godot import, a test-suite run, and/or a bounded runtime launch that
> this audit reproduced on disk. Items marked "visually verified" are backed by
> captured frames in `game/production/evidence/` whose files exist and contain
> real (non-blank) pixel data, but **no human supervisor has yet visually
> reviewed them**. This slice is a *vertical-slice foundation*; it is **not**
> presented as an AAA-complete game. See NOT IMPLEMENTED.

---

## 1. VERIFIED WORKING

Claim basis: Godot 4.7.1 headless import, `tests/run_tests.gd` (96 passed /
0 failed), bounded headless runtime launches of the main menu and Chapter 2
scenes, and a reproduced evidence-capture run — all re-executed by this audit.

| Area | Evidence | Verified by |
|---|---|---|
| Project imports cleanly | `godot4 --headless --import` exits 0, no parse/resource errors | audit re-run |
| Automated test suite | 96 passed, 0 failed (`TEST RUN OK`, exit 0) incl. `SMOKE_TEST: PASS` | audit re-run |
| Main menu scene runs | `main_menu.tscn` launches headless, exits 0, no script errors | audit re-run |
| Chapter 2 scene runs | `chapter2_choir_below.tscn` launches headless for 300 and 1200 frames, no script errors | audit re-run |
| Third-person controller | movement, camera-relative steering, jump, sprint, dodge with i-frames (`player.gd`, `test_player.gd`) | suite + source |
| Melee combat | light/heavy chains, input buffering, dodge-cancel, hitstop, knockback, stagger (`melee_controller.gd`, `test_melee_combo.gd`) | suite + source |
| Health / Resolve | damage, i-frame windows, regen, resolve gating (`test_health.gd`, `test_resolve.gd`) | suite + source |
| Enemy archetype (Custodian) | chase/windup telegraph/attack/hurt/stagger/convert state machine (`custodian.gd`, `test_custodian.gd`) | suite + source |
| Choir Warden arena set piece | phase 1 sweeps, phase 2 requiem channel (vulnerable + interruptible), summoning; boss bar (`choir_warden.gd`, `test_encounter.gd`) | suite + source |
| Companion commands | Nous TRUTH_BREACH (reveal + interrupt), Brooklyn HEART_BIND (convert), resolve + cooldown gated (`companion.gd`, `test_companion.gd`) | suite + source |
| Encounter controller | trigger, roster, conversion does not strand completion, completion on all dead (`encounter_controller.gd`, `test_encounter.gd`) | suite + source |
| Objective flow | ordered advance + deadlock-safe `skip_to`; no progression dead ends (`objective_flow.gd`, `test_slice_spine.gd`) | suite + source |
| Dialogue / cinematic framework | skip-safe runner, player-lock, camera swap; canonical dialogue verbatim from `docs/VERTICAL_SLICE_SCRIPT.md` (`dialogue_runner.gd`, `script_dialogue.gd`, `test_script_dialogue.gd`, `test_dialogue_runner.gd`) | suite + source |
| Hermes "eleven seconds" + the question | canonical text present verbatim; question is the final sequence and fires the end-of-slice title card (`test_script_dialogue.gd`) | suite + source |
| Truth-layer reconstruction | 3 substrate fragments, any order; Weep gate opens on completion (`truth_layer_reconstruction.gd`, `test_slice_spine.gd`) | suite + source |
| Checkpoint / save boundary | checkpoint registration, respawn spawn-transform, save/load/delete round-trip (`checkpoint_area.gd`, `game_state.gd`, `test_checkpoint.gd`, `test_game_state.gd`) | suite + source |
| Traversal solidity | 17-waypoint ground probe (no void gaps) + real-input conduit-gap jump (`test_traversal_path.gd`) | suite + source |
| Slice spine end-to-end | drives cold open → surrender → descent → conduit → first contact → payoff → Nous talk → Warden → eleven seconds → the question; title card fires; `slice_complete` persisted (`test_slice_spine.gd`) | suite + source |
| Audio | runtime-synthesized cues (no external files), bus layout, event hooks, volumes (`synth.gd`, `audio_director.gd`, `test_synth.gd`, `test_audio_director.gd`) | suite + source |
| Input prompts / accessibility basics | keyboard↔gamepad glyph switching, subtitle scale/background, invert-Y, sensitivity, FOV, quality presets, per-bus volume (`input_prompts.gd`, `settings.gd`, `options_menu.gd`) | suite + source |
| Lighting / color script | 6 authored rigs (ice→silence) wired to objective/encounter events (`lighting_director.gd`, `test_lighting_director.gd`) | suite + source |
| Cinematic camera | push-in + FOV pull while current, restores home on release (`cinematic_camera.gd`, `test_cinematic_camera.gd`) | suite + source |
| Combat VFX | procedural emerald/copper/violet effects, self-free (`combat_vfx.gd`, `test_combat_vfx.gd`) | suite + source |
| HUD / pause / options / title card | runtime-clean launches; subtitle, objective, boss bar, companion label wired (`hud.gd`, `pause_menu.gd`, `title_card.gd`) | runtime + source |
| Evidence-capture pipeline | `production/capture_frames.tscn` under Xvfb produced a valid 1.5 MB PNG in this audit (`CAPTURE_OK`) | audit re-run |
| On-disk evidence frames | `main_menu.png`, `chapter2_doves_row.png`, `chapter2_arena.png` are 1280×720, non-blank, high pixel variance | audit re-run |

### Run controls (current build)

| Action | Binding |
|---|---|
| Move | WASD (or left stick) |
| Sprint | Shift (or LB) |
| Jump | Space (or A) |
| Dodge | Q (or B) |
| Light attack | LMB (or RB) |
| Heavy attack | RMB (or LB+Y) |
| Interact / advance dialogue | E (or X) |
| Skip whole cutscene | Ctrl (hold) or skip action |
| Companion command | F (or Y) |
| Switch companion | C (or RB+LB) |
| Lock-on | Tab (or R3) |
| Pause | Esc (or Start) |
| Combat telemetry overlay | F3 |
| Truth-layer scan | T (defined, **not yet wired** — see §3) |

### Validation commands (exact)

```bash
GODOT=/home/decrux/.local/bin/godot4
cd game

# 1) Headless import
$GODOT --headless --import --path . ; echo $?   # expect 0

# 2) Full headless test suite (96 tests + smoke)
$GODOT --headless --path . -s res://tests/run_tests.gd ; echo $?   # expect 0, "TEST RUN OK"

# 3) Main menu runtime (bounded)
$GODOT --headless --path . --quit-after 10 res://scenes/main_menu.tscn ; echo $?  # expect 0

# 4) Chapter 2 runtime (bounded; no script errors)
$GODOT --headless --path . --quit-after 300 res://scenes/world/chapter2_choir_below.tscn ; echo $?  # expect 0

# 5) Evidence capture (requires a display; xvfb counts)
xvfb-run -a $GODOT --path . res://production/capture_frames.tscn \
  -- --scene res://scenes/world/chapter2_choir_below.tscn --out /tmp/frame.png --frames 45
# expect "CAPTURE_OK" and a non-empty PNG
```

---

## 2. PROTOTYPE / PLACEHOLDER

Everything below exists and runs, but is explicitly a replaceable prototype layer
per `BRIEF.md` and `docs/ART_DIRECTION.md`. It must not be presented as final art
or final audio.

- **All 3D art is procedural blockout** — primitives generated by
  `src/environment/blockout_chapter2.gd` and primitive-based entity scenes. The
  build labels itself "PROTOTYPE BLOCKOUT" both in the world (`BeatPrototypeGuide`
  plaque) and the main menu ("Blockout layer only").
- **All audio is runtime-synthesized placeholder** — `src/audio/synth.gd`
  generates raw PCM; `AudioDirector` hooks are the contract to keep. No voice
  acting; dialogue is subtitles only.
- **Combat VFX are procedural primitives** — `src/world/combat_vfx.gd`, cheap
  torus/sphere meshes with emissive materials. The color language is the
  production language; the meshes are not.
- **Character meshes are primitive silhouettes** — `VisualRoot` primitives
  (capsule/bell/headphone band etc.). Not final models.
- **Materials / ink edge** — `assets/blockout/materials/*.tres` +
  `ink_edge.gdshader`; tuned for blockout readability, not final shading.
- **Cinematic cameras** — `src/narrative/cinematic_camera.gd` is a prototype
  framing layer (push-in + FOV) that a cinematic animator replaces.
- **Evidence frames are blockout captures** — they demonstrate composition,
  lighting rigs, and beat staging, not final art.
- **Prototype guide plaque** and its control hints describe current prototype
  bindings (one hint is aspirational — see §3).

---

## 3. NOT IMPLEMENTED / KNOWN GAPS

Runtime errors are the only hard blockers; none were found. These are gaps
against the script, brief, or docs — logged here so a supervisor does not read
this draft as a complete claim.

- **Authored production art / Blender meshes** — none. Blockout only, by design.
- **Voice cast / mocap / facial animation / final VFX** — explicitly non-goals.
- **Full 12–20 minute runtime** — the prototype is a playable spine, much shorter.
- **Warden "Coda" traversal-and-pursuit phase (2.9 phase 3)** — the script calls
  for the pipes to split and an arena traversal-and-pursuit section. The Warden's
  state machine covers ENGAGE/sweeps/requiem/summon/defeat; the pursuit section is
  **not** implemented.
- **Exact checkpoint table from `docs/VERTICAL_SLICE_SCRIPT.md`** (CP-0…CP-4 with
  those semantics) — the scene ships 4 checkpoints
  (`doves_row`, `weep_descent`, `choir_threshold`, `choir_house`) which map
  approximately, not 1:1, to the script's CP table.
- **`truth_scan` (T key) is defined in the input map and advertised on the
  prototype plaque but is not wired to any handler.** The truth-layer is fully
  playable through E-interact reconstruction fragments (Nous's scan + Sidbin's
  forensics are narrative, not a separate T toggle). The `truth_layer_toggled`
  EventBus signal is declared but un-emitted. Not a blocker; document it so nobody
  expects a T-scan toggle.
- **Nous's headphone LED turning green (2.10)** — the single color-break beat is
  documented but not implemented as a visual state.
- **Sidbin stopping his recorder in-frame (2.10)** — documented character beat,
  not implemented as a visible action.
- **Choice-driven tutorial track (2.6)** — the script offers "Brooklyn's
  conversion OR Nous's counter, player's choice of tutorial track." Both abilities
  are implemented and switchable (C key), but there is no authored branching
  tutorial track; conversion vs. expose vs. disable all resolve the beat and set
  `street_allegiance`.
- **Full accessibility surface** — subtitle scale/background, invert-Y,
  sensitivity, FOV, quality, volumes are in; colorblind modes and remappable
  bindings are not.
- **Desktop renderer** — Forward+ only on desktop; the compatibility fallback is
  configured for mobile (`renderer/rendering_method.mobile`), per project.godot.
- **Save-to-disk is implemented but not exposed in the title flow** — `save_game`
  / `load_game` pass their tests; the menu currently starts a fresh run via
  `GameState.start_new_game()`.

---

## 4. Adversarial findings from this audit

1. All prior phase validation logs (`02…07`) match what this audit reproduced
   (96 passed / 0 failed, import exit 0). No inflated test counts or fake logs.
2. The evidence PNGs are real captures (non-blank, high variance) and the capture
   pipeline was re-executed successfully in this audit.
3. `production/capture_frames.gd`'s header documented a direct `.gd` invocation
   that hangs (exit 124); the working entry is `capture_frames.tscn`. The header
   comment was corrected in this audit; no other file was changed.
4. One advertised control (T / truth-scan) is unwired — see §3. Not a blocker.
5. No runtime errors surfaced in bounded headless runs of either scene.
6. Two benign warnings remain: the intentional `LightingDirector: unknown rig
   bogus` from its own negative test, and the standard ObjectDB leak notices on
   forced headless quit.

---

## 5. What a supervisor must still do

- **Visually review** `game/production/evidence/main_menu.png`,
  `chapter2_doves_row.png`, and `chapter2_arena.png` (or re-run the capture
  command in §1) and confirm composition, readability, and color language.
- **Play the slice** via the §1 run controls from the main menu (New Game) and
  confirm pacing and the emotional beats 2.1 → 2.11.
- **Approve or reject** this DRAFT. Until then, nothing above should be treated as
  a finished release claim.

---

*End of draft. This document will be superseded once a supervisor has visually
verified the slice and approved the §1 claims.*
