# ART DIRECTION — HERMES: THE LAST OPEN DOOR (vertical slice)

**Status:** Prototype art direction; live document for the blockout layer.
**Companion docs:** WORLD_BIBLE.md (§9 color/iconography), EMOTIONAL_PACING.md
(temperature scale), BRIEF.md (visual target). This document records the
*current build's* visual language and how the replaceable prototype layer is
structured, so a production art pass knows exactly what to swap and what to keep.

---

## 1. What this layer is

The slice's visuals are a **clearly-labelled prototype layer**. Every material,
character mesh, prop, light rig, VFX, and audio cue below is procedural —
generated in code or built from Godot primitives — and every one of them is
marked `PROTOTYPE` in its resource name or container. None of it is final art.
The *architecture* (which node owns what, how the lighting rigs drive the beat,
how VFX hook to the event bus) is the production skeleton and is intended to
survive the art pass.

**Replacement rule:** replace the *visuals*, not the *systems*. The gameplay and
narrative systems (combat, companions, dialogue, objectives, checkpoints) read
the blockout through event signals and node paths; an authored layer that keeps
those contracts can replace the blockout wholesale.

---

## 2. Scale kit (the metric spine)

All geometry is built on a consistent metric kit so silhouettes, architecture,
and camera framing stay coherent even as meshes are swapped:

