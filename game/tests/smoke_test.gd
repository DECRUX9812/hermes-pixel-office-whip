extends Node3D
## Headless smoke test: loads the full Chapter 2 scene and drives the foundation
## systems (spawn, grounded physics, jump, camera-relative movement, interaction
## focus + perform, checkpoint registration, melee on the training dummy).
## Emits finished(passed). When run standalone it quits with the result code.

signal finished(passed: bool)

var _passed := true
var _failures: Array[String] = []

@onready var chapter: Node3D = $Chapter2

func _ready() -> void:
	_run()

func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var player := chapter.get_node_or_null("Player") as Player
	_check(player != null, "player present in chapter scene")
	if player == null:
		_finish()
		return

	await _wait_frames(30)
	_check(player.is_on_floor(), "player grounded on the street")

	# Jump
	Input.action_press("jump")
	await _wait_frames(2)
	Input.action_release("jump")
	await _wait_frames(8)
	_check(not player.is_on_floor(), "player airborne after jump")
	await _wait_frames(60)
	_check(player.is_on_floor(), "player landed after jump")

	# Camera-relative movement
	var move_start := player.global_position
	Input.action_press("move_forward")
	await _wait_frames(120)
	Input.action_release("move_forward")
	var distance := (player.global_position - move_start).length()
	_check(distance > 2.0, "player moved forward (%.2f m)" % distance)
	_check(player.global_position.z < move_start.z, "player moved toward -Z (camera forward)")

	# Interaction focus + perform on Juno's door
	var door := chapter.get_node_or_null("Beats/Interactables/DoorJuno") as StoryInteractable
	_check(door != null, "DoorJuno interactable present")
	if door:
		player.global_position = door.global_position + Vector3(0.0, 0.0, 1.1)
		await _wait_frames(12)
		_check(player.interaction.focused == door, "interaction focused on Juno's door")
		if player.interaction.focused == door:
			player.interaction.perform_interaction()
			await _wait_frames(5)
			_check(not door.interactive, "one-shot door consumed after interaction")

	# Checkpoint registration
	var cp := chapter.get_node_or_null("Beats/Checkpoints/CP_DovesRow") as CheckpointArea
	_check(cp != null, "Doves Row checkpoint present")
	_check(GameState.has_checkpoint(), "checkpoint recorded during smoke run")

	# Melee on the training dummy
	var dummy := chapter.get_node_or_null("Beats/DummyThreshold") as TrainingDummy
	_check(dummy != null, "training dummy present")
	if dummy:
		player.global_position = dummy.global_position + Vector3(0.0, 0.0, 2.2)
		await _wait_frames(12)
		var before := dummy.health.current_health
		player.melee.try_light_attack()
		await _wait_frames(40)
		_check(dummy.health.current_health < before, "melee damaged the training dummy")

	# Objective flow started
	var flow := chapter.get_node_or_null("ObjectiveFlow") as ObjectiveFlow
	_check(flow != null and flow.current != null, "objective flow began with an active objective")

	_finish()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_passed = false
		_failures.append(message)
		push_error("SMOKE FAIL: %s" % message)

func _finish() -> void:
	if _passed:
		print("SMOKE_TEST: PASS")
	else:
		print("SMOKE_TEST: FAIL")
		for failure in _failures:
			print("  - %s" % failure)
	finished.emit(_passed)
	if get_tree().current_scene == self:
		get_tree().quit(0 if _passed else 1)

func _wait_frames(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame
