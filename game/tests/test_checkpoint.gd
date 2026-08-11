extends TestCase

func test_checkpoint_registers_spawn() -> void:
	GameState.last_checkpoint = {}
	CheckpointManager.active_checkpoint = null
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	var player := scene.instantiate() as Player
	add_child(player)
	var cp := CheckpointArea.new()
	cp.checkpoint_id = "unit_test_cp"
	var marker := Marker3D.new()
	marker.name = "SpawnPoint"
	marker.position = Vector3(0, 0.5, 2)
	cp.add_child(marker)
	add_child(cp)
	cp.activate(player)
	check(GameState.has_checkpoint(), "checkpoint registered in GameState")
	check_eq(GameState.get_checkpoint_position(), Vector3(0, 0.5, 2), "spawn position stored")
	check_eq(GameState.last_checkpoint.get("scene_path", ""), "res://scenes/world/chapter2_choir_below.tscn",
		"scene path fallback used headless")
	check_eq(CheckpointManager.active_checkpoint, cp, "active checkpoint tracked")
	GameState.last_checkpoint = {}
	player.queue_free()
	cp.queue_free()

func test_spawn_transform_builds_from_checkpoint() -> void:
	GameState.last_checkpoint = {}
	GameState.record_checkpoint("res://scenes/world/chapter2_choir_below.tscn", Vector3(4, 5, 6), 1.0)
	var spawn := CheckpointManager.get_spawn_transform()
	check_eq(spawn.origin, Vector3(4, 5, 6), "spawn origin from checkpoint")
	check(is_equal_approx(spawn.basis.get_euler().y, 1.0), "spawn yaw from checkpoint")
	GameState.last_checkpoint = {}
