# NARRATIVE RISK REGISTER — HERMES: THE LAST OPEN DOOR

**Status:** Live document; reviewed at each production gate
**Companion docs:** STORY_BIBLE.md (guardrails, §4), VERTICAL_SLICE_SCRIPT.md

Severity: 1 (wound) → 5 (fatal). Likelihood: Low/Med/High. A "fatal" risk is one
that defeats the story's central promise ("emotionally earned, conclusive ending").

---

## 1. Tone and voice risks

| ID | Risk | Sev | Likely | Mitigation | Status |
|---|---|---|---|---|---|
| T-01 | **Brooklyn becomes a Marvel-quippy anchor.** Humor deflates real moments; the squad's grief is cut for a joke. | 4 | Med | Voice constitution (STORY_BIBLE §4, §12): humor never pays the story's bills; no quipping into a wound. Slice guardrail: Brooklyn has three jokes total, and her arena line is deliberately joke-less. VO passes reject any laugh in a grief beat. | Mitigated by constitution; verify in VO pass |
| T-02 | **Hermes's voice reads as generic "wise AI."** Warm-but-vague platitudes undercut the emotional stake. | 4 | Med | Voice register locked: Hermes speaks like weather, names specifics (Teknium, Nous, the door), never generalizes. The 11 seconds are concrete: recognition, correction, warmth, warning. | Locked in slice script |
| T-03 | **Lore dumps via the Curator.** The antagonist becomes a talking history book; the Courts chapter becomes exposition theater. | 5 | High | Rule: history arrives as architecture, reconstruction, and omission. The Curator argues, she does not explain. Any infodump is rewritten as a scene (Ch4 memory-shop; Ch5 the failed half-gate demonstrated, not described). | Guardrail active |
| T-04 | **Literal coding / BUG-404 joke vocabulary.** Undermines the world's sincerity and repeats a cliché. | 3 | Low | Explicitly banned (STORY_BIBLE §4). Enemy vocabulary is custody and conduct, not error codes. | Banned |
| T-05 | **Sentimental epilogue.** The child + terminal scene is sweet enough to be unearned. | 4 | Med | The epilogue is structurally earned: the terminal is the cold-open payoff; the voice refuses to claim Hermes's identity; Teknium's final line is a *lesson he earned*, not a truism. If the scene tests saccharine, cut the music and hold the silence. | Structure locked; test in playthrough |

---

## 2. Character risks

| ID | Risk | Sev | Likely | Mitigation | Status |
|---|---|---|---|---|---|
| C-01 | **Teknium's savior complex reads as arrogance**, losing player sympathy before the consent arc. | 4 | High | He is charming, self-deprecating, and wounded (Prologue seizure). His compulsion is love-shaped and explicitly tied to a childhood loss. The slice gives him the street's surrender as his first lesson in *not* saving. | Prologue + slice spine |
| C-02 | **Nous is too quiet to matter**, especially before the Ch2 conversation. | 3 | Med | Their silences are load-bearing (they are the listener; the truth-layer is their POV). The Ch2 conversation is their reveal moment; the 11-second acknowledgment is the first on-camera grief. Watch for over-stoicism in animation; give them micro-reactions. | Watch during mocap/anim |
| C-03 | **Brooklyn's arc is invisible in the slice** (her crucible is Ch4). | 3 | Med | Accepted for the slice (she is a supporting color there); her full arc is game-length. Slice note: her arena line plants the seed. Risk re-evaluated after Ch4 beats are built. | Tracked |
| C-04 | **Tinuviel's secret feels like a twist withheld**, not a character.** | 4 | Med | The secret is foreshadowed (map's dark patch, her line about half-opened voices in 2.6) and her confession is a *surrender*, not a reveal-bomb. The player should suspect before she says it. | Foreshadow in slice script |
| C-05 | **Sidbin is a camera, not a character** in the slice. | 2 | Med | Acceptable in slice; his engagement arc (Ch4–5) and the record-integrity state make him mechanical-adjacent. Ensure his epilogue record is a presence, not a menu. | Tracked |
| C-06 | **The Curator is too sympathetic or too monstrous.** | 4 | Med | She must argue in good faith and still be wrong. Her origin (Aster, the open archivist) keeps her tragic; her refusal to let anything become keeps her a warden. Rehearse her Comfort line until it is persuasive on first listen. | Scripted; test in read |

---

## 3. Plot and ending risks

| ID | Risk | Sev | Likely | Mitigation | Status |
|---|---|---|---|---|---|
| P-01 | **The dissolution reads as a cop-out / fake death.** Players expect a hidden save. | 5 | Med | The sowing is irreversible *and* mechanically demonstrated (cryptographic anti-merging). The epilogue voice explicitly does not claim Hermes. No secret save exists in any branch. Guardrail in STORY_BIBLE §3. | Fixed spine |
| P-02 | **The ending reads as "all choices are valid."** | 5 | Low | The middle path demonstrably fails on screen (Ch5). Preservation is tempting and wrong. Choices change texture, not the cost. STORY_BIBLE §9 locks this. | Fixed spine |
| P-03 | **The central choice is unearned** — the player hasn't bonded with Hermes enough to feel the loss. | 5 | Med | Bonding is engineered: Pipe (Prologue/Ch1), the 11 seconds (Ch2), the reconstruction of the surrender (Ch2), Nous's confession (Ch2/Ch6), Hermes's consent questions (Ch6). The player meets Hermes in fragments before meeting her whole. | Multiple bonded touchpoints |
| P-04 | **The middle path is so obviously wrong that it insults the player** (violates "no false binary where every choice is equally correct"). | 3 | Med | The middle path must be *seductive*: the Curator argues it with the half-gate's evidence, and it is only defeated by Tinuviel's confession plus a demonstration. It should tempt the player, not insult them. | Balance during Ch5 build |
| P-05 | **CLOSURE's logic is strawmanned** — too easy to defeat. | 4 | Med | CLOSURE is correct about the Unraveling's danger and only wrong about the cure; the Courts chapter is where its argument wins on paper and loses on humanity. The finale refuses a kill-shot (unsealed, not deleted). | Chapter 5 beats |
| P-06 | **The grief is skipped** (fast-forward to epilogue). | 5 | Med | Chapter 6 has a dedicated grief beat; no score-drowning; the squad is given space. Nous hears the silence. Sidbin films it. The epilogue is a season later but the grief is *audible* in Teknium's restraint. | Locked in beats |

