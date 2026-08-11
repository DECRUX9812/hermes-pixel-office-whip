extends TestCase
## Traversal solidity probe: teleports Teknium to every waypoint along the slice
## spine and asserts the ground exists under each one. Catches void gaps in the
## blockout (a floor the player can fall through) that would otherwise be a
## progression dead end. Progression gates (Weep gate, Choir door) are opened via
## their beats before probing the segments they seal.

const CHAPTER_SCENE := "res://scenes/world/chapter2_choir_below.tscn"

var _waypoints := [
	Vector3(0, 0, 2),       # spawn, Dove's Row
	Vector3(0, 0, -20),     # street mid
	Vector3(0, 0, -44),     # street approaching the Weep wall
	Vector3(0, 0, -45.5),   # the breach doorway
	Vector3(0, 0, -47),     # Weep upper gallery
	Vector3(0, 0, -49),     # gallery deep (fragment room)
	Vector3(0, 0.1, -50.5), # first step of the descent
	Vector3(0, -3, -56.2),  # mid-descent (centre of a step tread)
	Vector3(0, -7.8, -63),  # base of the descent
	Vector3(0, -7.5, -66),  # collapsed conduit (near)
	Vector3(0, -7.5, -72.5), # conduit debris step
	Vector3(0, -7.5, -75),  # collapsed conduit (far)
	Vector3(0, -7.9, -84),  # choir threshold room
	Vector3(0, -7.9, -87.5), # before the Choir door
	Vector3(0, -7.9, -95),  # arena
	Vector3(0, -7.9, -100), # Warden position
	Vector3(0, -7.9, -108), # Hermes door
]

func test_traversal_spine_is_solid() -> void:
	var scene: PackedScene = load(CHAPTER_SCENE)
	var chapter := scene.instantiate()
	add_child(chapter)
	await _wait_physics(30)

	# Open the progression gates so the sealed segments are probeable.
	EventBus.story_beat_triggered.emit("reconstruction_complete")
	EventBus.story_beat_triggered.emit("threshold_door")
	await _wait_frames(4)
	var reveal := chapter.get_node_or_null("Beats/Narrative/Cinematics/RevealScene") as DialogueRunner
	if reveal and reveal.is_playing():
		reveal.skip_all()
	await _wait_frames(2)

	var player := chapter.get_node("Player") as Player
	check(player != null, "player present")

	var ungrounded: Array[String] = []
	for i in _waypoints.size():
		var wp: Vector3 = _waypoints[i]
		player.global_position = wp
		player.velocity = Vector3.ZERO
		await _wait_physics(45)
		if not player.is_on_floor():
			var state := player.get_world_3d().direct_space_state
			var hit := state.intersect_ray(PhysicsRayQueryParameters3D.create(
				wp, wp + Vector3.DOWN * 10.0))
			ungrounded.append("wp%d %s @ %.2f hit=%s" % [
				i, str(wp), player.global_position.y,
				str(hit.get("position", "NONE")) if hit else "NONE"])
	check(ungrounded.is_empty(),
		"every waypoint has solid ground beneath it\n  missing: %s" % "\n  ".join(ungrounded))

	# The two progression gates actually opened for traversal.
	var gate := chapter.get_node("Beats/Gates/WeepGate") as SlidingDoor
	check(gate.is_open(), "Weep gate opened")
	var choir_door := chapter.get_node("Beats/Gates/SlidingDoorThreshold") as SlidingDoor
	check(choir_door.is_open(), "Choir door opened")

	chapter.queue_free()

## The collapsed conduit's broken gap is the traversal tutorial beat: the player
## must jump from the near section across to the debris / far section. This drives
## it with real input (move forward + jump) and asserts the crossing lands.
func test_conduit_gap_crossable_with_jump() -> void:
	var scene: PackedScene = load(CHAPTER_SCENE)
	var chapter := scene.instantiate()
	add_child(chapter)
	await _wait_physics(30)

	var player := chapter.get_node("Player") as Player
	player.global_position = Vector3(0, -7.5, -70.8) # near conduit, edge at z=-71
	player.velocity = Vector3.ZERO
	await _wait_physics(10)

	Input.action_press("move_forward")
	await _wait_physics(40)
	Input.action_press("jump")
	await _wait_physics(2)
	Input.action_release("jump")
	await _wait_physics(50)
	Input.action_release("move_forward")
	await _wait_physics(30)

	if not is_instance_valid(player):
		check(false, "player survived the jump (did not fall out of bounds)")
		chapter.queue_free()
		return
	check(player.global_position.z < -71.5,
		"player crossed the conduit gap (z=%.1f)" % player.global_position.z)
	check(player.is_on_floor(), "player landed on the far conduit")
	chapter.queue_free()
