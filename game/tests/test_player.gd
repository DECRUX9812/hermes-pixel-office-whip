extends TestCase

func test_player_moves_forward_camera_relative() -> void:
	GameState.last_checkpoint = {}
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	var player := scene.instantiate() as Player
	add_child(player)
	var floor := _make_test_floor()
	add_child(floor)
	player.global_position = Vector3(0, 2, 0)
	await _wait_physics(60)
	check(player.is_on_floor(), "player landed on test floor")
	var start := player.global_position
	Input.action_press("move_forward")
	await _wait_physics(60)
	Input.action_release("move_forward")
	var moved := player.global_position
	check(moved.z < start.z - 1.0, "player moved toward -Z (camera forward) when pressing forward")
	player.queue_free()
	floor.queue_free()

func test_player_jump_leaves_ground() -> void:
	GameState.last_checkpoint = {}
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	var player := scene.instantiate() as Player
	add_child(player)
	var floor := _make_test_floor()
	add_child(floor)
	player.global_position = Vector3(0, 2, 0)
	await _wait_physics(60)
	check(player.is_on_floor(), "player grounded before jump")
	Input.action_press("jump")
	await _wait_physics(2)
	Input.action_release("jump")
	await _wait_physics(6)
	check(not player.is_on_floor(), "player airborne after jump")
	await _wait_physics(90)
	check(player.is_on_floor(), "player landed after jump")
	player.queue_free()
	floor.queue_free()

func test_player_dodge_gives_invulnerability_and_movement() -> void:
	GameState.last_checkpoint = {}
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	var player := scene.instantiate() as Player
	add_child(player)
	var floor := _make_test_floor()
	add_child(floor)
	player.global_position = Vector3(0, 2, 0)
	await _wait_physics(60)
	var start := player.global_position
	Input.action_press("move_forward")
	Input.action_press("dodge")
	await _wait_physics(2)
	Input.action_release("dodge")
	await _wait_physics(20)
	var moved := (player.global_position - start).length()
	check(moved > 1.0, "dodge moved player (%.2f m)" % moved)
	Input.action_release("move_forward")
	player.queue_free()
	floor.queue_free()

func test_melee_damages_dummy() -> void:
	GameState.last_checkpoint = {}
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	var player := scene.instantiate() as Player
	add_child(player)
	var dummy_scene: PackedScene = load("res://scenes/world/entities/training_dummy.tscn")
	var dummy := dummy_scene.instantiate() as TrainingDummy
	dummy.position = Vector3(0, 0, -2.3)
	add_child(dummy)
	var floor := _make_test_floor()
	add_child(floor)
	player.global_position = Vector3(0, 2, 0)
	await _wait_physics(60)
	var before := dummy.health.current_health
	player.melee.try_light_attack()
	await _wait_physics(40)
	check(dummy.health.current_health < before, "melee reduced dummy health")
	player.queue_free()
	dummy.queue_free()
	floor.queue_free()

func _make_test_floor() -> StaticBody3D:
	var floor := StaticBody3D.new()
	floor.collision_layer = 1
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 1, 20)
	mesh.mesh = box
	floor.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(20, 1, 20)
	collider.shape = shape
	floor.add_child(collider)
	floor.position = Vector3(0, -0.5, 0)
	return floor