| Element | Size | Notes |
|---|---|---|
| Humanoid figure (Teknium, companions) | ~1.9 m tall, capsule r 0.3–0.4 | Feet at y=0, eyes ~1.7 m |
| Door / passage height | 2.6 m | Juno's door, service breach, gates |
| Door width | 1.4–1.8 m | Corridors never narrower than 2.4 m |
| Corridor width | 3.0–5.0 m | Gameplay lanes, dodge space |
| Ceiling height (interior beats) | 4.5–7.0 m | Choir rooms taller on purpose |
| Street width (Dove's Row) | 16 m | Two tenements + a lane + curbs |
| Arena (Choir-house) | 16 × 24 m | Single resonant chamber |
| Step height (Weep stairs) | 0.66 m | One deliberate cadence |
| Lamp, pipe, rail thickness | 0.06–0.24 m | Reads at camera distance |

**Rule:** no two verticals of the same class differ by more than ~20%. A door
must always be a door, a column always a column, across the whole slice. This is
what keeps the procedural environment from reading as "random primitives."

---

## 3. Material language — emerald / copper / obsidian

Three families, one rule: **emerald light against near-black stone and copper**,
with restrained character accents. Materials live in
`game/assets/blockout/materials/` and all use the `ink_edge.gdshader` so
silhouettes carry a selective dark ink line (the graphic-novel register).

| Material | Role | Palette | Rendering notes |
|---|---|---|---|
| `stone_black` | Street, tenements, walls | near-black blue-grey | roughness ~0.92, matte |
| `stone_obsidian` | Player, constructs, columns | polished black | metallic 0.55, subtle green emission |
| `copper` | Doors, pipes, engine trim | warm copper | metallic 1.0, faint warm emission |
| `copper_glow` | Resonator bells, choir hardware | hot copper | strong warm emission |
| `emerald_glow` | Hermes, lumen-moss, staff, beacons | Hermes green | emissive, no bloom overload |
| `copper_dead` | Kettle, stall crates, rust | dead copper | high roughness, no emission |
| `water` | Flooded crypts | near-black teal | low roughness, faint green |

**Language rules:**
- Emerald is the *only* saturated green and only ever means remembering/Hermes.
- Copper is the machine present; obsidian the machine's body; stone the city.
- Character accents (Nous violet, Brooklyn pink) are small, hard-edged, and never
  fight the emerald key.
- `ink_edge.gdshader` adds a rim-ink term; it is tuned low enough that faces stay
  clean and never hides geometry under darkness.

---

## 4. Lighting / color script (authored, per beat)

`src/world/lighting_director.gd` drives the environment: ambient color/energy,
fog color/density, sun energy, an emerald key light, a copper key light, and a
restrained glow intensity. It is wired to `EventBus.objective_updated` and the
encounter signals, so the *story's temperature* is the light's temperature
(docs/EMOTIONAL_PACING.md §1).

| Rig | Beats | Temperature | Grade |
|---|---|---|---|
| `ice` | 2.1–2.3 Dove's Row, the surrender | 1–2 | near-black, cold fog, single dead lumen |
| `weep` | 2.4 the descent | 4 | green lumen-moss, flooded crypt fog |
| `conduit` | 2.5 collapsed conduit | 5 | green past → copper present |
| `threshold` | 2.6–2.7 first contact, payoff | 6 | copper warm, emerald edges |
| `arena` | 2.8–2.9 Warden set piece | 7–8 | copper singing green |
| `silence` | 2.10–2.11 eleven seconds, the question | 1 | the green-out; held dark, not murky |

**Composition rule:** every rig keeps ambient energy ≥ 0.26 and a key light, so
the frame is readable without turning the brightness up or hiding under darkness.
Post is restrained: ACES tonemap, MSAA 2x, SSAO (dropped on Low preset), fog, a
subtle glow tuned to emission sources — no bloom, no dark-vignette crutch.

---

## 5. Silhouette-first characters

Every character reads from its silhouette before its color. The blockout uses
primitive "signature" geometry per cast member (marked PROTOTYPE):

| Character | Signature silhouette | Color accent |
|---|---|---|
| Teknium | coat flare + tall emerald staff with glowing tip + headband | green (Hermes family) |
| Custodian | visored head, shoulder ring, low lamp arm | copper + emerald eye |
| Choir Warden | tall resonator head, crown band, conductor's baton | copper + captive emerald core |
| Nous | headphone band + ear cups + single LED | violet LED on monochrome |
| Brooklyn | coat hem + heart-core weapon | pink / magenta |

The `FlashMesh` on combatants (emerald on hit) and the `TargetRing` on the
Custodian/dummy keep state readable in silhouette before any HUD is read.

---

## 6. Environment storytelling props

Props are primitive stand-ins with *intent*. Each one encodes a story beat from
the script so the environment narrates before dialogue (WORLD_BIBLE §1 law):

- **Dove's Row:** Juno's open door, the kettle boiled dry, a chair pushed back
  and never returned, the care terminal (Lark's box) with its emerald screen, a
  fallen household frame, a market stall kept open for a child's winter.
- **The Weep:** the worn Common Index mark on the lintel (Payoff A8), drowned
  archive shelves, a single emerald lumen in the dark.
- **The Choir threshold:** captive-voice resonators — "able to sing, not able to
  mean it" (2.6 Tinuviel beat, Payoff E2).
- **The arena:** a captive-choir echo wall of emerald-lit pipes (2.9 causality:
  the surrendered voices are bound into the machine).

---

## 7. Combat VFX language (readable, cheap)

`src/world/combat_vfx.gd` spawns short-lived procedural primitives on EventBus
signals. No textures, no particle systems: each effect is a few draw calls and
frees itself. The language is the production language:

| Event | Effect | Color |
|---|---|---|
| Attack started | staff swing arc | emerald |
| Attack landed | impact flash + expanding ring | emerald (light) / copper (heavy) |
| Dodge | brief afterimage | emerald |
| Enemy windup | telegraph ring | copper |
| Warden requiem | wide captive ring | emerald |
| Truth breach | violet ring | violet |
| Defeat | dissolve flash | emerald |

Telegraphs are always *before* the threat; impacts are always *at* the victim;
nothing persists long enough to hide the world.

---

## 8. Prototype labelling & replacement inventory

- **Materials:** `assets/blockout/materials/*.tres` (+ `ink_edge.gdshader`).
- **Environment:** `src/environment/blockout_chapter2.gd` (one named container
  per beat; swap the `Blockout` node in the chapter scene to replace).
- **Characters:** `scenes/player/player.tscn`, `scenes/world/entities/*.tscn`
  (VisualRoot children are the replaceable mesh layer).
- **Lighting:** `src/world/lighting_director.gd` + the scene's light rigs.
- **VFX:** `src/world/combat_vfx.gd`.
- **Cameras:** `src/narrative/cinematic_camera.gd` on `CinematicCamera10/11`.
- **Audio:** `src/audio/synth.gd` (placeholders) + `src/audio/audio_director.gd`
  (hook API to keep). See AUDIO_DIRECTION.md.

Every asset listed here is a prototype stand-in and must not be presented as
final art. The systems above them are the deliverable of this slice.
