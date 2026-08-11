class_name CombatTelemetry
extends CanvasLayer
## Combat telemetry / debug overlay (F3). Renders live combat state so the
## feel and readability rules can be inspected while playing:
##   - player health / resolve / invulnerability / dodge cooldown,
##   - the active combo step and buffered input,
##   - lock-on / soft target,
##   - every companion's cooldown and ability,
##   - every known enemy's state, health, reveal / conversion status,
##   - the active arena encounter,
##   - the last N combat events.
##
## Toggle is pure input state; the panel is only polled while visible. Exposes
## toggle() and get_last_events() so headless tests can drive it deterministically.

const MAX_LOG := 10

var _visible := false
var _player: Player = null
var _last_attack_state := "IDLE"
var _enemies := {}  # Node -> { state, hp, max, converted, dead }
var _encounter_active := false
var _encounter_id := ""

@onready var panel: Control = %Panel
@onready var label: Label = %Label

func _ready() -> void:
	panel.visible = false
	EventBus.player_spawned.connect(_on_player_spawned)
	EventBus.player_attack_state_changed.connect(_on_attack_state_changed)
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.enemy_state_changed.connect(_on_enemy_state_changed)
	EventBus.combatant_defeated.connect(_on_enemy_defeated)
	EventBus.custodian_converted.connect(_on_enemy_converted)
	EventBus.encounter_started.connect(_on_encounter_started)
	EventBus.encounter_completed.connect(_on_encounter_completed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay"):
		toggle()

func toggle() -> void:
	_visible = not _visible
	panel.visible = _visible

func is_visible_overlay() -> bool:
	return _visible

func get_last_events() -> Array[String]:
	return _log

func _on_player_spawned(player: Node3D) -> void:
	if player is Player:
		_player = player as Player

func _on_attack_state_changed(state: String) -> void:
	_last_attack_state = state

func _on_enemy_spawned(enemy: Node) -> void:
	if not _enemies.has(enemy):
		_enemies[enemy] = {
			"state": "?",
			"hp": 0.0,
			"max": 0.0,
			"converted": false,
			"dead": false,
		}

func _on_enemy_state_changed(enemy: Node, state: String) -> void:
	if not _enemies.has(enemy):
		_on_enemy_spawned(enemy)
	_enemies[enemy]["state"] = state

func _on_enemy_defeated(enemy: Node) -> void:
	if _enemies.has(enemy):
		_enemies[enemy]["dead"] = true

func _on_enemy_converted(enemy: Node, _duration: float) -> void:
	if _enemies.has(enemy):
		_enemies[enemy]["converted"] = true

func _on_encounter_started(encounter: Node) -> void:
	_encounter_active = true
	_encounter_id = (encounter as EncounterController).encounter_id if encounter is EncounterController else "?"

func _on_encounter_completed(_encounter: Node) -> void:
	_encounter_active = false
	_encounter_id = ""

var _log: Array[String] = []

func _on_combat_event(message: String) -> void:
	_log.append(message)
	if _log.size() > MAX_LOG:
		_log.pop_front()

func _process(_delta: float) -> void:
	if not _visible:
		return
	label.text = _compose()

func _compose() -> String:
	var lines: Array[String] = []
	lines.append("HERMES COMBAT TELEMETRY  |  FPS %d" % Engine.get_frames_per_second())
	if _player and is_instance_valid(_player):
		var p := _player
		lines.append("")
		lines.append("-- TEKNIUM --")
		lines.append("HP %d/%d   Resolve %d/%d" % [
			p.health.current_health, p.health.max_health,
			p.resolve.current_resolve, p.resolve.max_resolve])
		lines.append("Move %s   DodgeCD %.2fs   Invulnerable %.2fs" % [
			Player.MoveState.keys()[p.move_state],
			p.get_dodge_cooldown(),
			p.health.invulnerability_timer])
		lines.append("Combo %s   Buffered %s" % [_last_attack_state, str(_player.melee.is_buffered())])
		lines.append("Lock %s   Soft target %s" % [
			_player.locked_target().name if _player.is_locked_on() else "off",
			_player.get_combat_target().name if _player.get_combat_target() else "none"])
	else:
		lines.append("-- no player --")
	lines.append("")
	lines.append("-- COMPANIONS --")
	var companions := get_tree().get_nodes_in_group("companion")
	if companions.is_empty():
		lines.append("  none")
	for node in companions:
		var c := node as Companion
		if c == null:
			continue
		var status := "READY" if c.is_ready() else "%.1fs" % c.current_cooldown
		lines.append("  %s [%s] %s  cost %d" % [c.display_name, c.ability_id(), status, c.ability_cost])
	lines.append("")
	lines.append("-- HOSTILES / CONSTRUCTS --")
	if _enemies.is_empty():
		lines.append("  none")
	for enemy in _enemies:
		if not is_instance_valid(enemy):
			continue
		var info: Dictionary = _enemies[enemy]
		if info["dead"]:
			continue
		var health: HealthComponent = (enemy as Combatant).health if enemy is Combatant else null
		var hp := 0.0
		var mx := 1.0
		if health:
			hp = health.current_health
			mx = health.max_health
		var flags := ""
		if info["converted"]:
			flags += " [CONVERTED]"
		lines.append("  %s %s  hp %d/%d%s" % [
			enemy.name if not (enemy is Combatant) else (enemy as Combatant).display_name,
			str(info["state"]), hp, mx, flags])
	lines.append("")
	lines.append("-- ENCOUNTER --")
	if _encounter_active:
		var remaining := 0
		for enemy in _enemies:
			if is_instance_valid(enemy) and not _enemies[enemy]["dead"]:
				remaining += 1
		lines.append("  %s active — %d combatants remaining" % [_encounter_id, remaining])
	else:
		lines.append("  inactive")
	lines.append("")
	lines.append("-- COMBAT LOG --")
	if _log.is_empty():
		lines.append("  (empty)")
	for entry in _log:
		lines.append("  %s" % entry)
	return "\n".join(lines)