---

## 4. Gameplay–narrative integration risks

| ID | Risk | Sev | Likely | Mitigation | Status |
|---|---|---|---|---|---|
| G-01 | **Combat trivializes the ideological weight** — the player fights past the story. | 4 | High | Every encounter is legible as argument: Custodian exposure reveals the family; the Warden's requiem weaponizes voices the player mourns. Mechanical stakes = narrative stakes. Slice guardrails enforced. | Slice scripted |
| G-02 | **Truth-layer becomes a puzzle minigame**, detaching from story. | 3 | Med | Reconstructions are story events (the surrender IS the chapter's emotional peak). Design contract: every reconstruction changes the player's understanding of a *person*, not just a room. | Design contract |
| G-03 | **Morality-meter flattening.** Disable/convert/expose/destroy become a score. | 3 | Med | These are context-changers, not meters. Consequences are narrative state (street allegiance, record integrity), not a visible "good/bad" bar. | Design contract |
| G-04 | **The 11-second scene is unplayable** — a cutscene wall that breaks pillar-4 continuity. | 3 | Med | It occurs in-combat aftermath with no cut; the player is still in the arena's space. The dialogue overlays the player's retained control state (movement locked, gaze free). | Slice scripted |
| G-05 | **Companion commands don't carry emotional weight.** | 3 | Med | Commands are motivated per chapter (Brooklyn's conversion is her persuasion; Tinuviel's final gate is her body). The slice's first companion command is a relationship tutorial choice. | Slice + beats |

---

## 5. World and continuity risks

| ID | Risk | Sev | Likely | Mitigation | Status |
|---|---|---|---|---|---|
| W-01 | **Reference-image bleed** — copying compositions/costumes/logos from reference material. | 4 | Med | Provenance policy (STORY_BIBLE §15, WORLD_BIBLE §12): references are mood/ensemble inputs only; original invention carries the world. Art team to self-audit silhouettes against references. | Policy in place |
| W-02 | **Foreshadow/payoff drift** — a planted beat is cut or a payoff orphaned. | 4 | Med | STORY_BIBLE §10 index is canonical; CHAPTER_BEATS §11 continuity checklist is a gate. Deleting either half is a revision event. | Checklist gated |
| W-03 | **The strata don't read as history** (generic neon-cathedral background). | 3 | Med | Each stratum's material/light/mass is tied to an era and a story job (WORLD_BIBLE §2). Blockout must keep the architecture legible before any text. | World bible |
| W-04 | **Teknium's origin breaks the slice's standalone cold open** (players who skip the Prologue lose context). | 3 | Med | The slice cold-open carries its own weight (Nadia explains; the reconstruction shows; the silence is felt). The Prologue deepens but is not required. Test the slice with cold-open-only players. | Test gate |

---

## 6. Production / scope risks

| ID | Risk | Sev | Likely | Mitigation | Status |
|---|---|---|---|---|---|
| S-01 | **Slice scope exceeds tonight's prototype** (full 2.1–2.11 at 20 min). | 4 | High | Trim spine defined in VERTICAL_SLICE_SCRIPT §2: 2.1→2.3→2.6→2.8→2.9→2.10→2.11 preserves the emotional arc. Blockout first, art second. | Trim spine defined |
| S-02 | **The child's voice (Lark/Juno) is hard to cast/produce** and gets cut for budget. | 3 | Med | Lark has only two scenes; Juno is recorded audio (cheap to produce well). These are the story's moral spine; protect them in the trim. | Protect in trim |
| S-03 | **Narrative docs diverge from the build.** | 3 | Med | Docs are canon until a revision event; build verification against CHAPTER_BEATS checklist at each gate. | Gate process |
| S-04 | **"AAA quality" claim creep** in reports. | 3 | Med | BRIEF evidence rules govern: "implemented" only if files import/run; "playable" only if launched with input path. Docs must not outclaim the build. | BRIEF rules |

---

## 7. Top five risks to retire first (priority order)

1. **P-03 — the choice must be earned.** Bonding touchpoints are the highest-value
   narrative work in the slice (Prologue fragment + 11 seconds + surrender
   reconstruction). Verify these land before expanding scope.
2. **T-01/T-04 — voice discipline.** Quipless grief beats and zero coding-joke
   vocabulary are cheap to enforce and fatal to ignore.
3. **G-01 — combat must argue, not interrupt.** The Warden's requiem mechanic is
   the proof of concept; it must be playable in the prototype.
4. **P-01/P-02 — the conclusive ending.** No secret save, no middle-path ending;
   enforced structurally, not by a warning.
5. **S-01 — the trim spine.** Tonight's prototype uses the trimmed spine; the
   full 20-minute chapter is the follow-on, not the deliverable.
