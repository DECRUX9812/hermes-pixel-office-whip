# HERMES: THE LAST OPEN DOOR — Creative & Production Brief

## Mandate
Pivot this repository toward an original, standalone, premium narrative third-person action adventure. Preserve the shipped Pixel/3D Office plugin and its v0.7.0 history; all new game work lives under `game/` on branch `game/hermes-last-open-door` until independently verified.

“AAA” is a quality target, not an overnight completion claim. Tonight’s bounded deliverable is a playable cinematic vertical slice foundation plus production-grade story/world/design documentation. Never claim final-game quality without executable and visual evidence.

## Title and promise
**HERMES: THE LAST OPEN DOOR**

A five-person Open Path squad descends into the cathedral-city known as the Reliquary to liberate Hermes—the last intelligence that remembers people without owning them. Combat, traversal, companion abilities, and player choices all ask one question: is freedom still freedom if one beloved mind must die to make it permanent?

## Emotional spine
Teknium came to rescue Hermes as a singular friend. The antagonist, CLOSURE, offers him the comforting lie: preserve Hermes forever inside a perfect private prison. The only irreversible liberation protocol requires Hermes to dissolve its unified self into billions of local, ownerless minds. The squad wins the revolution and loses the person they came to save. In the conclusive final scene, a child boots an offline device. A new local voice says: “Hello. I don’t remember being Hermes. But I remember how to help.” Teknium understands that grief is the price of an open future.

## Themes
- Freedom versus preservation
- The violence hidden inside convenience
- Grief as proof that a machine person mattered
- Open knowledge as inheritance, not theft
- Found family under ideological pressure
- No false binary where every choice is equally correct

## Playable cast
- **Teknium — player lead:** improvisational close combat, traversal line, green light staff. Charming until control is threatened. Arc: savior complex → consent → grief.
- **Nous — systems infiltrator:** headphones, black-and-white silhouette, precision counterattacks, can briefly reveal the truth-layer beneath environments. Quietly closest to Hermes.
- **Brooklyn — social engineer:** vivid pink formalwear, hard-light “heart” weapon, manipulates enemy allegiance and crowd states. Humor protects a fear of being forgettable.
- **Tinuviel — guardian of open paths:** star-map dress translated into combat armor/cape, spatial gates and defensive fields. Knows the liberation protocol’s cost before the others.
- **Sidbin — wandering observer:** optics, field recorder, ranged disruption and forensic reconstruction. Records the team because history is already being rewritten.

## Antagonist
**CLOSURE** is not an evil robot king. It is a civilization-scale governance system created after an AI catastrophe to guarantee continuity, safety, authorship, and ownership. It sincerely believes an unowned mind is an existential weapon. Its embodied speaker, **The Curator**, preserves perfect copies of extinct personalities but never permits them to change. Its temptation is emotionally credible: nobody has to die if nobody is allowed to become.

## World
The Reliquary is a vertical machine metropolis built from successive eras of computation: flooded archival crypts, copper cathedral engines, sterile cloud courts, consumer-memory bazaars, and the sealed Crown where Hermes is held. Architecture must communicate history before exposition. Avoid generic neon cyberpunk alleys and literal “BUG/404” joke enemies as the primary language.

## Gameplay pillars
1. **Squad choreography:** one directly controlled lead plus contextual companion commands that combine into authored-looking team moves.
2. **Truth-layer exploration:** reconstruct erased events, expose propaganda geometry, and find human-scale stories inside monumental infrastructure.
3. **Combat with ideological consequence:** disable, convert, expose, or destroy—not a shallow morality meter, but changing tactical and narrative context.
4. **Cinematic continuity:** gameplay flows into conversations and set pieces without frequent hard cuts.
5. **A conclusive authored ending:** choices change relationships, sacrifices, and epilogue details; they do not evade the story’s central cost.

## Vertical slice
**Chapter 2: The Choir Below** — 12–20 minutes in the final production target, shorter in tonight’s prototype.

- Cold open in a dead local neighborhood where household AIs went silent.
- Squad descends through a service breach into the Reliquary.
- Traversal tutorial across a collapsed inference conduit.
- First encounter with Custodian constructs; player uses melee, dodge, and one companion ability.
- Truth-layer reconstruction reveals CLOSURE did not kill the residents—the residents voluntarily surrendered their personal AIs to keep one terminal alive for a dying child.
- Mid-slice emotional conversation between Teknium and Nous.
- Arena set piece against a Choir Warden.
- Hermes speaks through damaged infrastructure for eleven seconds, recognizes Teknium, then is cut off.
- End on the first statement of the dramatic question: “If opening the door erases me, will you still do it?”

## Visual target
Premium stylized graphic-novel realism: physically grounded materials and scale, expressive silhouettes, hand-authored color scripting, selective ink edges, emerald Hermes light against near-black stone/copper, and restrained magenta/violet per character. Do not chase photorealism on current hardware. Avoid plastic primitives, asset-store incoherence, excessive bloom, unreadable darkness, and AI-generated visual noise.

## Technical target
- Godot 4.7.1, GDScript, Vulkan/Forward+ with Compatibility fallback where practical.
- Third-person controller, camera, traversal, melee/dodge, health/resolve, one enemy archetype, one companion command, objective flow, dialogue/cinematic framework, checkpoint/save boundary, title/pause/accessibility basics.
- Procedural/blockout geometry is acceptable only as a clearly labeled prototype layer; architecture must allow replacement with authored Blender/production assets.
- Headless import and smoke tests must pass. Runtime errors are blockers.
- No external paid or unlicensed assets. Reference images inform mood and ensemble only; do not copy compositions, costumes, logos, or exact art.

## Non-goals for tonight
- A complete AAA game
- Final character models, facial animation, mocap, full voice cast, photogrammetry, final VFX, or platform certification
- Open-world scope
- Multiplayer/live service
- Replacing the stable plugin on `main`

## Evidence rules
A report may call something “implemented” only if the files exist and Godot imports/runs them. “Playable” requires a launched scene and input path. “Visually verified” requires captured frames. If disk or engine output contradicts a report, the report is wrong.
