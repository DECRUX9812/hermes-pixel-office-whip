extends Node3D
## Chapter 2: The Choir Below — scene director. Owns the event-driven objective
## flow and reacts to story beats, checkpoint arrivals, and combat outcomes.
## All canonical dialogue lives in the StoryInteractable nodes (from
## game/docs/VERTICAL_SLICE_SCRIPT.md); this script only sequences them.

@onready var objective_flow: ObjectiveFlow = $ObjectiveFlow

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.story_beat_triggered.connect(_on_story_beat)
	EventBus.combatant_defeated.connect(_on_combatant_defeated)
	EventBus.checkpoint_reached.connect(_on_checkpoint_reached)
	EventBus.scene_loaded.emit(scene_file_path)
	objective_flow.begin()

func _on_story_beat(beat_id: String) -> void:
	match beat_id:
		"doves_row_door":
			objective_flow.complete("investigate_doves_row")
		"threshold_door":
			objective_flow.complete("enter_the_choir")

func _on_combatant_defeated(_combatant: Node) -> void:
	objective_flow.complete("clear_the_threshold")

func _on_checkpoint_reached(checkpoint: CheckpointArea) -> void:
	match checkpoint.checkpoint_id:
		"weep_descent":
			objective_flow.complete("reach_the_weep")
		"choir_threshold":
			objective_flow.complete("cross_the_conduit")
		"choir_house":
			objective_flow.complete("reach_the_wardens_house")
