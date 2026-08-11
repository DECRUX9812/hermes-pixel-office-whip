class_name MeleeController
extends Node3D
## Teknium's staff combat — readable light/heavy chains, not a stub anymore.
##
## Design goals (combat director):
##  - Three-step light chain (L1, L2, finisher) and a two-step heavy chain.
##  - Input buffering: pressing attack during any active swing is remembered and
##    continues the chain on recovery, so the rhythm comes from timing, not from
##    mashing against a locked-out input.
##  - Dodge-cancel: dodging mid-swing aborts the attack cleanly.
##  - Bounded hitstop: a hit freezes the attacker's swing clock very briefly so
##    a landed blow reads; it never freezes the world or the enemy.
##  - Auto-face: at swing start the staff turns toward the active combat target
##    (lock-on, else soft-target), so hits land without pixel-perfect aim.
##  - Finishers and heavies apply a hit reaction (hurt/stagger/knockback) via the
##    combatant's take_hit() so enemies visibly react.

signal attack_started
signal attack_finished
signal hit_landed(target: Node)

const DAMAGEABLE_LAYER := 16

enum Kind { LIGHT, HEAVY }
const LIGHT_STEPS := 3
const HEAVY_STEPS := 2

@export var light_damage: Array[float] = [12.0, 12.0, 18.0]
@export var heavy_damage: Array[float] = [26.0, 34.0]
@export var light_durations: Array[float] = [0.34, 0.34, 0.52]
@export var heavy_durations: Array[float] = [0.5, 0.62]
@export var hit_window_start := 0.08
@export var hit_window_end := 0.24
@export var attack_cooldown := 0.3
@export var hitstop_duration := 0.045
@export var knockback_strength := 3.5
@export var stagger_knockback_strength := 5.0

var chain_index := -1
var heavy_index := -1
var is_attacking_flag := false
var kind := Kind.LIGHT
var step := 0
var _elapsed := 0.0
var _cooldown := 0.0
var _hitstop := 0.0
var _buffered := false
var _buffered_kind := Kind.LIGHT
var _facing_done := false
var _hit_targets: Array[Node] = []

@onready var hit_area: Area3D = $HitArea

func _ready() -> void:
	hit_area.collision_layer = 0
	hit_area.collision_mask = DAMAGEABLE_LAYER
	hit_area.monitoring = true

func try_light_attack() -> bool:
	return _request_attack(Kind.LIGHT)

func try_heavy_attack() -> bool:
	return _request_attack(Kind.HEAVY)

func is_attacking() -> bool:
	return is_attacking_flag

func is_buffered() -> bool:
	return _buffered

func is_attack_ready() -> bool:
	return not is_attacking_flag and _cooldown <= 0.0

func cancel_to_dodge() -> void:
	if not is_attacking_flag:
		return
	is_attacking_flag = false
	_buffered = false
	attack_finished.emit()
	EventBus.player_attack_state_changed.emit("DODGE")

func _request_attack(requested: Kind) -> bool:
	if is_attacking_flag:
		_buffered = true
		_buffered_kind = requested
		return false
	if _cooldown > 0.0:
		return false
	return _begin(requested)

func _begin(requested: Kind) -> bool:
	is_attacking_flag = true
	kind = requested
	if requested == Kind.LIGHT:
		step = (chain_index + 1) % LIGHT_STEPS
	else:
		step = (heavy_index + 1) % HEAVY_STEPS
	_elapsed = 0.0
	_hitstop = 0.0
	_facing_done = false
	_hit_targets.clear()
	attack_started.emit()
	EventBus.attack_started.emit(get_parent(), state_label())
	EventBus.player_attack_state_changed.emit(state_label())
	return true

func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _hitstop > 0.0:
		_hitstop = maxf(0.0, _hitstop - delta)
		return
	if not is_attacking_flag:
		return
	_elapsed += delta
	if not _facing_done:
		_face_target()
		_facing_done = true
	if _elapsed >= hit_window_start and _elapsed <= hit_window_end:
		_check_hits()
	if _elapsed >= _current_duration():
		_finish_attack()

func _check_hits() -> void:
	for body in hit_area.get_overlapping_bodies():
		if body in _hit_targets:
			continue
		var health := _resolve_health(body)
		if health == null or health.is_dead():
			continue
		var target := health.get_parent()
		if target.has_method("is_hostile") and not target.is_hostile():
			continue
		var amount := _current_damage()
		var is_heavy := kind == Kind.HEAVY or (kind == Kind.LIGHT and step == LIGHT_STEPS - 1)
		var dir := _knockback_direction(target)
		var applied := false
		if target.has_method("take_hit"):
			applied = target.take_hit(amount, dir, is_heavy, get_parent())
		elif health.take_damage(amount, get_parent()):
			applied = true
		if applied:
			_hit_targets.append(body)
			hit_landed.emit(target)
			EventBus.attack_landed.emit(get_parent(), target, amount,
				"heavy" if is_heavy else "light")
			_hitstop = hitstop_duration

func _finish_attack() -> void:
	if kind == Kind.LIGHT:
		chain_index = -1 if step == LIGHT_STEPS - 1 else step
	else:
		heavy_index = -1 if step == HEAVY_STEPS - 1 else step
	is_attacking_flag = false
	_cooldown = attack_cooldown
	attack_finished.emit()
	if _buffered:
		var requested := _buffered_kind
		_buffered = false
		_begin(requested)
	else:
		EventBus.player_attack_state_changed.emit("IDLE")

func _face_target() -> void:
	var parent := get_parent()
	if parent == null or not (parent is Player):
		return
	var player := parent as Player
	var target := player.get_combat_target()
	if target == null:
		return
	var to_target := player.global_position.direction_to(_horizontal(target.global_position, player.global_position.y))
	if to_target.length_squared() < 0.0001:
		return
	player.set_visual_facing(to_target)

func _knockback_direction(target: Node) -> Vector3:
	var parent := get_parent()
	if parent is Node3D:
		var origin := _horizontal((parent as Node3D).global_position, 0.0)
		var to := _horizontal((target as Node3D).global_position, 0.0)
		var dir := origin.direction_to(to)
		if dir.length_squared() > 0.0001:
			return dir.normalized()
	return (get_parent() as Node3D).global_transform.basis.z.normalized() * -1.0

func _horizontal(v: Vector3, y: float) -> Vector3:
	return Vector3(v.x, y, v.z)

func _current_damage() -> float:
	if kind == Kind.LIGHT:
		return light_damage[mini(step, light_damage.size() - 1)]
	return heavy_damage[mini(step, heavy_damage.size() - 1)]

func _current_duration() -> float:
	if kind == Kind.LIGHT:
		return light_durations[mini(step, light_durations.size() - 1)]
	return heavy_durations[mini(step, heavy_durations.size() - 1)]

func state_label() -> String:
	var label := "HEAVY" if kind == Kind.HEAVY else "LIGHT"
	return "%s %d" % [label, step + 1]

func _resolve_health(body: Node) -> HealthComponent:
	if body is HealthComponent:
		return body as HealthComponent
	var direct := body.get_node_or_null("Health") as HealthComponent
	if direct:
		return direct
	var parent := body.get_parent()
	if parent is HealthComponent:
		return parent as HealthComponent
	if parent is Node:
		return parent.get_node_or_null("Health") as HealthComponent
	return null
