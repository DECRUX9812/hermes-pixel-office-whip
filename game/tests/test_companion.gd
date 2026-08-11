extends TestCase
## Deterministic coverage for the companion command interface: resolve gating,
## cooldown enforcement, and the two canonical bible abilities — Nous's Truth
## Breach (reveal + interrupt) and Brooklyn's Heart-Bind (conversion).

const CUSTODIAN_SCENE := "res://scenes/world/entities/custodian.tscn"

func test_truth_breach_marks_and_spends_resolve() -> void:
	GameState.last_checkpoint = {}
	var player := _make_player()
	var cust := _make_custodian()
	add_child(player)
	add_child(cust)
	await _wait_physics(20)
	var nous := _make_companion(Companion.Ability.TRUTH_BREACH, 30.0, 5.0)
	add_child(nous)
	var before := player.resolve.current_resolve
	check(nous.use_ability(player, cust), "Truth Breach command accepted")
	check(cust.reveal_timer > 0.0, "target marked as revealed")
	check_eq(cust.get_reveal_multiplier(), 2.0, "reveal doubles incoming damage")
	check(player.resolve.current_resolve < before, "resolve spent on the command")
	player.queue_free()
	cust.queue_free()
	nous.queue_free()

func test_heart_bind_converts_target() -> void:
	GameState.last_checkpoint = {}
	var player := _make_player()
	var cust := _make_custodian()
	add_child(player)
	add_child(cust)
	await _wait_physics(20)
	var brooklyn := _make_companion(Companion.Ability.HEART_BIND, 40.0, 7.0)
	add_child(brooklyn)
	check(brooklyn.use_ability(player, cust), "Heart-Bind command accepted")
	check(not cust.is_hostile(), "Custodian converted to witness")
	player.queue_free()
	cust.queue_free()
	brooklyn.queue_free()

func test_cooldown_blocks_and_recovers() -> void:
	GameState.last_checkpoint = {}
	var player := _make_player()
	var cust := _make_custodian()
	add_child(player)
	add_child(cust)
	await _wait_physics(20)
	var nous := _make_companion(Companion.Ability.TRUTH_BREACH, 30.0, 0.5)
	add_child(nous)
	check(nous.use_ability(player, cust), "first command succeeds")
	check(not nous.use_ability(player, cust), "cooldown blocks immediate reuse")
	await _wait_physics(40)
	check(nous.is_ready(), "cooldown recovered after the window")
	check(nous.use_ability(player, cust), "command succeeds again after cooldown")
	player.queue_free()
	cust.queue_free()
	nous.queue_free()

func test_resolve_gate_blocks_ability() -> void:
	GameState.last_checkpoint = {}
	var player := _make_player()
	var cust := _make_custodian()
	add_child(player)
	add_child(cust)
	await _wait_physics(20)
	var nous := _make_companion(Companion.Ability.TRUTH_BREACH, 30.0, 5.0)
	add_child(nous)
	player.resolve.current_resolve = 5.0
	check(not nous.use_ability(player, cust), "insufficient resolve rejects the command")
	check_eq(player.resolve.current_resolve, 5.0, "resolve untouched on rejected command")
	player.queue_free()
	cust.queue_free()
	nous.queue_free()

func test_no_target_no_spend() -> void:
	GameState.last_checkpoint = {}
	var player := _make_player()
	add_child(player)
	await _wait_physics(20)
	var nous := _make_companion(Companion.Ability.TRUTH_BREACH, 30.0, 5.0)
	add_child(nous)
	var before := player.resolve.current_resolve
	check(not nous.use_ability(player, null), "null target rejected")
	check_eq(player.resolve.current_resolve, before, "resolve untouched without a target")
	player.queue_free()
	nous.queue_free()

func _make_companion(ability: Companion.Ability, cost: float, cooldown: float) -> Companion:
	var companion := Companion.new()
	companion.ability = ability
	companion.ability_cost = cost
	companion.cooldown_seconds = cooldown
	return companion

func _make_player() -> Player:
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	return scene.instantiate() as Player

func _make_custodian() -> Custodian:
	var scene: PackedScene = load(CUSTODIAN_SCENE)
	return scene.instantiate() as Custodian
