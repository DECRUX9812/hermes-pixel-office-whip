# AUDIO DIRECTION — HERMES: THE LAST OPEN DOOR (vertical slice)

**Status:** Prototype; original placeholder synthesis only. No external audio
files are used or licensed. Every cue in the slice is generated at runtime as
raw PCM by `src/audio/synth.gd` and routed by `src/audio/audio_director.gd`.

---

## 1. Bus layout

Created at startup (idempotent), all sending to Master:

```
Master
 ├── SFX       (one-shots: impacts, telegraphs, chimes, UI)
 ├── Music     (ambient bed / story stingers, follows temperature)
 ├── Voice     (dialogue subtitle blips)
 └── Ambience  (long loops behind scenes)
```

Per-bus volumes are exposed in the options menu and persisted by `Settings`.

## 2. What every cue means

The placeholder cues carry the world's identity so the mix "sounds right" while
waiting for a production audio pass:

| Cue | Sound | Used for |
|---|---|---|
| `impact` / `impact_heavy` | noise crack + copper thump | staff light/heavy hits |
| `whoosh` | filtered noise sweep | dodge, swing |
| `telegraph` | rising ping | Custodian windup |
| `requiem` | dissonant chord stab | Warden requiem channel |
| `heart_bind` | warm rising two-note | Brooklyn conversion |
| `truth_breach` | dry glissando shimmer | Nous reveal |
| `chime` | pure emerald bell | Hermes moments, Warden fall |
| `click` / `blip` | UI / dialogue ticks | menus, subtitle pacing |
| `sting` | low swell into chime | title card |
| `music_doves_row` | near-silent room tone | cold open (temperature 1–2) |
| `music_weep` | low drone + drips | the descent (4) |
| `music_choir` | warm beating low drone | Choir / threshold (5–7) |
| `music_warden` | tight dissonant drone | the arena (7–8) |

**Emotional pacing law (EMOTIONAL_PACING §11):** the score has been the choir,
so at 2.10–2.11 the choir going silent *is* the loudest sound in the game. The
director's `objective_updated` handler switches the bed per temperature and the
encounter-completed handler silences the ambience to make that beat land.

## 3. Event hooks (the API to keep)

`AudioDirector` listens to EventBus signals and nothing else is coupled to audio:

- `player_dodged` -> whoosh
- `attack_landed` -> impact (light/heavy)
- `player_hit_received` -> impact
- `enemy_state_changed` -> telegraph (windups), requiem (Warden)
- `custodian_converted` / `truth_revealed` / `combatant_defeated` -> identity cues
- `interaction_performed` -> click
- `subtitle_requested*` -> blip (Voice bus)
- `objective_updated` -> ambient bed switch
- `encounter_started/completed` -> ambience / silence
- `title_card_requested` -> sting
- `game_paused/unpaused` -> click

## 4. Replacement plan

A production audio pass replaces the `Synth` streams with authored clips while
keeping the same cue IDs and hook wiring; `AudioDirector` is the fixed contract.
The placeholder synthesis is deliberately dry and simple so it never reads as
"finished music" and never drowns a grief beat.
