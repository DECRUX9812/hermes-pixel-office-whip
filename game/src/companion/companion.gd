class_name Companion
extends Node3D
## Companion base. A squadmate that trails the player and exposes one commandable
## ability gated by Resolve (the squad's shared willpower pool) plus a cooldown.
##
## Two canonical abilities from the character bible:
##   - TRUTH_BREACH (Nous): precision counter — reveals the truth-layer of a
##     hostile (incoming-damage multiplier) and interrupts its channel.
##   - HEART_BIND (Brooklyn): hard-light heart — converts a Custodian construct
##     into a witness that fights its former kin instead of the squad.
##
## Abilities are data-driven through exports; adding a third is a scene change,
## not a systems change.

signal cooldown_ready_changed(companion: Companion, ready: bool)

enum Ability { NONE, TRUTH_BREACH, HEART_BIND }

@export var display_name := "Companion"
@export var ability := Ability.NONE
@export var ability_cost := 35.0
@export var cooldown_seconds := 6.0
@export var follow_offset := Vector3(-1.4, 0.0, 0.8)
@export var follow_speed := 6.0
@export var truth_reveal_duration := 5.0
@export var bind_duration := 12.0

var current_cooldown := 0.0
var _last_ready := true

func _ready() -> void:
	add_to_group("companion")

func ability_id() -> String:
	match ability:
		Ability.TRUTH_BREACH:
			return "truth_breach"
		Ability.HEART_BIND:
			return "heart_bind"
		_:
			return "none"

func is_ready() -> bool:
	return current_cooldown <= 0.0

func cooldown_fraction() -> float:
	if cooldown_seconds <= 0.0:
		return 0.0
	return clampf(current_cooldown / cooldown_seconds, 0.0, 1.0)

func can_target(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	match ability:
		Ability.TRUTH_BREACH:
			return target.has_method("truth_reveal")
		Ability.HEART_BIND:
			return target.has_method("convert")
		_:
			return false

func use_ability(executor: Node, target: Node) -> bool:
	if not is_ready():
		EventBus.combat_event.emit("%s: %s on cooldown (%.1fs)" % [display_name, ability_id(), current_cooldown])
		return false
	if not can_target(target):
		EventBus.combat_event.emit("%s: no valid target for %s" % [display_name, ability_id()])
		return false
	var resolve := _resolve_pool(executor)
	if resolve and not resolve.has(ability_cost):
		EventBus.combat_event.emit("%s: not enough resolve (%d/%d)" % [display_name, resolve.current_resolve, ability_cost])
		return false
	if resolve:
		resolve.spend(ability_cost)
	_execute(target)
	current_cooldown = cooldown_seconds
	if _last_ready:
		_last_ready = false
		EventBus.companion_ability_ready_changed.emit(self, false)
		cooldown_ready_changed.emit(self, false)
	EventBus.companion_command_issued.emit(self, ability_id())
	EventBus.ability_used.emit(self, ability_id(), target)
	return true

func _execute(target: Node) -> void:
	match ability:
		Ability.TRUTH_BREACH:
			_execute_truth_breach(target)
		Ability.HEART_BIND:
			_execute_heart_bind(target)

func _execute_truth_breach(target: Node) -> void:
	if target.has_method("truth_reveal"):
		target.truth_reveal(truth_reveal_duration)
	if target.has_method("interrupt"):
		target.interrupt()

func _execute_heart_bind(target: Node) -> void:
	if target.has_method("convert"):
		target.convert(bind_duration)

func _resolve_pool(executor: Node) -> ResolveComponent:
	if executor == null:
		return null
	if executor is Player:
		return (executor as Player).resolve
	if executor is Node:
		var direct := executor.get_node_or_null("Resolve") as ResolveComponent
		if direct:
			return direct
	return null

func _physics_process(delta: float) -> void:
	_tick_cooldown(delta)
	_follow(delta)

func _tick_cooldown(delta: float) -> void:
	if current_cooldown <= 0.0:
		return
	current_cooldown = maxf(0.0, current_cooldown - delta)
	var ready := current_cooldown <= 0.0
	if ready != _last_ready:
		_last_ready = ready
		EventBus.companion_ability_ready_changed.emit(self, ready)
		cooldown_ready_changed.emit(self, ready)

func _follow(delta: float) -> void:
	var leader := _find_leader()
	if leader == null:
		return
	var desired := leader.global_position + leader.global_transform.basis * follow_offset
	global_position = global_position.lerp(desired, minf(1.0, follow_speed * delta))

func _find_leader() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node3D
