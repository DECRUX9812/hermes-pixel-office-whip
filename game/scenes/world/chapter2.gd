extends Node3D
## Chapter 2: The Choir Below — scene director.
##
## Owns the event-driven objective flow end to end (cold open -> Nadia ->
## reconstruction -> descent -> conduit -> first contact -> payoff -> Teknium &
## Nous -> Warden arena -> Hermes's eleven seconds -> the question). All
## canonical dialogue lives in ScriptDialogue (game/docs/VERTICAL_SLICE_SCRIPT.md);
## this script only sequences it and advances objectives.
##
## Deadlock policy: every completion path goes through ObjectiveFlow.skip_to(),
## so a checkpoint / encounter / beat that fires ahead of the current objective
## jumps the flow forward instead of dropping the completion. A player who skips
## a cutscene, walks past an objective, or respawns mid-slice can never strand
## the progression.

@onready var objective_flow: ObjectiveFlow = $ObjectiveFlow

@onready var door_runner: DialogueRunner = $Beats/Narrative/Cinematics/DoorScene
@onready var truth_scan_runner: DialogueRunner = $Beats/Narrative/Cinematics/TruthScanExchange
@onready var nadia_runner: DialogueRunner = $Beats/Narrative/Cinematics/NadiaScene
@onready var reveal_runner: DialogueRunner = $Beats/Narrative/Cinematics/RevealScene
@onready var conversion_runner: DialogueRunner = $Beats/Narrative/Cinematics/ConversionLine
@onready var after_fight_runner: DialogueRunner = $Beats/Narrative/Cinematics/AfterTheFight
@onready var requiem_runner: DialogueRunner = $Beats/Narrative/Cinematics/BrooklynRequiem
@onready var coda_runner: DialogueRunner = $Beats/Narrative/Cinematics/TekniumCoda
@onready var eleven_runner: DialogueRunner = $Beats/Narrative/Cinematics/HermesElevenSeconds
@onready var question_runner: DialogueRunner = $Beats/Narrative/Cinematics/TheQuestion

@onready var reconstruction: TruthLayerReconstruction = $Beats/Narrative/Reconstruction
@onready var guard: Custodian = $Beats/FirstContactCustodian
@onready var encounter: EncounterController = $Beats/Arena/Encounter

var _requiem_line_played := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.story_beat_triggered.connect(_on_story_beat)
	EventBus.combatant_defeated.connect(_on_combatant_defeated)
	EventBus.checkpoint_reached.connect(_on_checkpoint_reached)
	EventBus.encounter_started.connect(_on_encounter_started)
	EventBus.encounter_completed.connect(_on_encounter_completed)
	EventBus.objective_updated.connect(_on_objective_updated)
	EventBus.dialogue_sequence_finished.connect(_on_dialogue_finished)
	EventBus.truth_layer_reconstruction_completed.connect(_on_reconstruction_completed)
	EventBus.custodian_converted.connect(_on_custodian_converted)
	EventBus.truth_revealed.connect(_on_truth_revealed)
	EventBus.enemy_state_changed.connect(_on_enemy_state_changed)
	EventBus.scene_loaded.emit(scene_file_path)
	objective_flow.begin()

func _on_story_beat(beat_id: String) -> void:
	match beat_id:
		"doves_row_door":
			objective_flow.skip_to("investigate_doves_row")
			door_runner.play()
		"reconstruction_complete":
			objective_flow.skip_to("reconstruct_the_surrender")
			reveal_runner.play()
		"surrender_reveal":
			objective_flow.skip_to("reconstruct_the_surrender")
		"nadia_silence":
			objective_flow.skip_to("learn_the_surrender")
		"voices_return":
			objective_flow.skip_to("the_voices_return")
		"nous_conversation":
			objective_flow.skip_to("talk_with_nous")
		"threshold_door":
			objective_flow.skip_to("open_the_choir_door")
		"hermes_eleven_seconds":
			objective_flow.skip_to("hermes_speaks")
			question_runner.play()
		"the_question_asked":
			objective_flow.skip_to("the_question")
			EventBus.title_card_requested.emit("HERMES: THE LAST OPEN DOOR")
			GameState.set_flag("slice_complete", true)

func _on_dialogue_finished(sequence_id: String) -> void:
	match sequence_id:
		"2.1_door":
			truth_scan_runner.play()
		"2.1_truth_scan":
			nadia_runner.play()
		"2.9_teknium_coda":
			eleven_runner.play()

func _on_combatant_defeated(combatant: Node) -> void:
	objective_flow.skip_to("clear_the_threshold")
	if combatant == guard and GameState.get_flag("street_allegiance") == null:
		GameState.set_flag("street_allegiance",
			"exposed" if GameState.get_flag("custodian_exposed") else "disabled")
	if not after_fight_runner.has_played() and not encounter.active:
		after_fight_runner.play()

func _on_checkpoint_reached(checkpoint: CheckpointArea) -> void:
	match checkpoint.checkpoint_id:
		"weep_descent":
			objective_flow.skip_to("descend_the_weep")
		"choir_threshold":
			objective_flow.skip_to("cross_the_conduit")

func _on_encounter_started(_encounter: Node) -> void:
	EventBus.combat_event.emit("The choir-house seals behind the squad — no escape but through the Warden")

func _on_encounter_completed(_encounter: Node) -> void:
	objective_flow.skip_to("defeat_the_warden")
	if not coda_runner.has_played():
		coda_runner.play()

func _on_objective_updated(objective: Objective) -> void:
	if objective.id == "clear_the_threshold" and guard and guard.aggro_range <= 0.0:
		guard.aggro_range = 8.5
		EventBus.combat_event.emit("A Custodian patrol stands between the squad and the Choir")

func _on_reconstruction_completed(_reconstruction: Node) -> void:
	EventBus.combat_event.emit("Truth-layer reconstruction complete — the surrender is legible")
	GameState.set_flag("record_integrity", true)

func _on_custodian_converted(_custodian: Node, _duration: float) -> void:
	# Conversion is a first-class resolution: it clears the first contact (the
	# converted Custodian does not die, so the fight-completion path never fires)
	# and records the street's allegiance for later chapters.
	GameState.set_flag("street_allegiance", "converted")
	objective_flow.skip_to("clear_the_threshold")
	if not conversion_runner.has_played():
		conversion_runner.play()

func _on_truth_revealed(target: Node, _duration: float) -> void:
	if target == guard:
		GameState.set_flag("custodian_exposed", true)

func _on_enemy_state_changed(enemy: Node, state: String) -> void:
	if _requiem_line_played:
		return
	if enemy == encounter.warden_node and state == "REQUIEM_CHANNEL":
		_requiem_line_played = true
		requiem_runner.play()
