extends TestCase
## Deterministic coverage for the Custodian state machine: it detects and engages
## the player, its lunge damages the player unless i-frames are up, hits provoke
## hurt/stagger reactions, defeat emits EventBus.combatant_defeated, and
## Brooklyn's Heart-Bind conversion flips allegiance.

const CUSTODIAN_SCENE := "res://scenes/world/entities/custodian.tscn"

var _defeated: Array[Node] = []

func _ready() -> void:
	EventBus.combatant_defeated.connect(_on_defeated)

func _exit_tree() -> void:
	EventBus.combatant_defeated.disconnect(_on_defeated)

func _on_defeated(node: Node) -> void:
	_defeated.append(node)

func test_custodian_attacks_player_in_range() -> void:
	GameState.last_checkpoint = {}
	_defeated.clear()
	var cust := _make_custodian(Vector3(0, 1, 2.0))
	var player := _make_player()
	var floor := _make_test_floor()
	add_child(floor)
	add_child(player)
	add_child(cust)
	player.global_position = Vector3(0, 2, 0)
	await _wait_physics(40)
	var before := player.health.current_health
	await _wait_physics(220)
	check(player.health.current_health < before,
		"custodian lunge damaged the player (%.0f -> %.0f)" % [before, player.health.current_health])
	check(player.health.current_health > 0.0, "bounded i-frames kept the player alive through the test")
	player.queue_free()
	cust.queue_free()
	floor.queue_free()

func test_player_invulnerability_blocks_custodian_damage() -> void:
	GameState.last_checkpoint = {}
	_defeated.clear()
	var cust := _make_custodian(Vector3(0, 1, 1.8))
	var player := _make_player()
	var floor := _make_test_floor()
	add_child(floor)
	add_child(player)
	add_child(cust)
	player.global_position = Vector3(0, 2, 0)
	await _wait_physics(40)
	player.health.grant_invulnerability_window(6.0)
	await _wait_physics(180)
	check_eq(player.health.current_health, player.health.max_health,
		"invulnerability window blocked the custodian's lunge")
	player.queue_free()
	cust.queue_free()
	floor.queue_free()

func test_hit_reactions_hurt_and_stagger() -> void:
	var cust := _make_custodian(Vector3(0, 1, 0))
	add_child(cust)
	await _wait_physics(10)
	cust.take_hit(10.0, Vector3(1, 0, 0), false)
	check(cust.hurt_timer > 0.0, "light hit applies a hurt pause")
	check_eq(cust.stagger_timer, 0.0, "light hit does not stagger")
	cust.health.invulnerability_timer = 0.0
	cust.take_hit(10.0, Vector3(1, 0, 0), true)
	check(cust.stagger_timer > 0.0, "heavy hit applies a stagger")
	cust.queue_free()

func test_defeat_emits_combatant_defeated_once() -> void:
	_defeated.clear()
	var cust := _make_custodian(Vector3(0, 1, 0))
	add_child(cust)
	await _wait_physics(10)
	cust.take_hit(9999.0, Vector3.BACK, true)
	check(cust.dead, "custodian marked dead")
	await _wait_physics(5)
	check_eq(_defeated.size(), 1, "combatant_defeated emitted exactly once")
	check(not cust.is_hostile(), "defeated custodian leaves the hostile group")
	check(not get_tree().get_nodes_in_group("hostile").has(cust), "custodian absent from hostile group")
	cust.queue_free()

func test_convert_flips_allegiance() -> void:
	var cust := _make_custodian(Vector3(0, 1, 0))
	add_child(cust)
	await _wait_physics(10)
	check(cust.convert(8.0), "heart-bind conversion accepted")
	check(not cust.is_hostile(), "converted custodian is no longer hostile")
	check(not get_tree().get_nodes_in_group("hostile").has(cust), "converted custodian removed from hostile group")
	cust.queue_free()

func _make_custodian(position: Vector3) -> Custodian:
	var scene: PackedScene = load(CUSTODIAN_SCENE)
	var cust := scene.instantiate() as Custodian
	cust.position = position
	return cust

func _make_player() -> Player:
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	return scene.instantiate() as Player

func _make_test_floor() -> StaticBody3D:
	var floor := StaticBody3D.new()
	floor.collision_layer = 1
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24, 1, 24)
	mesh.mesh = box
	floor.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(24, 1, 24)
	collider.shape = shape
	floor.add_child(collider)
	floor.position = Vector3(0, -0.5, 0)
	return floor
