class_name MeleeController
extends Node3D
## Minimal melee stub for the foundation: a timed swing that activates a forward
## hitbox and applies damage to any Damageable (HealthComponent) it overlaps.
## Kept readable and small on purpose — phase 04 replaces this with the real
## light/heavy chain, lock-on and hit reactions.

signal attack_started
signal attack_finished
signal hit_landed(target: Node)

const DAMAGEABLE_LAYER := 16

@export var light_damage := 14.0
@export var attack_duration := 0.45
@export var hit_window_start := 0.12
@export var hit_window_end := 0.32
@export var attack_cooldown := 0.35

var _attacking := false
var _elapsed := 0.0
var _cooldown := 0.0
var _hit_targets: Array[Node] = []

@onready var hit_area: Area3D = $HitArea

func _ready() -> void:
	hit_area.collision_layer = 0
	hit_area.collision_mask = DAMAGEABLE_LAYER
	# Monitoring stays enabled from scene load; hits are gated by the swing window.
	hit_area.monitoring = true

func try_light_attack() -> bool:
	if _attacking or _cooldown > 0.0:
		return false
	_attacking = true
	_elapsed = 0.0
	_hit_targets.clear()
	attack_started.emit()
	return true

func is_attacking() -> bool:
	return _attacking

func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if not _attacking:
		return
	_elapsed += delta
	if _elapsed >= hit_window_start and _elapsed <= hit_window_end:
		for body in hit_area.get_overlapping_bodies():
			if body in _hit_targets:
				continue
			var health := _resolve_health(body)
			if health and health.take_damage(light_damage, get_parent()):
				_hit_targets.append(body)
				hit_landed.emit(body)
	if _elapsed >= attack_duration:
		_attacking = false
		_cooldown = attack_cooldown
		attack_finished.emit()

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
