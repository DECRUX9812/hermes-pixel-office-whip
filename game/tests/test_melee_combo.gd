extends TestCase
## Deterministic coverage for the light/heavy chain, input buffering, dodge
## cancel, cooldown gating and finisher reset. Timings are asserted against the
## exported swing durations, so they break loudly if tuning drifts.

var _attack_states: Array[String] = []

func _ready() -> void:
	EventBus.player_attack_state_changed.connect(_on_attack_state)

func _exit_tree() -> void:
	EventBus.player_attack_state_changed.disconnect(_on_attack_state)

func _on_attack_state(state: String) -> void:
	_attack_states.append(state)

func test_light_chain_advances_in_order_and_finisher_resets() -> void:
	GameState.last_checkpoint = {}
	_attack_states.clear()
	var player := _make_player()
	var floor := _make_test_floor()
	add_child(floor)
	add_child(player)
	player.global_position = Vector3(0, 2, 0)
	await _wait_physics(40)

	check(player.melee.try_light_attack(), "L1 begins")
	await _wait_physics(6)
	check(not player.melee.try_light_attack(), "mid-swing press is buffered, not restarted")
	check(player.melee.is_buffered(), "input buffered for L2")
	await _wait_physics(18)
	check(player.melee.state_label() == "LIGHT 2", "chain advanced to L2 (got %s)" % player.melee.state_label())
	await _wait_physics(4)
	check(not player.melee.try_light_attack(), "L2 press is buffered, not restarted")
	check(player.melee.is_buffered(), "L2 press buffered for finisher")
	await _wait_physics(22)
	check(player.melee.state_label() == "LIGHT 3", "chain advanced to finisher (got %s)" % player.melee.state_label())
	await _wait_physics(45)
	check(player.melee.chain_index == -1, "finisher reset the chain")
	check("LIGHT 1" in _attack_states and "LIGHT 2" in _attack_states and "LIGHT 3" in _attack_states,
		"all three light steps observed: %s" % str(_attack_states))
	player.queue_free()
	floor.queue_free()

func test_heavy_hits_harder_than_light() -> void:
	GameState.last_checkpoint = {}
	var player := _make_player()
	var floor := _make_test_floor()
	var dummy_scene: PackedScene = load("res://scenes/world/entities/training_dummy.tscn")
	var dummy := dummy_scene.instantiate() as TrainingDummy
	dummy.position = Vector3(0, 0, -2.3)
	add_child(floor)
	add_child(dummy)
	add_child(player)
	player.global_position = Vector3(0, 2, 0)
	await _wait_physics(40)

	player.melee.try_light_attack()
	await _wait_physics(30)
	var light_damage := dummy.health.max_health - dummy.health.current_health
	dummy.health.reset()
	await _wait_physics(30)

	player.melee.try_heavy_attack()
	await _wait_physics(45)
	var heavy_damage := dummy.health.max_health - dummy.health.current_health
	check(light_damage > 0.0, "light swing connected (%d dmg)" % light_damage)
	check(heavy_damage > light_damage, "heavy (%d) hits harder than light (%d)" % [heavy_damage, light_damage])
	check_eq(heavy_damage, 26.0, "heavy step one deals the exported value")
	player.queue_free()
	dummy.queue_free()
	floor.queue_free()

func test_cooldown_blocks_immediate_reuse() -> void:
	GameState.last_checkpoint = {}
	var player := _make_player()
	var floor := _make_test_floor()
	add_child(floor)
	add_child(player)
	player.global_position = Vector3(0, 2, 0)
	await _wait_physics(40)

	player.melee.try_light_attack()
	await _wait_physics(26)
	check(not player.melee.try_light_attack(), "cooldown blocks a fresh swing right after recovery")
	await _wait_physics(30)
	check(player.melee.try_light_attack(), "swing allowed once the cooldown has elapsed")
	player.queue_free()
	floor.queue_free()

func test_dodge_cancels_active_attack() -> void:
	GameState.last_checkpoint = {}
	var player := _make_player()
	var floor := _make_test_floor()
	add_child(floor)
	add_child(player)
	player.global_position = Vector3(0, 2, 0)
	await _wait_physics(40)

	check(player.melee.try_light_attack(), "attack starts")
	await _wait_physics(4)
	check(player.melee.is_attacking(), "attack active before dodge")
	player.melee.cancel_to_dodge()
	check(not player.melee.is_attacking(), "dodge cancel aborts the swing")
	check("DODGE" in _attack_states, "attack state reported the dodge cancel")
	player.queue_free()
	floor.queue_free()

func _make_player() -> Player:
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	return scene.instantiate() as Player

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
